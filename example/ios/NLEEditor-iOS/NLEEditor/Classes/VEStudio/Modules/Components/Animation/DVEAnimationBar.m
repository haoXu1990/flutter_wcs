//
//  DVEAnimationBar.m
//  TTVideoEditorDemo
//
//  Created by bytedance on 2020/12/20
//  Copyright © 2020 bytedance. All rights reserved.
//

#import "DVEAnimationBar.h"
#import "DVEAnimationItemCell.h"
#import "NSString+DVEToPinYin.h"
#import "DVEBundleLoader.h"
#import "DVEVCContext.h"
#import <DVETrackKit/UIView+VEExt.h>
#import "DVEUIHelper.h"
#import "DVEEffectsBarBottomView.h"
#import "NSString+VEToImage.h"
#import "DVEPickerView.h"
#import "DVELoggerImpl.h"
#import "DVEModuleBaseCategoryModel.h"
#import "DVEAnimationPickerUIDefaultConfiguration.h"
#import <NLEPlatform/NLETrackSlot+iOS.h>
#import <NLEPlatform/NLEEditor+iOS.h>
#import <NLEPlatform/NLEVideoAnimation+iOS.h>
#import <ReactiveObjC/ReactiveObjC.h>
#import <Masonry/Masonry.h>

#define kVEVCAnimationBarIdentifier @"kVEVCAnimationBarIdentifier"

static const CGFloat kAnimationMinSec = 0.3;

@interface DVEAnimationBar ()<DVEPickerViewDelegate>

@property (nonatomic, strong) DVEEffectValue *curValue;
@property (nonatomic) BOOL isValueChanged;
///动画区域
@property (nonatomic, strong) DVEPickerView *animationPickerView;
///底部区域
@property (nonatomic, strong) DVEEffectsBarBottomView *bottomView;
///动画数据源
@property (nonatomic, strong) NSArray<DVEModuleBaseCategoryModel *> *animationDataSource;
//动画时长标签
@property (nonatomic, strong) UILabel *animationLabel;

@property (nonatomic, weak) id<DVECoreAnimationProtocol> animationEditor;
@property (nonatomic, weak) id<DVECoreActionServiceProtocol> actionService;
@property (nonatomic, weak) id<DVENLEInterfaceProtocol> nle;

@end

@implementation DVEAnimationBar

DVEAutoInject(self.vcContext.serviceProvider, animationEditor, DVECoreAnimationProtocol)
DVEAutoInject(self.vcContext.serviceProvider, actionService, DVECoreActionServiceProtocol)
DVEAutoInject(self.vcContext.serviceProvider, nle, DVENLEInterfaceProtocol)

- (void)dealloc
{
    DVELogInfo(@"VEVCAnimationBar dealloc");
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self initView];
    }
    
    return self;
}

- (void)initView
{
    [self addSubview:self.animationPickerView];
    [self.animationPickerView mas_makeConstraints:^(MASConstraintMaker *make) {
        id<DVEPickerUIConfigurationProtocol> config = self.animationPickerView.uiConfig;
        make.height.mas_equalTo(config.effectUIConfig.effectListViewHeight + config.categoryUIConfig.categoryTabListViewHeight);
        make.top.equalTo(self).mas_offset(60);
        make.left.right.equalTo(self);
    }];
    
    [self addSubview:self.bottomView];
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.animationPickerView.mas_bottom);
        make.left.right.bottom.equalTo(self);
    }];

    CGFloat sliderY = 18;
    CGFloat sliderWidth = 279;

    self.animationLabel.frame = CGRectMake(16, sliderY, 48, 20);
    [self addSubview:self.animationLabel];

    [self.slider removeFromSuperview];
    self.slider = [[DVEStepSlider alloc] initWithStep:1 defaultValue:kAnimationMinSec frame:CGRectMake((self.width - sliderWidth) / 2, sliderY, sliderWidth, 20)];
    self.slider.valueType = DVEStepSliderValueTypeSecond;
    self.slider.backgroundColor = self.backgroundColor;
    [self addSubview:self.slider];

    [self initSlider];
}

- (void)initData
{
    @weakify(self);
    DVEModuleModelHandler handler = ^(NSArray<DVEEffectValue *> * _Nullable datas, NSString * _Nullable error){
        @strongify(self);
        [self performSelectorOnMainThread:@selector(initData:) withObject:datas waitUntilDone:NO];
    };
    switch (self.type) {
        case VEVCModuleCutSubTypeAnimationTypeAdmission:
        {
            [self.bottomView setTitleText: NLELocalizedString(@"ck_anim_in",@"入场动画")];
            [[DVEBundleLoader shareManager] animationIn:self.vcContext handler:handler];
        }
            break;
        case VEVCModuleCutSubTypeAnimationTypeDisappear:
        {
            [self.bottomView setTitleText:NLELocalizedString(@"ck_anim_out",@"出场动画")];
            [[DVEBundleLoader shareManager] animationOut:self.vcContext handler:handler];
        }
            break;
        case VEVCModuleCutSubTypeAnimationTypeCombination:
        {
            [self.bottomView setTitleText:NLELocalizedString(@"ck_anim_all",@"组合动画")];
            [[DVEBundleLoader shareManager] animationCombin:self.vcContext handler:handler];
        }
            break;
            
        default:
            break;
    }
}

-(void)initData:(NSArray<DVEEffectValue *> *)animationArr
{
    if (![self.vcContext.mediaContext currentBlendVideoSlot]) {
        return;
    }
    NSMutableArray *valueArr = [NSMutableArray new];
    DVEEffectValue *none = [DVEEffectValue new];
    none.valueState = VEEffectValueStateShuntDown;
    none.assetImage = @"iconFilterwu".dve_toImage;
    none.name = NLELocalizedString(@"ck_none", @"无");
    none.identifier = none.name;
    none.sourcePath = none.name;
    [valueArr addObject:none];

    DVEModuleBaseCategoryModel *categoryModel = [DVEModuleBaseCategoryModel new];
    DVEEffectCategory* category = [DVEEffectCategory new];
    categoryModel.category = category;
    [valueArr addObjectsFromArray:animationArr];
    category.models = valueArr;
    
    self.animationDataSource = @[categoryModel];
    [self.animationPickerView updateCategory:self.animationDataSource];

    CGFloat maxTransition = CMTimeGetSeconds([[self.vcContext.mediaContext currentBlendVideoSlot] duration]);
    [self.slider setValueRange:DVEMakeFloatRang(kAnimationMinSec, maxTransition) defaultProgress:kAnimationMinSec];
    
    DVEEffectValue *evalue = [self currentSlotEffectValue:self.type];
    if (evalue) {
        for(NSInteger index = 0 ;index < valueArr.count ; index++){
            DVEEffectValue* value = valueArr[index];
            if([value.sourcePath isEqualToString:evalue.sourcePath]){
                value.indesty = evalue.indesty;
                value.valueState = VEEffectValueStateInUse;
                _curValue = value;
                self.slider.hidden = NO;
                self.slider.value = evalue.indesty;
                [self.animationPickerView currentCategorySelectItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
                return;
            }
        }
    }
    
    if (![self updateAnimationSlider]) {
        _curValue = nil;
        self.slider.hidden = YES;
        self.animationLabel.hidden = YES;
    }
}

- (void)initSlider
{
    self.slider.hidden = YES;
    @weakify(self);
    [[self.slider rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self);
        DVELogInfo(@"-----------%@",x);
        self.isValueChanged = YES;
        self.curValue.indesty = self.slider.value;
        [self playAnimationWithDuration:self.slider.value value:self.curValue];
        
    }];
}

- (UIView*)bottomView
{
    if(!_bottomView) {
        @weakify(self);
        _bottomView = [DVEEffectsBarBottomView newActionBarWithTitle:@"动画" action:^{
            @strongify(self);
            self.vcContext.playerService.needPausePlayerTime = -1;
            if (self.isValueChanged) {
                self.isValueChanged = NO;
                [self.actionService commitNLE:YES];
            }

            [self dismiss:YES];
            [self.actionService refreshUndoRedo];
            self.vcContext.mediaContext.shouldShowVideoAnimation = NO;
        }];
    }
    return _bottomView;
}

- (UILabel *)animationLabel {
    if (!_animationLabel) {
        _animationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 48, 20)];
        _animationLabel.text = NLELocalizedString(@"ck_anim_duration", @"动画时长");
        _animationLabel.font = SCRegularFont(12);
        _animationLabel.textColor = [UIColor whiteColor];
        _animationLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _animationLabel;
}

- (DVEPickerView *)animationPickerView {
    if(!_animationPickerView) {
        _animationPickerView = [[DVEPickerView alloc] initWithUIConfig:[DVEAnimationPickerUIDefaultConfiguration new]];
        _animationPickerView.delegate = self;
        _animationPickerView.backgroundColor = [UIColor clearColor];
    }
    
    return _animationPickerView;
}

- (void)setCurValue:(DVEEffectValue *)curValue {
    if(curValue){
        if (curValue.valueState == VEEffectValueStateShuntDown) {
            [self.animationEditor deleteVideoAnimation];
        }else{
            [self playAnimationWithDuration:curValue.indesty value:curValue];
        }
    }
    else if(_curValue && _curValue.valueState != VEEffectValueStateShuntDown){
        [self.animationEditor deleteVideoAnimation];
    }
    _curValue = curValue;
    
    if ([self.vcContext.mediaContext currentBlendVideoSlot]) {
        self.vcContext.mediaContext.videoAnimationValueChangePayload = [[DVEVideoAnimationChangePayload alloc] initWithSlotId:[self.vcContext.mediaContext currentBlendVideoSlot].nle_nodeId duration:curValue.indesty];
    }
    
}

#pragma mark - AWEStickerPickerViewDelegate

- (BOOL)pickerView:(DVEPickerView *)pickerView isSelected:(DVEEffectValue*)sticker{
    return sticker.valueState == VEEffectValueStateInUse;
}

- (void)pickerView:(DVEPickerView *)pickerView
         didSelectSticker:(DVEEffectValue*)sticker
                 category:(id<DVEPickerCategoryModel>)category
         indexPath:(NSIndexPath *)indexPath{

    
    DVEEffectValue *animationValue = sticker;
    if(animationValue.status == DVEResourceModelStatusDefault){
        if(self.curValue == animationValue) return;
        
        //更新上次选择的“动画”状态为none，如果是清空“动画”对象不做状态更新
        if(self.curValue.valueState == VEEffectValueStateShuntDown){
            
        }else{
            self.curValue.valueState = VEEffectValueStateNone;
        }
        
        //更新目前选择的“动画”状态为inUse，如果是清空“动画”对象不做状态更新
        if(indexPath.row == 0){
            self.animationLabel.hidden = YES;
            self.slider.hidden = YES;
        }else{
            self.animationLabel.hidden = NO;
            self.slider.hidden = NO;
            animationValue.valueState = VEEffectValueStateInUse;
        }
        
        animationValue.indesty = self.slider.value;
        self.curValue = animationValue;
        self.isValueChanged = YES;
        [pickerView updateSelectedStickerForId:self.curValue.identifier];
        return;
    }else if(animationValue.status == DVEResourceModelStatusNeedDownlod || animationValue.status == DVEResourceModelStatusDownlodFailed){
        @weakify(self);
        [sticker downloadModel:^(id<DVEResourceModelProtocol>  _Nonnull model) {
            [pickerView updateStickerStatusForId:model.identifier];
            if(model.status != DVEResourceModelStatusDefault) return;
            dispatch_async(dispatch_get_main_queue(), ^{
                @strongify(self);
                [self pickerView:pickerView didSelectSticker:sticker category:category indexPath:indexPath];
            });
        }];
    }
    [self updateAnimationSlider];
    [pickerView updateStickerStatusForId:animationValue.identifier];
    
}

- (void)pickerView:(DVEPickerView *)pickerView didSelectTabIndex:(NSInteger)index{
    
}


- (void)pickerViewDidClearSticker:(DVEPickerView *)pickerView {
    
}

#pragma mark -

- (void)playAnimationWithDuration:(NSTimeInterval)duration value:(DVEEffectValue *)value  {
    if (![self.vcContext.mediaContext currentBlendVideoSlot]) {
        return;
    }
    DVELogInfo(@"playAnimationWithDuration----%0.1f",duration);

    [self.animationEditor addAnimation:value.sourcePath identifier:self.curValue.identifier withType:self.type duration:self.slider.value];

    CMTime startTime = kCMTimeZero;
    CGFloat playDuration = duration;
    switch (self.type) {
        case VEVCModuleCutSubTypeAnimationTypeAdmission:
            startTime = [self.vcContext.mediaContext currentBlendVideoSlot].startTime;
            playDuration = duration - 0.03;
            break;
        case VEVCModuleCutSubTypeAnimationTypeCombination: {
            startTime = [self.vcContext.mediaContext currentBlendVideoSlot].startTime;
            playDuration = CMTimeGetSeconds([self.vcContext.mediaContext currentBlendVideoSlot].duration) - 0.03;
            break;
        }
        case VEVCModuleCutSubTypeAnimationTypeDisappear:
            startTime = CMTimeSubtract([self.vcContext.mediaContext currentBlendVideoSlot].endTime, CMTimeMakeWithSeconds(duration, USEC_PER_SEC));
            playDuration = duration - 0.03;
            break;
        default:
            break;
    }
    [self.vcContext.playerService playFrom:startTime duration:playDuration completeBlock:nil];
}

#pragma mark - show view

- (void)setType:(VEVCModuleCutSubTypeAnimationType)type
{
    _type = type;
    [self initData];
}

- (void)showInView:(UIView *)view animation:(BOOL)animation
{
    [super showInView:view animation:(BOOL)animation];
    self.actionService.isNeedHideUnReDo = YES;
    [self initData];
}

- (void)undoRedoClikedByUser
{
    ///前次特效对象状态重制，跳过VEEffectValueStateShuntDown态的“无”选项
    if(_curValue && _curValue.valueState != VEEffectValueStateShuntDown){
        _curValue.valueState = VEEffectValueStateNone;
    }
    _curValue = nil;
    self.slider.hidden = YES;
    [self.animationPickerView reloadData];
    
    
    CGFloat maxTransition = CMTimeGetSeconds([[self.vcContext.mediaContext currentBlendVideoSlot] duration]);
    [self.slider setValueRange:DVEMakeFloatRang(kAnimationMinSec, maxTransition) defaultProgress:(maxTransition - kAnimationMinSec) * 0.8];
    
    DVEEffectValue *evalue = [self currentSlotEffectValue:self.type];
    if (evalue) {
        NSArray *valueArr = self.animationDataSource.firstObject.models;
        for(NSInteger index = 0 ;index < valueArr.count ; index++){
            DVEEffectValue* value = valueArr[index];
            if([value.sourcePath isEqualToString:evalue.sourcePath]){
                value.indesty = evalue.indesty;
                value.valueState = VEEffectValueStateInUse;
                _curValue = value;
                self.slider.hidden = NO;
                self.slider.value = evalue.indesty;
                [self.animationPickerView currentCategorySelectItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
                break;
            }
        }
    }
    [self updateAnimationSlider];
}

- (DVEEffectValue *)currentSlotEffectValue:(VEVCModuleCutSubTypeAnimationType)type
{
    NLETrackSlot_OC* selectSlot = [self.vcContext.mediaContext currentBlendVideoSlot];
    
    AVURLAsset *asset = [self.nle assetFromSlot:selectSlot];
    if (!asset) return nil;
    
    NLEVideoAnimationType animationType = [self videoAnimationFor:type];
    
    for(NLEVideoAnimation_OC *animation in [selectSlot getVideoAnims]){
        if(animation.nle_animationType == animationType){
            NLESegmentVideoAnimation_OC* segmentVideoAnimation = animation.segmentVideoAnimation;
            NLEResourceNode_OC *resource = segmentVideoAnimation.effectSDKVideoAnimation;
            DVEEffectValue* value = [DVEEffectValue new];
            value.indesty = CMTimeGetSeconds(segmentVideoAnimation.animationDuration);
            value.sourcePath = resource.resourceFile;
            return value;
        }
    }
    
    return nil;
}

-(NLEVideoAnimationType)videoAnimationFor:(VEVCModuleCutSubTypeAnimationType)type {
    NLEVideoAnimationType animationType = NLEVideoAnimationTypeNone;
    switch (type) {
        case VEVCModuleCutSubTypeAnimationTypeAdmission: {
            animationType = NLEVideoAnimationTypeIn;
        }
            break;
        case VEVCModuleCutSubTypeAnimationTypeCombination: {
            animationType = NLEVideoAnimationTypeCombination;
        }
            break;
        case VEVCModuleCutSubTypeAnimationTypeDisappear: {
            animationType = NLEVideoAnimationTypeOut;
        }
            break;
    }
    return animationType;
}

- (BOOL)updateAnimationSlider
{
    NLEVideoAnimationType type = [self videoAnimationFor:self.type];
    NSDictionary *dic = [self.animationEditor currentAnimationDuration:type];
    NSString *identifier = [dic objectForKey:@"identifier"];
    if (dic && identifier) {
        NSNumber *animationDuration = [dic objectForKey:identifier];
        if (animationDuration.floatValue >= kAnimationMinSec) {
            self.slider.value = animationDuration.floatValue;
            NSArray* models = self.animationDataSource.firstObject.models;
            for (NSInteger i = 1; i < models.count; i ++) {//忽略第一个“无”
                DVEEffectValue *model = models[i];
                if ([model.identifier isEqualToString:identifier]) {
                    model.indesty = animationDuration.floatValue;
                    _curValue = model;
                    model.valueState = VEEffectValueStateInUse;
                    self.slider.hidden = NO;
                    self.animationLabel.hidden = NO;
                    [self.animationPickerView updateSelectedStickerForId:identifier];
                    return YES;
                }
            }
        }
    }
    return NO;
}


@end

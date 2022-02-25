//
//  DVETransitionBar.m
//  TTVideoEditorDemo
//
//  Created by bytedance on 2020/12/20
//  Copyright © 2020 bytedance. All rights reserved.
//

#import "DVETransitionBar.h"
#import "DVETransitionItem.h"
#import "DVEVCContext.h"
#import "DVEBundleLoader.h"
#import <DVETrackKit/UIView+VEExt.h>
#import "NSString+VEToImage.h"
#import "DVEEffectsBarBottomView.h"
#import "NSString+VEToImage.h"
#import "DVEPickerView.h"
#import "DVECustomerHUD.h"
#import "DVEModuleBaseCategoryModel.h"
#import "DVETransitionPickerUIConfiguration.h"
#import "DVELoggerImpl.h"
#import <Masonry/Masonry.h>
#import <ReactiveObjC/ReactiveObjC.h>

@interface DVETransitionBar ()<DVEPickerViewDelegate>

@property (nonatomic, strong) NSMutableArray *transitionArr;
///动画区域
@property (nonatomic, strong) DVEPickerView *animationPickerView;
///底部区域
@property (nonatomic, strong) DVEEffectsBarBottomView *bottomView;
@property (nonatomic, strong) DVEEffectValue *curValue;
@property (nonatomic) BOOL isValueChanged;

@property (nonatomic, weak) id<DVECoreTransitionProtocol> transitionEditor;
@property (nonatomic, weak) id<DVECoreActionServiceProtocol> actionService;

@end

@implementation DVETransitionBar

DVEAutoInject(self.vcContext.serviceProvider, transitionEditor, DVECoreTransitionProtocol)
DVEAutoInject(self.vcContext.serviceProvider, actionService, DVECoreActionServiceProtocol)

- (void)dealloc
{
    DVELogInfo(@"VEVCTransitionBar dealloc");
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

    [self initSlider];
}

- (void)initSlider
{
    self.slider.top = 0;
    self.slider.hidden = YES;
    self.slider.valueType = DVEStepSliderValueTypeSecond;
    @weakify(self);
    [[self.slider rac_signalForControlEvents:UIControlEventValueChanged] subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self);
        DVELogInfo(@"-----------%@",x);
        [self updateTransitionDuration];
    }];
    
    [[self.slider rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self);
        DVELogInfo(@"-----------%@",x);
        [self playTransitionWithCurDuration:self.slider.value value:self.curValue];
        
    }];
}

- (void)updateTransitionDuration
{
    if (self.curValue) {
        self.curValue.indesty = self.slider.value;
    }
}

- (void)playTransitionWithCurDuration:(NSTimeInterval)seconds value:(DVEEffectValue *)value
{
    DVELogInfo(@"playTransitionWithCurDuration----%0.1f",seconds);
    [self.transitionEditor deleteCurrentTransitionForSlot:self.preSlot];
    [self.transitionEditor addTransitionWithEffectResource:value.sourcePath resourceId:value.identifier duration:seconds isOverlap:value.overlap forSlot:self.preSlot];
}

- (void)initData
{
    @weakify(self);
    [[DVEBundleLoader shareManager] transition:self.vcContext handler:^(NSArray<DVEEffectValue *> * _Nullable datas, NSString * _Nullable error) {
        @strongify(self);
        DVEModuleBaseCategoryModel *categoryModel = nil;
        NSMutableArray *valueArr = nil;
        if(!error){
            valueArr = [NSMutableArray new];
            
            
            
            NSString *name = self.preSlot.endTransition.effectSDKTransition.resourceName;
            
            DVEEffectValue *value = [DVEEffectValue new];
            value.valueState = VEEffectValueStateShuntDown;
            value.assetImage = @"iconFilterwu".dve_toImage;
            value.name = NLELocalizedString(@"ck_none", @"无");
            value.identifier = value.name;
            [valueArr addObject:value];
            [valueArr addObjectsFromArray:datas];
            
            self->_curValue = value;
            
            for(DVEEffectValue* value in datas){
                value.indesty = 0.5;
                if ([value.name isEqualToString:name]) {
                    self->_curValue = value;
                    self->_curValue.valueState = VEEffectValueStateInUse;
                }
            }
            
            categoryModel = [DVEModuleBaseCategoryModel new];
            DVEEffectCategory* category = [DVEEffectCategory new];
            categoryModel.category = category;
            category.models = valueArr;
        }
        
        @weakify(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);
            if(!error){
                self.transitionArr = valueArr;
                [self.animationPickerView updateCategory:@[categoryModel]];
                [self.animationPickerView updateFetchFinish];
                @weakify(self);
                [self.animationPickerView performBatchUpdates:^{
                    
                } completion:^(BOOL finished) {
                    @strongify(self);
                    if(finished){
                        [self performSelectorOnMainThread:@selector(initSelectTransition) withObject:nil waitUntilDone:NO];
                    }
                }];
            }else{
                [DVECustomerHUD showMessage:error];
                [self.animationPickerView updateFetchError];
            }
        });
    }];
}

- (UIView*)bottomView
{
    if(!_bottomView) {
        @weakify(self);
        _bottomView = [DVEEffectsBarBottomView newActionBarWithTitle:NLELocalizedString(@"ck_transition", @"转场") action:^{
            @strongify(self);
            self.vcContext.playerService.needPausePlayerTime = -1;
            if (self.isValueChanged) {
                self.isValueChanged = NO;
                //TODO: commit NLE
                [self.actionService commitNLE:YES];
            }
            [self.vcContext.playerService pause];

            [self dismiss:YES];
            [self.actionService refreshUndoRedo];

        }];
    }
    return _bottomView;
}

- (DVEPickerView *)animationPickerView {
    if(!_animationPickerView) {
        _animationPickerView = [[DVEPickerView alloc] initWithUIConfig:[DVETransitionPickerUIDefaultConfiguration new]];
        _animationPickerView.delegate = self;
        _animationPickerView.backgroundColor = [UIColor clearColor];
    }
    
    return _animationPickerView;
}

- (void)setCurValue:(DVEEffectValue *)curValue {
    if(curValue){
        if (curValue.valueState == VEEffectValueStateShuntDown) {
            [self.transitionEditor deleteCurrentTransitionForSlot:self.preSlot];
        }else{
            [self playTransitionWithCurDuration:self.slider.value value:curValue];
        }
    }
    else if(_curValue && _curValue.valueState != VEEffectValueStateShuntDown){
        [self.transitionEditor deleteCurrentTransitionForSlot:self.preSlot];
    }
    _curValue = curValue;
    
}

-(void)initSelectTransition
{
    NSString *resourceId = nil;
    if (self.preSlot.endTransition) {
        resourceId = self.preSlot.endTransition.effectSDKTransition.resourceId;
    }
    
    for (DVEEffectValue *value in self.transitionArr) {
        if ([value.identifier isEqualToString:resourceId]) {
            _curValue = value;
        }
    }
    
    CGFloat maxTransition = [self.transitionEditor getMaxTranstisionTimeBySlot:self.preSlot];
    NSInteger index = [self.transitionArr indexOfObject:self.curValue];
    NSTimeInterval duration = 0.8;
    if(index == NSNotFound || index == 0){
        index = 0;
        self.slider.hidden = YES;
    }else{
        if(self.preSlot.endTransition){
            duration = CMTimeGetSeconds(self.preSlot.endTransition.transitionDuration);
        }
        self.slider.hidden = NO;
    }
    NSTimeInterval defaultDuration = MIN(duration, maxTransition);
    [self.slider setValueRange:DVEMakeFloatRang(0.1, maxTransition) defaultProgress:defaultDuration];
    [self.animationPickerView currentCategorySelectItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
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
            self.slider.hidden = YES;
        }else{
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
    [pickerView updateStickerStatusForId:animationValue.identifier];
    
}

- (void)pickerView:(DVEPickerView *)pickerView didSelectTabIndex:(NSInteger)index{
    
}


- (void)pickerViewDidClearSticker:(DVEPickerView *)pickerView {
    
}


- (void)showInView:(UIView *)view animation:(BOOL)animation
{
    [super showInView:view animation:(BOOL)animation];
    self.actionService.isNeedHideUnReDo = YES;
    [self initData];
}

- (void)undoRedoWillClikeByUser
{
    if (self.isValueChanged) {
        self.isValueChanged = NO;
        //TODO: commit NLE
        [self.actionService commitNLE:YES];
    }
    [self.vcContext.playerService pause];

    [self dismiss:YES];
    [self.actionService refreshUndoRedo];
}

@end

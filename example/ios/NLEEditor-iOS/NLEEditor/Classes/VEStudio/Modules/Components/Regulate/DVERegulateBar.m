//
//  VEVCRegulateBar.m
//  TTVideoEditorDemo
//
//  Created by bytedance on 2020/12/20
//  Copyright © 2020 bytedance. All rights reserved.
//

#import "DVERegulateBar.h"
#import "NSString+DVEToPinYin.h"
#import "NSString+VEIEPath.h"
#import "DVEVCContext.h"
#import "DVEBundleLoader.h"
#import <DVETrackKit/UIView+VEExt.h>
#import "NSString+VEToImage.h"
#import "DVEPickerView.h"
#import "DVEModuleBaseCategoryModel.h"
#import "DVERegulateUIConfiguration.h"
#import "DVEEffectsBarBottomView.h"
#import "DVECustomerHUD.h"
#import "DVELoggerImpl.h"
#import "DVEReportUtils.h"
#import "DVENotification.h"
#import <ReactiveObjC/ReactiveObjC.h>
#import <Masonry/Masonry.h>

#define kVEVCRegulateItemIdentifier @"kVEVCRegulateItemIdentifier"

@interface DVERegulateBar () <DVEPickerViewDelegate>

@property (nonatomic, strong) DVEPickerView *pickerView;

///底部区域
@property (nonatomic, strong) DVEEffectsBarBottomView *bottomView;
@property (nonatomic, strong) NSArray<DVEEffectValue *> *regulateModels;
@property (nonatomic, strong) DVEEffectValue *selectedValue;
@property (nonatomic) BOOL isValueChanged;

@property (nonatomic, weak) id<DVECoreRegulateProtocol> regulateEditor;

@end

@implementation DVERegulateBar

DVEAutoInject(self.vcContext.serviceProvider, regulateEditor, DVECoreRegulateProtocol)

- (void)dealloc
{
    DVELogInfo(@"DVERegulateBar dealloc");
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.slider.hidden = YES;
        self.slider.top = 0;
        [self.slider setValueRange:DVEMakeFloatRang(0, 100) defaultProgress:80];
       
        @weakify(self);
        [[self.slider rac_signalForControlEvents:UIControlEventValueChanged] subscribeNext:^(__kindof UIControl * _Nullable x) {
            @strongify(self);
            DVELogInfo(@"-----------%@",x);
            if (x) {
                [self updateRegulateIndensity:NO];
            }
        }];
        [[self.slider rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
            @strongify(self);
            DVELogInfo(@"-----------%@",x);
            if (x) {
                [self updateRegulateIndensity:YES];
            }
        }];
        
        [self addSubview:self.pickerView];
        [self.pickerView mas_makeConstraints:^(MASConstraintMaker *make) {
            id<DVEPickerUIConfigurationProtocol> config = self.pickerView.uiConfig;
            make.height.mas_equalTo(config.effectUIConfig.effectListViewHeight + config.categoryUIConfig.categoryTabListViewHeight);
            make.left.right.equalTo(self);
            make.top.equalTo(self).offset(50);
        }];
        [self addSubview:self.bottomView];
        [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.pickerView.mas_bottom);
            make.left.right.bottom.equalTo(self);
        }];
    }
    
    return self;
}

- (void)updateRegulateIndensity:(BOOL)commit
{
    if (self.selectedValue) {
        self.isValueChanged = YES;
        self.selectedValue.indesty = (NSInteger)self.slider.value * 0.01;
        [self.regulateEditor addOrUpdateAjustFeatureWithPath:self.selectedValue.sourcePath
                                                        name:self.selectedValue.name
                                                  identifier:self.selectedValue.identifier
                                                   intensity:self.selectedValue.indesty
                                                 resourceTag:(NLEResourceTag)self.selectedValue.resourceTag
                                                  needCommit:commit];
    }
    [self updateResetEnable];
}


- (void)setUpData
{
    [self.pickerView updateLoading];
    
    @weakify(self);
    [[DVEBundleLoader shareManager] adjust:self.vcContext handler:^(NSArray<DVEEffectValue *> * _Nullable datas, NSString * _Nullable error) {
        @strongify(self);
        DVEModuleBaseCategoryModel *categoryModel = [DVEModuleBaseCategoryModel new];
        DVEEffectCategory* category = [DVEEffectCategory new];
        category.models = datas;
        categoryModel.category = category;
        @weakify(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);
            if(!error){
                self.regulateModels = datas;
                [self.pickerView updateCategory:@[categoryModel]];
                [self.pickerView updateFetchFinish];
                [self updateRegulateModels];
            }else{
                [DVECustomerHUD showMessage:error];
                [self.pickerView updateFetchError];
            }
        });
    }];
}

- (UIView*)bottomView
{
    if(!_bottomView) {
        @weakify(self);
        _bottomView = [DVEEffectsBarBottomView newActionBarWithTitle:NLELocalizedString(@"ck_adjust",@"调节") action:^{
            @strongify(self);
            if (self.isValueChanged) {
                self.isValueChanged = NO;
                
            }
            [self dismiss:YES];
            [DVEAutoInline(self.vcContext.serviceProvider, DVECoreActionServiceProtocol) refreshUndoRedo];
        }];
        [_bottomView setResetButtonHidden:NO];
        [_bottomView setResetButtonEnable:YES];
        [_bottomView setupResetBlock:^{
            [self resetRegulateMethod];
        }];
    }
    return _bottomView;
}

- (DVEPickerView *)pickerView
{
    if (!_pickerView) {
        DVERegulateUIConfiguration *config = [[DVERegulateUIConfiguration alloc] init];
        _pickerView = [[DVEPickerView alloc] initWithUIConfig:config];
        _pickerView.delegate = self;
    }
    return _pickerView;
}

- (void)pickerView:(DVEPickerView *)pickerView didSelectTabIndex:(NSInteger)index
{
    
}

- (BOOL)pickerView:(DVEPickerView *)pickerView isSelected:(DVEEffectValue*)sticker
{
    return [self.selectedValue.identifier isEqualToString:sticker.identifier];
}

- (void)pickerViewDidClearSticker:(DVEPickerView *)pickerView
{
    
}

- (void)pickerView:(DVEPickerView *)pickerView
willDisplaySticker:(DVEEffectValue*)sticker
         indexPath:(NSIndexPath *)indexPath
{
    
}

- (void)pickerView:(DVEPickerView *)pickerView
  didSelectSticker:(DVEEffectValue*)sticker
          category:(id<DVEPickerCategoryModel>)category
         indexPath:(NSIndexPath *)indexPath
{
    DVEEffectValue *model = sticker;
    
    if (model.status == DVEResourceModelStatusDefault) {
        if ([self.selectedValue.identifier isEqualToString:model.identifier]) {
            return;
        }
        self.slider.hidden = NO;
        model.indesty = self.slider.value * 0.01;
        self.selectedValue = model;
        [pickerView updateSelectedStickerForId:model.identifier];
        [self dealSliderRangeWithIndex:self.selectedValue];
        NSDictionary *adjustDic = [self.regulateEditor currentAdjustIntensity];
        if (adjustDic.count == 0) {
            [self updateRegulateIndensity:YES];
        }
        NSDictionary *dic = @{@"action":sticker.name ?:@""};
        [DVEReportUtils logEvent:@"video_edit_config_click" params:dic];
        self.isValueChanged = YES;

        return;
    } else if (model.status == DVEResourceModelStatusNeedDownlod || model.status == DVEResourceModelStatusDownlodFailed) {
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
    [pickerView updateStickerStatusForId:model.identifier];
}

- (void)dealSliderRangeWithIndex:(DVEEffectValue*)value
{
    [self updateRegulateModels];
    float progress = value.indesty * 100;
    if([value.name isEqualToString:@"亮度"]){
        [self.slider setValueRange:DVEMakeFloatRang(100, 50) defaultProgress:progress];
    }else if([value.name isEqualToString:@"曝光"]){
        [self.slider setValueRange:DVEMakeFloatRang(100, 50) defaultProgress:progress];
    }else if([value.name isEqualToString:@"色调"]){
        [self.slider setValueRange:DVEMakeFloatRang(100, 50) defaultProgress:progress];
    }else if([value.name isEqualToString:@"对比度"]){
        [self.slider setValueRange:DVEMakeFloatRang(100, 50) defaultProgress:progress];
    }else if([value.name isEqualToString:@"色温"]){
        [self.slider setValueRange:DVEMakeFloatRang(100, 50) defaultProgress:progress];
    }else if([value.name isEqualToString:@"饱和度"]){
        [self.slider setValueRange:DVEMakeFloatRang(100, 50) defaultProgress:progress];
    }else if([value.name isEqualToString:@"褪色"]){
        [self.slider setValueRange:DVEMakeFloatRang(0, 100) defaultProgress:progress];
    }else if([value.name isEqualToString:@"高光"]){
        [self.slider setValueRange:DVEMakeFloatRang(100, 50) defaultProgress:progress];
    }else if([value.name isEqualToString:@"阴影"]){
        [self.slider setValueRange:DVEMakeFloatRang(0, 100) defaultProgress:progress];
    }else if([value.name isEqualToString:@"暗角"]){
        [self.slider setValueRange:DVEMakeFloatRang(0, 100) defaultProgress:progress];
    }else if([value.name isEqualToString:@"锐化"]){
        [self.slider setValueRange:DVEMakeFloatRang(0, 100) defaultProgress:progress];
    }
}

- (void)showInView:(UIView *)view animation:(BOOL)animation
{
    [super showInView:view animation:(BOOL)animation];
    [self setUpData];
    self.selectedValue = nil;

    NSDictionary *dic = [self.regulateEditor currentAdjustIntensity];
    
    for (DVEEffectValue *model in self.regulateModels) {
        NSNumber *intensity = [dic valueForKey:model.identifier];
        if (intensity) {
            model.indesty = intensity.floatValue;
        } else {
            model.indesty = 0;
        }
    }
    self.slider.hidden = YES;
}

- (void)updateRegulateModels
{
    NSDictionary *dic = [self.regulateEditor currentAdjustIntensity];

    for (DVEEffectValue *model in self.regulateModels) {
        NSNumber *intensity = [dic valueForKey:model.identifier];
        if (intensity) {
            model.indesty = intensity.floatValue;
        } else {
            model.indesty = 0;
        }
    }
    [self updateResetEnable];
}

- (void)updateResetEnable
{
    BOOL isResetEnable = NO;
    for (DVEEffectValue *model in self.regulateModels) {
        if (model.indesty != 0) {
            isResetEnable = YES;
        }
    }
    [self.bottomView setResetButtonEnable:isResetEnable];
}

- (void)undoRedoClikedByUser
{
    DVELogInfo(@"undoRedoClikedByUser -----");
    
    NSDictionary *dic = [self.regulateEditor currentAdjustIntensity];
    NSInteger index = -1;
    for(NSInteger i = 0; i<self.regulateModels.count; i++){
        DVEEffectValue *model = self.regulateModels[i];
        NSNumber *intensity = [dic valueForKey:model.identifier];
        if (intensity) {
            if (intensity.floatValue != model.indesty) {
                index = i;
            }
            model.indesty = intensity.floatValue;
        } else {
            if (model.indesty != 0) {
                index = i;
            }
            model.indesty = 0;
        }
    }
    if(index>= 0 && index < self.regulateModels.count){
        self.selectedValue = [self.regulateModels objectAtIndex:index];
        self.slider.value = self.selectedValue.indesty * 100;
        self.slider.hidden = NO;
        [self.pickerView updateSelectedStickerForId:self.selectedValue.identifier];
        [self.pickerView currentCategorySelectItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]
                                                animated:YES
                                          scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
        [self dealSliderRangeWithIndex:self.selectedValue];
    }
    [self updateResetEnable];
    if ([self.regulateEditor currentAdjustIntensity].count == 0) {
        [self dismiss:YES];
    }
}

- (void)resetAllRegulateModels
{
    [self.regulateEditor resetAllRegulateNeedCommit:YES];
    self.slider.value = 0;
    [self updateRegulateModels];
}

- (void)resetRegulateMethod
{
    DVENotificationAlertView *alerView = [DVENotification showTitle:@"重置参数" message:@"确定重置所有参数吗？" leftAction:@"取消" rightAction:@"确定"];
    alerView.leftActionBlock = ^(UIView * _Nonnull view) {
        DVELogInfo(@"取消重置按钮被点击了");
    };
    alerView.rightActionBlock = ^(UIView * _Nonnull view) {
        DVELogInfo(@"确定重置按钮被点击了");
        [self resetAllRegulateModels];
    };
}

@end

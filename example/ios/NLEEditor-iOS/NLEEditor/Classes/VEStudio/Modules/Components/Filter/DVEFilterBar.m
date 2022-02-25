//
//  DVEFilterBar.m
//  TTVideoEditorDemo
//
//  Created by bytedance on 2020/12/20
//  Copyright © 2020 bytedance. All rights reserved.
//

#import "DVEFilterBar.h"
#import "DVEFilterItemCell.h"
#import "DVEVCContext.h"
#import "DVEBundleLoader.h"
#import <DVETrackKit/UIView+VEExt.h>
#import "NSString+VEToImage.h"
#import "DVEEffectsBarBottomView.h"
#import "DVEPickerView.h"
#import "DVEModuleBaseCategoryModel.h"
#import "DVEFilterPickerUIDefaultConfiguration.h"
#import "DVECustomerHUD.h"
#import "DVELoggerImpl.h"
#import <Masonry/Masonry.h>
#import <ReactiveObjC/ReactiveObjC.h>

#define kVEVCFilterItemIdentifier @"kVEVCFilterItemIdentifier"

@interface DVEFilterBar ()<DVEPickerViewDelegate>

///滤镜数据源
@property (nonatomic, strong) NSArray<DVEModuleBaseCategoryModel *> *filterDataSource;
///当前选中滤镜
@property (nonatomic, strong) DVEEffectValue *curValue;
///滤镜区域
@property (nonatomic, strong) DVEPickerView *filterPickerView;
///底部区域
@property (nonatomic, strong) UIView *bottomView;

@property (nonatomic, weak) id<DVECoreFilterProtocol> filterEditor;

@end


@implementation DVEFilterBar

DVEAutoInject(self.vcContext.serviceProvider, filterEditor, DVECoreFilterProtocol)

- (void)dealloc
{
    DVELogInfo(@"VEVCFilterBar dealloc");
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self initView];
    }
    
    return self;
}

- (void)showInView:(UIView *)view animation:(BOOL)animation
{
    [super showInView:view animation:(BOOL)animation];
    [self initData];
}

-(void)setCurValue:(DVEEffectValue *)curValue
{
    if(curValue){
        if (curValue.valueState == VEEffectValueStateShuntDown) {
            [self.filterEditor deleteCurrentFilterNeedCommit:YES];
        }else{
            [self.filterEditor addOrUpdateFilterWithPath:curValue.sourcePath name:curValue.name identifier:curValue.identifier intensity:curValue.indesty resourceTag:(NLEResourceTag)curValue.resourceTag needCommit:YES];
        }
    }
    else if(_curValue && _curValue.valueState != VEEffectValueStateShuntDown){
        [self.filterEditor deleteCurrentFilterNeedCommit:YES];
    }
    _curValue = curValue;
}

#pragma mark - private Method

- (void)initView
{
    self.slider.top = 0;
    [self.slider setValueRange:DVEMakeFloatRang(0, 100) defaultProgress:80];

    [self addSubview:self.filterPickerView];
    [self.filterPickerView mas_makeConstraints:^(MASConstraintMaker *make) {
        id<DVEPickerUIConfigurationProtocol> config = self.filterPickerView.uiConfig;
        make.height.mas_equalTo(config.effectUIConfig.effectListViewHeight + config.categoryUIConfig.categoryTabListViewHeight);
        make.top.equalTo(self).mas_offset(60);
        make.left.right.equalTo(self);
    }];
    [self addSubview:self.bottomView];
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.filterPickerView.mas_bottom);
        make.left.right.bottom.equalTo(self);
    }];
    
    @weakify(self);
    [[self.slider rac_signalForControlEvents:UIControlEventValueChanged] subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self);
        DVELogInfo(@"-----------%@",x);
        if (x) {
            [self updateFilterIndensity:NO];
        }
    }];
    [[self.slider rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self);
        DVELogInfo(@"-----------%@",x);
        if (x) {
            [self updateFilterIndensity:YES];
        }
    }];
}



- (void)initData
{
    self.slider.hidden = YES;
    self.slider.value = 80;
    _curValue = nil;
    
    @weakify(self);
    [[DVEBundleLoader shareManager] filter:self.vcContext handler:^(NSArray<DVEEffectValue *> * _Nullable datas, NSString * _Nullable error) {
        @strongify(self);
        NSMutableArray *valueArr = [NSMutableArray arrayWithCapacity:1 + datas.count];
        
        DVEEffectValue *value = [DVEEffectValue new];
        value.valueType = VEEffectValueTypeFilter;
        value.indesty = 0.8;
        value.name = NLELocalizedString(@"ck_none", @"无");
        value.valueState = VEEffectValueStateShuntDown;
        value.assetImage = @"iconFilterwu".dve_toImage;
        value.identifier = value.name;
        [valueArr addObject:value];
        
        [valueArr addObjectsFromArray:datas];

        DVEModuleBaseCategoryModel* categoryModel = [DVEModuleBaseCategoryModel new];
        DVEEffectCategory* category = [DVEEffectCategory new];
        category.models = valueArr;
        categoryModel.category = category;

        
        @weakify(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);
            if(!error){
                self.filterDataSource = @[categoryModel];
                [self.filterPickerView updateCategory:self.filterDataSource];
                [self.filterPickerView updateFetchFinish];
                @weakify(self);
                [self.filterPickerView performBatchUpdates:^{
                    
                } completion:^(BOOL finished) {
                    @strongify(self);
                    if(finished){
                        [self performSelectorOnMainThread:@selector(initSelectFilter) withObject:nil waitUntilDone:NO];
                    }
                }];
            }else{
                [DVECustomerHUD showMessage:error];
                [self.filterPickerView updateFetchError];
            }
        });
    }];

}

-(BOOL)initSelectFilter
{
    NSDictionary *dic = [self.filterEditor currentFilterIntensity];
    NSString *identifier = [dic objectForKey:@"identifier"];
    NSArray* models = self.filterDataSource.firstObject.models;
    if(dic && identifier){
        NSArray* models = self.filterDataSource.firstObject.models;
        for (NSInteger i = 1; i < models.count; i ++) {//忽略第一个“无”
            DVEEffectValue *model = models[i];
            if ([model.identifier isEqualToString:identifier]) {
                NSNumber *intensity = [dic objectForKey:@"intensity"];
                model.indesty = intensity.floatValue;
                [self.filterPickerView currentCategorySelectItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
                self.slider.value = model.indesty * 100;
                self.slider.hidden = NO;
                _curValue = model;
                model.valueState = VEEffectValueStateInUse;
                [self.filterPickerView updateSelectedStickerForId:model.identifier];
            } else {
                model.valueState = VEEffectValueTypeNone;
                model.indesty = 0.8;
            }
        }
        return YES;
    }else{
        for (NSInteger i = 1; i < models.count; i ++) {//忽略第一个“无”
            DVEEffectValue *model = models[i];
            model.valueState = VEEffectValueTypeNone;
        }
        _curValue = models[0];
        [self.filterPickerView currentCategorySelectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
        [self.filterPickerView updateSelectedStickerForId:_curValue.identifier];
    }
    
    return NO;
}

- (void)updateFilterIndensity:(BOOL)needCommit
{
    if (self.curValue) {
        self.curValue.indesty = self.slider.value * 0.01;
        if (self.curValue.valueState == VEEffectValueStateShuntDown) {
            [self.filterEditor deleteCurrentFilterNeedCommit:needCommit];
        } else {
            [self.filterEditor addOrUpdateFilterWithPath:self.curValue.sourcePath name:self.curValue.name identifier:self.curValue.identifier intensity:self.curValue.indesty resourceTag:(NLEResourceTag)self.curValue.resourceTag needCommit:needCommit];
        }
    }
}

- (void)undoRedoClikedByUser
{
    [self.filterPickerView reloadData];
    @weakify(self);
    [self.filterPickerView performBatchUpdates:^{

    } completion:^(BOOL finished) {
        @strongify(self);
        if(finished){
            if(![self initSelectFilter]){
                self.slider.hidden = YES;
                self.curValue = nil;
                self.slider.value = 80;
            }
        }
        if ([self.filterEditor currentFilterIntensity].count == 0) {
            [self dismiss:YES];
        }
    }];
}

#pragma mark - layz Method

- (UIView*)bottomView
{
    if(!_bottomView) {
        @weakify(self);
        _bottomView = [DVEEffectsBarBottomView newActionBarWithTitle:NLELocalizedString(@"ck_filter",@"滤镜") action:^{
            @strongify(self);
            [self dismiss:YES];
        }];
    }
    return _bottomView;
}

- (DVEPickerView *)filterPickerView {

    if (!_filterPickerView) {
        _filterPickerView = [[DVEPickerView alloc] initWithUIConfig:[DVEFilterPickerUIDefaultConfiguration new]];
        _filterPickerView.delegate = self;
        _filterPickerView.backgroundColor = [UIColor clearColor];
    }
    return _filterPickerView;
}
#pragma mark - AWEStickerPickerViewDelegate

- (BOOL)pickerView:(DVEPickerView *)pickerView isSelected:(DVEEffectValue*)sticker{
    return sticker.valueState == VEEffectValueStateInUse;
}

- (void)pickerView:(DVEPickerView *)pickerView
         didSelectSticker:(DVEEffectValue*)sticker
                 category:(id<DVEPickerCategoryModel>)category
         indexPath:(NSIndexPath *)indexPath{


    DVEEffectValue *filterValue = sticker;
    
    if(filterValue.status == DVEResourceModelStatusDefault){
        if(self.curValue == filterValue) return;
        
        //更新上次选择的“特效”状态为none，如果是清空“特效”对象不做状态更新
        if(self.curValue.valueState == VEEffectValueStateShuntDown){
            
        }else{
            self.curValue.valueState = VEEffectValueStateNone;
        }
        
        //更新目前选择的“特效”状态为inUse，如果是清空“特效”对象不做状态更新
        if(indexPath.row == 0){
            self.slider.hidden = YES;
        }else{
            self.slider.hidden = NO;
            filterValue.valueState = VEEffectValueStateInUse;
        }
        
        filterValue.indesty = self.slider.value * 0.01;
        self.curValue = filterValue;
        
        [pickerView updateSelectedStickerForId:self.curValue.identifier];
        return;
    }else if(filterValue.status == DVEResourceModelStatusNeedDownlod || filterValue.status == DVEResourceModelStatusDownlodFailed){
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
    [pickerView updateStickerStatusForId:filterValue.identifier];
    
}

- (void)pickerView:(DVEPickerView *)pickerView didSelectTabIndex:(NSInteger)index{
    
}


- (void)pickerViewDidClearSticker:(DVEPickerView *)pickerView {
    
}

@end

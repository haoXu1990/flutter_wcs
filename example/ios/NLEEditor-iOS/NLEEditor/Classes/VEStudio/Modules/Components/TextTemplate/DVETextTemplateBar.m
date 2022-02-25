//
//  DVETextTemplateBar.m
//  NLEEditor
//
//  Created by bytedance on 2021/6/23.
//

#import "DVETextTemplateBar.h"
#import "DVEPickerView.h"
#import "DVEVCContext.h"
#import "DVEBundleLoader.h"
#import <DVETrackKit/UIView+VEExt.h>
#import "DVETextTemplatePickerUIConfiguration.h"
#import "DVEEffectsBarBottomView.h"
#import "DVEModuleBaseCategoryModel.h"
#import "DVECustomerHUD.h"
#import <Masonry/Masonry.h>
#import "DVEViewController.h"
#import "DVEComponentViewManager.h"
@interface DVETextTemplateBar()<DVEPickerViewDelegate>
///选择区域
@property (nonatomic, strong) DVEPickerView *effectsPickerView;
///底部区域
@property (nonatomic, strong) UIView *bottomView;
///当前选中特效
@property (nonatomic, strong) DVEEffectValue *curValue;
///数据源
@property (nonatomic, strong) NSArray<DVEModuleBaseCategoryModel *> *effectsDataSource;
// TODO: 换成segmentId会好些
///新增模板ID
@property (nonatomic, strong) NSString* effectObjID;
///初始特效
@property (nonatomic, strong) NSString *itValue;

@property (nonatomic, weak) id<DVECoreTextTemplateProtocol> textTemplateEditor;
@property (nonatomic, weak) id<DVECoreActionServiceProtocol> actionService;

@end

@implementation DVETextTemplateBar

DVEAutoInject(self.vcContext.serviceProvider, textTemplateEditor, DVECoreTextTemplateProtocol)
DVEAutoInject(self.vcContext.serviceProvider, actionService, DVECoreActionServiceProtocol)

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self initView];
    }
    
    return self;
}

- (void)initView
{
    [self addSubview:self.effectsPickerView];
    [self.effectsPickerView mas_makeConstraints:^(MASConstraintMaker *make) {
        id<DVEPickerUIConfigurationProtocol> config = self.effectsPickerView.uiConfig;
        make.height.mas_equalTo(config.effectUIConfig.effectListViewHeight + config.categoryUIConfig.categoryTabListViewHeight);
        make.top.left.right.equalTo(self);
    }];
    [self addSubview:self.bottomView];
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.effectsPickerView.mas_bottom);
        make.left.right.bottom.equalTo(self);
    }];
}

- (void)initData
{
    [self.effectsPickerView updateLoading];
    
    NLETrackSlot_OC* slot = self.vcContext.mediaContext.selectTextSlot;
    NLESegmentTextTemplate_OC* seg = nil;
    BOOL inUse = NO;
    NSString* sourcePath = nil;
    
    if ([slot.segment isKindOfClass:NLESegmentTextTemplate_OC.class]) {
        seg =  (NLESegmentTextTemplate_OC*)slot.segment;
        NLEResourceNode_OC *resEffect = seg.effectSDKFile;
        // note(caishaowu): 因为addTemplateWithSeg返回的是 slot.name
        self.effectObjID = slot.name;
        sourcePath = resEffect.resourceFile;
        inUse = seg.effectSDKFile != nil;
    }

    // 检查当前使用的模板名称
    if(inUse && sourcePath.length>0){
        DVEEffectValue* eff = [DVEEffectValue new];
        eff.sourcePath = sourcePath;
        eff.identifier = eff.name;
        eff.valueState = VEEffectValueStateInUse;
        _curValue = eff;
        self.itValue = eff.identifier;
    }
    
    @weakify(self);
    [[DVEBundleLoader shareManager] textTemplateCategory:self.vcContext handler:^(NSArray<DVEEffectCategory *> * _Nullable categorys, NSString * _Nullable error) {
        @strongify(self);
        NSMutableArray *valueArr = [NSMutableArray new];
        for(DVEEffectCategory* cat in categorys){
            DVEModuleBaseCategoryModel* category = [DVEModuleBaseCategoryModel new];
            category.category = cat;
            [valueArr addObject:category];
        }
        
        @weakify(self);
        ///目前只支持单类
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);
            if(!error){
                self.effectsDataSource = valueArr;
                [self.effectsPickerView updateCategory:self.effectsDataSource];
                if(self.effectsDataSource.count > 0){
                    [self pickerView:self.effectsPickerView didSelectTabIndex:0];
                }
                [self.effectsPickerView updateFetchFinish];
            }else{
                [DVECustomerHUD showMessage:error];
                [self.effectsPickerView updateFetchError];
            }
        });
    }];
}

-(void)showInView:(UIView *)view animation:(BOOL)animation{
    [super showInView:view animation:(BOOL)animation];
    [self initData];
}

#pragma mark - private Method
/// 添加编辑框
- (void)p_addEditBox {
    DVEViewController *parentVC = (DVEViewController *)self.parentVC;
    NSString *segmentId = self.effectObjID;
    [parentVC.stickerEditAdatper addEditBoxForSticker:segmentId isText:YES];
}

- (void)p_removeSelectedTextTemplate {
    NSString *segmentId = self.effectObjID;
    [self.textTemplateEditor removeTextTemplate:segmentId isCommit:NO];
    DVEViewController *parentVC = (DVEViewController *)self.parentVC;
    [parentVC.stickerEditAdatper removeStickerBox:segmentId];
}
/// 替换模板
- (void)p_replaceTemplateWithEffect:(DVEEffectValue *)effect {
    @weakify(self);
    // 先拿到slot与track信息，避免删除后，获取不到
    NLETrackSlot_OC *slot = self.vcContext.mediaContext.selectTextSlot;
    Float64 start = CMTimeGetSeconds(slot.startTime);
    Float64 end = CMTimeGetSeconds(slot.endTime);

    self.effectObjID = [self.textTemplateEditor replaceTemplateAtSlot:slot
                                                            startTime:start
                                                              endTime:end
                                                                 path:effect.sourcePath
                                                         depResModels:effect.textTemplateDeps completion:^{
        @strongify(self);
        [self p_refreshSelectedTextTemplate:slot];
    }];
}

- (void)p_refreshSelectedTextTemplate:(NLETrackSlot_OC*)slot {
    DVEViewController *parentVC = (DVEViewController *)self.parentVC;
    NSString *segmentId = self.effectObjID;
    [parentVC.stickerEditAdatper replaceItemsWithSlots:@[slot]];
    [parentVC.stickerEditAdatper activeEditBox:segmentId];
}

- (void)p_addTemplateWithEffect:(DVEEffectValue *)effect {
    // 添加到主轨道
    @weakify(self);
    self.effectObjID = [self.textTemplateEditor addTemplateWithPath:effect.sourcePath
                                                       depResModels:effect.textTemplateDeps
                                                         needCommit:YES completion:^{
        @strongify(self);
        [self p_addEditBox];
    }];
}

#pragma mark - layz Method

- (void)setCurValue:(DVEEffectValue *)curValue {
    if(curValue){
        if(_curValue){ //已有特效，则替换
            [self p_replaceTemplateWithEffect:curValue];
        } else {
            [self p_addTemplateWithEffect:curValue];
        }
    } else if (_curValue){ //删除特效
        [self p_removeSelectedTextTemplate];
    }
    _curValue = curValue;
}

- (DVEPickerView *)effectsPickerView {

    if (!_effectsPickerView) {
        _effectsPickerView = [[DVEPickerView alloc] initWithUIConfig:[DVETextTemplatePickerUIConfiguration new]];
        _effectsPickerView.delegate = self;
        _effectsPickerView.backgroundColor = [UIColor clearColor];
    }
    return _effectsPickerView;
}

- (UIView*)bottomView
{
    if(!_bottomView) {
        @weakify(self);
        _bottomView = [DVEEffectsBarBottomView newActionBarWithTitle:NLELocalizedString(@"ck_text_template_select", @"选择模板")  action:^{
            @strongify(self);
            
            if(!(self.itValue == nil && self.curValue == nil) && ![self.itValue isEqualToString:self.curValue.identifier]){
                [self.actionService commitNLE:YES];
            }
            
            if (self.vcContext.mediaContext.selectTextSlot) {
                // 显示底部编辑 
                [[DVEComponentViewManager sharedManager] showComponentType:DVEBarComponentTypeTextTemplate groupTpye:DVEBarSubComponentGroupEdit];
            }
            // 所有模板的 slot 取消预览
            [self.textTemplateEditor updateAllTextTemplateSlotPreviewMode:0];
            
            [self dismiss:YES];
            [self.actionService refreshUndoRedo];
        }];
    }
    return _bottomView;
}

#pragma mark - AWEStickerPickerViewDelegate

- (void)pickerView:(DVEPickerView *)pickerView didSelectTabIndex:(NSInteger)index{
    DVEModuleBaseCategoryModel* ca = self.effectsDataSource[index];
    if(ca.category.models.count == 0){
        [pickerView updateLoadingWithTabIndex:index];
        [[DVEBundleLoader shareManager] textTemplate:self.vcContext category:ca.category handler:^(NSArray<DVEEffectValue *> * _Nullable datas, NSString * _Nullable error) {
            for(DVEEffectValue* da in datas){
                da.identifier = da.name;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if(!error){
                    ca.category.models = datas;
                    [pickerView updateFetchFinishWithTabIndex:index];
                }else{
                    [DVECustomerHUD showMessage:error];
                }
            });
        }];
    }
}

- (BOOL)pickerView:(DVEPickerView *)pickerView isSelected:(DVEEffectValue*)sticker{
    return [sticker.sourcePath isEqualToString:self.curValue.sourcePath];
}

- (void)pickerView:(DVEPickerView *)pickerView
         didSelectSticker:(DVEEffectValue*)sticker
                 category:(id<DVEPickerCategoryModel>)category
         indexPath:(NSIndexPath *)indexPath{
    DVEEffectValue* model = sticker;
    if(sticker.status == DVEResourceModelStatusDefault){
        
        if([self.curValue.identifier isEqualToString:model.identifier]){
            self.curValue = nil;
            [pickerView updateSelectedStickerForId:@""];
            return;
        }
        self.curValue = model;
        
    }else if(sticker.status == DVEResourceModelStatusNeedDownlod || sticker.status == DVEResourceModelStatusDownlodFailed){
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

    [pickerView updateSelectedStickerForId:model.identifier];
    
}

- (void)pickerViewDidClearSticker:(DVEPickerView *)pickerView{
    self.curValue = nil;
    [pickerView updateSelectedStickerForId:@""];
}

- (void)pickerView:(DVEPickerView *)pickerView willDisplaySticker:(DVEEffectValue*)sticker indexPath:(NSIndexPath *)indexPath{
    
}

@end

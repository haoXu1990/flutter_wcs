//
//  DVEComponentAction+TextTemplate.m
//  NLEEditor
//
//  Created by bytedance on 2021/6/25.
//
//  处理各种事情
#import "DVEComponentAction+TextTemplate.h"
#import "DVEComponentAction+Private.h"
#import "DVEComponentAction+Text.h"
#import "DVETextTemplateBar.h"
#import "DVECustomerHUD.h"
#import "DVETextTemplateInputManager.h"
@implementation DVEComponentAction (TextTemplate)

/// 一级菜单入口展示控制
-(NSNumber*)showTextTemplateStatus:(id<DVEBarComponentProtocol>)component
{
    return @(DVEBarComponentViewStatusHidden);
}

/// 在轨道里显示模板
-(void)textTemplateComponentOpen:(id<DVEBarComponentProtocol>)component
{
    self.vcContext.mediaContext.multipleTrackType = DVEMultipleTrackTypeTextSticker;
    [self.parentVC showEditStickerViewWithType:VEVCStickerEditTypeTextTemplate];
    // 根据情况，有可能显示底部编辑区
    [self openSubComponent:component];
}
/// 显示模板面板
-(void)openTextTemplate:(id<DVEBarComponentProtocol>)component
{
    [self openParentComponent:component];
    NSString *segmentId = @"";
    [self showTextTemplate:segmentId];
}

- (void)showTextTemplate:(NSString*)segmentId
{
    CGFloat H =  214 + 50 + 40 + VEBottomMargn;
    CGFloat Y = VE_SCREEN_HEIGHT - H;

    DVETextTemplateBar* barView = [[DVETextTemplateBar alloc] initWithFrame:CGRectMake(0, Y, VE_SCREEN_WIDTH, H)];
    [self showActionView:barView];
}

- (void)replaceTextTemplate:(id<DVEBarComponentProtocol>)component {
    [self openTextTemplate:component];
}

- (void)splitTextTemplate:(id<DVEBarComponentProtocol>)component {
    NSString *newSegId = [self splitSlot];
    if (!newSegId) {
        return;
    }
    [self.parentVC.stickerEditAdatper addEditBoxForSticker:newSegId isText:YES];
}

- (void)copyTextTemplate:(id<DVEBarComponentProtocol>)component {
    DVELogInfo(@"copy one text template track");
    //默认追加到在当前模板下面
    id<DVECoreTextTemplateProtocol> editor = self.textTemplateEditor;
    NSString *newSegId = [editor copyTextTemplateWithIsCommit:YES];
    // 添加编辑框
    [self.parentVC.stickerEditAdatper addEditBoxForSticker:newSegId isText:YES];
}

- (void)editTextTemplate:(id<DVEBarComponentProtocol>)component {
    DVELogInfo(@"edit one text template track");
    [[DVETextTemplateInputManager sharedInstance] showWithTextIndex:0
                                                             source:DVETextTemplateInputManagerSourceBottomBtn];
}

- (void)deleteTextTemplate:(id<DVEBarComponentProtocol>)component {
    DVELogInfo(@"delete one text template track");
    NSString *segmentId = [self textTemplateSegmentId];
    if(!segmentId)return;
    [self.textTemplateEditor removeTextTemplate:segmentId isCommit:YES];
    [self.parentVC.stickerEditAdatper removeStickerBox:segmentId];
    
    [self openParentComponent:component];
}
- (void)textTemplateComponentClose:(id<DVEBarComponentProtocol>)component {
    [self hideMultipleTrackIfNeed];
    ///防止外部监听mediaContext信号重复触发action，需要加标志
//    [DVEComponentViewManager sharedManager].enable = NO;
    self.vcContext.mediaContext.selectTextSlot = nil;
//    [DVEComponentViewManager sharedManager].enable = YES;
    [self openParentComponent:component];
}

-(NSString*)textTemplateSegmentId
{
    NLETrackSlot_OC* slot = self.vcContext.mediaContext.selectTextSlot;
    if (slot && [slot.segment isKindOfClass:NLESegmentTextTemplate_OC.class]) {
        return slot.nle_nodeId;
    }
    return nil;
}

@end

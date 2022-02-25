//
//  DVEStickerEditAdpter.h
//  TTVideoEditorDemo
//
//  Created by bytedance on 2020/12/20
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DVETrackKit/DVETransformEditView.h>
#import "DVEVCContext.h"
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, VEVCStickerEditType) {
    VEVCStickerEditTypeNone = 0,
    VEVCStickerEditTypeSticker,//贴纸，信息化贴纸和图片贴纸为一个类型的轨道
    VEVCStickerEditTypeText,//文本，有自己单独的轨道
    VEVCStickerEditTypeTextTemplate,
};

@class NLEVideoFrameModel_OC;
@class DVETextBar;

@interface DVEStickerEditAdpter : NSObject<DVECoreActionNotifyProtocol>

//// 适用于文字气泡更新后，影响大小
- (void)refreshEditBox:(nullable NSString *)segmentId;

- (void)refreshItems:(NSArray *)slots;
- (void)replaceItemsWithSlots:(NSArray *)slots;

- (void)isShowBox;

- (void)activeEditBox:(nullable NSString *)segmentId;

- (void)addEditBoxForSticker:(NSString *)segmentId isText:(BOOL)text;

- (void)addEditBoxForStickerWithVideoCover:(NLEVideoFrameModel_OC *)coverModel
                                 segmentId:(NSString *)segmentId;

- (void)removeStickerBox:(NSString *)segmentId;

- (void)changeSelectTextSlot:(NSString *)segmentId;

- (void)showInPreview:(UIView *)view withType:(VEVCStickerEditType)type;
- (void)hideFromPreview;

@property (nonatomic,weak) DVEVCContext *vcContext;
@property (nonatomic,weak) DVETransformEditView *editView;
@property (nonatomic, assign) VEVCStickerEditType curType;
@property (nonatomic, weak) DVETextBar *textBar;
@end

NS_ASSUME_NONNULL_END

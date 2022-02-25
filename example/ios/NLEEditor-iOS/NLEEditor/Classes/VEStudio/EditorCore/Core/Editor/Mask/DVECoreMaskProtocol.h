//
//   DVECoreMaskProtocol.h
//   NLEEditor
//
//   Created  by bytedance on 2021/4/26.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//
    

#import "DVECoreProtocol.h"

@class DVEMaskConfigModel;
@class NLESegmentMask_OC;

NS_ASSUME_NONNULL_BEGIN

@protocol DVEMaskKeyFrameProtocol <NSObject>

- (void)maskKeyFrameDidChanged:(NLESegmentMask_OC *)mask;

@end

@protocol DVECoreMaskProtocol <DVECoreProtocol>

@property (nonatomic, weak) id<DVEMaskKeyFrameProtocol> keyFrameDelegate;

- (void)addOrChangeMaskWithEffectValue:(DVEMaskConfigModel *)eValue needCommit:(BOOL)commit;

- (void)updateOneMaskWithEffectValue:(DVEMaskConfigModel *)eValue needCommit:(BOOL)commit;

- (void)deletCurMaskEffectValueNeedCommit:(BOOL)commit;

- (NSDictionary *)currentMaskInfo;

/// 刷新关键帧参数
/// @param slot 主轨/副轨
- (void)refreshMaskForKeyFrameIfNeed:(NLETrackSlot_OC*)slot;

@end

NS_ASSUME_NONNULL_END

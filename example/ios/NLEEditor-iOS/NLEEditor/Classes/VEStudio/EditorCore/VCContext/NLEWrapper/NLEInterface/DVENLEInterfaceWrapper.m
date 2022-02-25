//
//  DVENLEInterfaceWrapper.m
//  NLEEditor
//
//  Created by bytedance on 2021/9/16.
//

#import "DVENLEInterfaceWrapper.h"
#import <NLEPlatform/NLEInterface.h>
#import <TTVideoEditor/IVEEffectProcess.h>

@interface DVENLEInterfaceWrapper ()

@property (nonatomic, weak) NLEInterface_OC *nle;

@end

@implementation DVENLEInterfaceWrapper

- (instancetype)initWithNLEInterface:(NLEInterface_OC *)nle
{
    self = [super init];
    if (self) {
        _nle = nle;
    }
    return self;
}

#pragma mark - DVENLEInterfaceProtocol

- (void)enableKeyFrameCallback
{
    [self.nle enableKeyFrameCallback];
}

- (void)addKeyFrameListener:(id<NLEKeyFrameCallbackProtocol>)listener
{
    [self.nle addKeyFrameListener:listener];
}

- (void)resetPlayerWithViews:(nullable NSArray<UIView *> *)views
{
    [self.nle resetPlayerWithViews:views];
}

- (NLETrackSlot_OC *)slotWithCanvasKeyFrameInfo:(NSMutableDictionary *)allCanvasKeyFrameInfo        
                                           slot:(NLETrackSlot_OC *)slot
{
    return [self.nle slotWithCanvasKeyFrameInfo:allCanvasKeyFrameInfo slot:slot];
}

- (CGFloat)audioVolumeKeyFrameInfoWithPTS:(NSUInteger)pts
                                     slot:(NLETrackSlot_OC *)slot
{
    return [self.nle audioVolumeKeyFrameInfoWithPTS:pts slot:slot];
}

- (NLESegmentMask_OC *)maskSegmentFromKeyFrameInfo:(NSMutableDictionary *)allFeatureKeyFrames
                                           forSlot:(NLETrackSlot_OC *)slot
{
    return [self.nle maskSegmentFromKeyFrameInfo:allFeatureKeyFrames forSlot:slot];
}

- (NLEAllKeyFrameInfo *)allKeyFrameInfoAtTime:(CMTime)time
{
    return [self.nle allKeyFrameInfoAtTime:time];
}

- (NLETextTemplateInfo *)textTemplateInfoForSlot:(NLETrackSlot_OC *)slot
{
    return [self.nle textTemplateInfoForSlot:slot];
}

- (NSInteger)setStickerPreviewMode:(NLETrackSlot_OC *)slot
                       previewMode:(int)previewMode
{
    return [self.nle setStickerPreviewMode:slot previewMode:previewMode];
}

- (NSInteger)stickerIdForSlot:(NSString *)slotId
{
    return [self.nle stickerIdForSlot:slotId];
}

- (AVURLAsset *)assetFromSlot:(NLETrackSlot_OC *)slot
{
    return [self.nle assetFromSlot:slot];
}

- (NSString *)getAbsolutePathWithResource:(NLEResourceNode_OC *)resourceNode
{
    return [self.nle getAbsolutePathWithResource:resourceNode];
}

- (NSString *)draftFolder
{
    return self.nle.draftFolder;
}

- (void)setDraftFolder:(NSString *)draftFolder
{
    self.nle.draftFolder = draftFolder;
}

- (HTSVideoData *)videoData
{
    return self.nle.veVideoData;
}

- (id<IVEEffectProcess>)getVideoProcess
{
    return [self.nle getVideoProcess];
}

- (CGSize)getstickerEditBoxSizeNormaliz:(NSInteger)stickerId
{
    return [self.nle getstickerEditBoxSizeNormaliz:stickerId];
}

- (void)setStickerLayer:(NSInteger)stickerId
                  layer:(NSInteger)layer
{
    [self.nle setStickerLayer:stickerId layer:layer];
}

@end

//
//   DVEMaskEditor.m
//   NLEEditor
//
//   Created  by bytedance on 2021/4/26.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//


#import "DVEMaskEditor.h"
#import "DVEMaskConfigModel.h"
#import "NSDictionary+DVE.h"

@interface DVEMaskEditor()<NLEKeyFrameCallbackProtocol>

@property (nonatomic) NSMutableDictionary <AVAsset *, VEAmazingFeature *> *maskFeatureMap;

@property (nonatomic, weak) id<DVECoreDraftServiceProtocol> draftService;
@property (nonatomic, weak) id<DVECoreActionServiceProtocol> actionService;
@property (nonatomic, weak) id<DVECoreKeyFrameProtocol> keyframeEditor;
@property (nonatomic, weak) id<DVENLEInterfaceProtocol> nle;

@end

@implementation DVEMaskEditor

@synthesize vcContext = _vcContext;
@synthesize keyFrameDelegate = _keyFrameDelegate;

DVEAutoInject(self.vcContext.serviceProvider, draftService, DVECoreDraftServiceProtocol)
DVEAutoInject(self.vcContext.serviceProvider, actionService, DVECoreActionServiceProtocol)
DVEAutoInject(self.vcContext.serviceProvider, keyframeEditor, DVECoreKeyFrameProtocol)
DVEAutoInject(self.vcContext.serviceProvider, nle, DVENLEInterfaceProtocol)

- (instancetype)initWithContext:(DVEVCContext *)context
{
    if(self = [super init]) {
        self.vcContext = context;
        [self.nle addKeyFrameListener:self];
    }
    return self;
}

- (NSMutableDictionary<AVAsset *,VEAmazingFeature *> *)maskFeatureMap
{
    if (!_maskFeatureMap) {
        _maskFeatureMap = [NSMutableDictionary dictionary];
    }
    
    return _maskFeatureMap;
}

- (void)addOrChangeMaskWithEffectValue:(DVEMaskConfigModel *)eValue needCommit:(BOOL)commit
{
    [self.vcContext.playerService pause];
    [self addOrChangeNLEMaskWithEffectValue:eValue needCommit:commit forSlot:[self.vcContext.mediaContext currentBlendVideoSlot]];
}

- (void)addOrChangeNLEMaskWithEffectValue:(DVEMaskConfigModel *)eValue needCommit:(BOOL)commit forSlot:(NLETrackSlot_OC *)selectSlot
{
    if (!selectSlot) return;
    
    NSString *relativePath = [self.draftService copyResourceToDraft:[NSURL fileURLWithPath:eValue.curValue.sourcePath] resourceType:NLEResourceTypeMask];
    
    NLEMask_OC *findMask = [[self.vcContext.mediaContext currentBlendVideoSlot] getMask].firstObject;
    if (!findMask) {
        NLEResourceNode_OC *maskResource = [[NLEResourceNode_OC alloc] init];
        maskResource.resourceId = eValue.curValue.identifier;
        maskResource.resourceFile = relativePath;
        maskResource.resourceType = NLEResourceTypeMask;
        maskResource.resourceName = eValue.curValue.name;
        
        NLESegmentMask_OC *maskSegment = [[NLESegmentMask_OC alloc] init];
        [maskSegment setEffectSDKMask:maskResource];
        [maskSegment setAspectRatio:eValue.aspectRatio];
        [maskSegment setWidth:eValue.width];
        [maskSegment setHeight:eValue.height];
        [maskSegment setCenterX:eValue.center.x];
        [maskSegment setCenterY:eValue.center.y];
        [maskSegment setRotation:eValue.rotation];
        [maskSegment setInvert:eValue.invert];
        [maskSegment setFeather:eValue.feather];
        [maskSegment setMaskType:eValue.curValue.mask];
        
        NLEMask_OC *mask = [NLEMask_OC new];
        [mask setSegmentMask:maskSegment];
        
        [selectSlot addMask:mask];

        [self.actionService commitNLE:commit];

    } else {
        NLESegmentMask_OC *maskSegment = [findMask segmentMask];
        [maskSegment setMaskType:eValue.curValue.mask];
        
        NLEResourceNode_OC *maskResource = maskSegment.getResource;
        maskResource.resourceId = eValue.curValue.identifier;
        maskResource.resourceFile = relativePath;
        maskResource.resourceType = NLEResourceTypeMask;
        maskResource.resourceName = eValue.curValue.name;
        [self.actionService commitNLE:commit];

    }
}

- (void)updateOneMaskWithEffectValue:(DVEMaskConfigModel *)eValue needCommit:(BOOL)commit
{
    [self.vcContext.playerService pause];
    
    NLETrackSlot_OC* selectSlot = [self.vcContext.mediaContext currentBlendVideoSlot];
    
    if (!selectSlot) return;
    NLEMask_OC *findMask = [[self.vcContext.mediaContext currentBlendVideoSlot] getMask].firstObject;
    if (!findMask) {
        return;
    }
    
    NLESegmentMask_OC *maskSegment = findMask.segmentMask;
    [maskSegment setAspectRatio:eValue.aspectRatio];
    [maskSegment setWidth:eValue.width];
    [maskSegment setHeight:eValue.height];
    [maskSegment setCenterX:eValue.center.x];
    [maskSegment setCenterY:eValue.center.y];
    [maskSegment setRotation:eValue.rotation];
    [maskSegment setInvert:eValue.invert];
    [maskSegment setFeather:eValue.feather];
    [maskSegment setRoundCorner:eValue.roundCorner];
    [maskSegment setMaskType:eValue.curValue.mask];
    
    maskSegment.effectSDKMask.resourceName = eValue.curValue.name;
    
    if([self.keyframeEditor hasKeyframe:selectSlot]){
        CMTime time = CMTimeMake(self.vcContext.playerService.currentPlayerTime * USEC_PER_SEC, USEC_PER_SEC);
        [self.keyframeEditor addOrUpdateKeyFrame:selectSlot forTime:time commit:commit];
    }else{
        [self.actionService commitNLE:commit];
    }
}

- (void)deletCurMaskEffectValueNeedCommit:(BOOL)commit
{
    [self.vcContext.playerService pause];
    [self deletCurNLEMaskEffectValueNeedCommit:commit forSlot:[self.vcContext.mediaContext currentBlendVideoSlot]];
}

- (void)deletCurNLEMaskEffectValueNeedCommit:(BOOL)commit forSlot:(NLETrackSlot_OC *)selectSlot
{
    if (!selectSlot) return;
    NSMutableArray<NLEMask_OC*>* masks = [selectSlot getMask];
    for (NLEMask_OC *mask in masks) {
        //        NLESegmentMask_OC *segMask = mask.segmentMask;
        [selectSlot removeMask:mask];
    }
    
    [self.actionService commitNLE:commit];
}

- (NSDictionary *)currentMaskInfo
{
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    NLETrackSlot_OC *selectSlot = [self.vcContext.mediaContext currentBlendVideoSlot];

    if (selectSlot) {
        NSArray<NLEMask_OC *> *array= [selectSlot getMask];
        for (NLEMask_OC *mask in array) {
            NLEResourceNode_OC *resMask = mask.segmentMask.effectSDKMask;
            CGFloat duration = mask.segmentMask.aspectRatio * 100;
            [dic setObject:resMask.resourceId forKey:@"identifier"];
            [dic setObject:@(duration) forKey:resMask.resourceId];
            return dic;
        }
    }
    return dic;
}

- (void)refreshMaskForKeyFrameIfNeed:(NLETrackSlot_OC*)slot {

    if (!slot || [slot getMask].count == 0) {
        return;
    }
    NLEAllKeyFrameInfo *keyFrameInfo = [self.nle allKeyFrameInfoAtTime:self.vcContext.mediaContext.currentTime];
    [self nleDidChangedWithPTS:self.vcContext.mediaContext.currentTime keyFrameInfo:keyFrameInfo];
}

#pragma mark - KeyFrame

- (void)nleDidChangedWithPTS:(CMTime)time
                keyFrameInfo:(NLEAllKeyFrameInfo *)info
{
    NLETrackSlot_OC *slot = [self.vcContext.mediaContext currentMainVideoSlot];
    
    if (!slot) {
        return;
    }
    
    NLESegmentMask_OC* newMask = [self.nle maskSegmentFromKeyFrameInfo:info.featureKeyFrames forSlot:slot];
    if(!newMask){
        return;
    }else{
        ///如果有代理截获数据，则交给代理去决定是否刷新原来slot的mask数据
        if ([self.keyFrameDelegate respondsToSelector:@selector(maskKeyFrameDidChanged:)]) {
            [self.keyFrameDelegate maskKeyFrameDidChanged:newMask];
        }else{
            ///没代理截获数据，则刷新原来slot的mask数据
            NLEMask_OC *findMask = [slot getMask].firstObject;
            NLESegmentMask_OC *maskSegment = findMask.segmentMask;
            maskSegment.width = newMask.width;
            maskSegment.height = newMask.height;
            maskSegment.feather = newMask.feather;
            maskSegment.centerX = newMask.centerX;
            maskSegment.centerY = newMask.centerY;
            maskSegment.roundCorner = newMask.roundCorner;
            maskSegment.rotation = newMask.rotation;
        }
    }


}

@end

//
//   DVEKeyFrameEditor.m
//   NLEEditor
//
//   Created  by ByteDance on 2021/8/18.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//
    

#import "DVEKeyFrameEditor.h"
#import "DVEVCContext.h"
#import <NLEPlatform/NLETrackSlot+iOS.h>

@interface DVEKeyFrameEditor ()

@property (nonatomic, weak) id<DVECoreActionServiceProtocol> actionService;

@end

@implementation DVEKeyFrameEditor

@synthesize vcContext = _vcContext;

DVEAutoInject(self.vcContext.serviceProvider, actionService, DVECoreActionServiceProtocol)


- (instancetype)initWithContext:(DVEVCContext *)context
{
    if(self = [super init]) {
        self.vcContext = context;
    }
    return self;
}

-(NSString*)addOrUpdateKeyFrame:(NLETrackSlot_OC*)slot forTime:(CMTime)time commit:(BOOL)commit
{
    NLESegment_OC* seg = slot.segment;
    CGFloat scale = 1.0f;
    if([seg isKindOfClass:[NLESegmentVideo_OC class]] || [seg isKindOfClass:[NLESegmentAudio_OC class]]){
        scale = ((NLESegmentAudio_OC*)seg).absSpeed;
        if(scale == 1.0f){
            scale = ((NLESegmentAudio_OC*)seg).avgCurveSpeed;
        }
    }
    
    BOOL update = NO;
    BOOL resChange = NO;
    CMTimeRange slotRange = CMTimeRangeMake(slot.startTime, slot.duration);
    if(CMTimeRangeContainsTime(slotRange, time)){
        CGFloat offset = CMTimeGetSeconds(CMTimeSubtract(time, slot.startTime)) * USEC_PER_SEC;///关键帧相对于Slot开始时间的相对时间
        CGFloat range = NLEKeyframeRange/(2 * self.vcContext.mediaContext.timeScale) * scale;
        NLETrackSlot_OC* newKeyframe = [self cloneKeyframeSlot:slot];//拷贝当前时间点的Slot快照数据
        
        NLETrackSlot_OC* syncKeyframe;
        NSArray* sortKeyframe = slot.getSortKeyframe;
        for(NSInteger i = 0;i<sortKeyframe.count ; i++){
            NLETrackSlot_OC* keyfram = sortKeyframe[i];
            CGFloat time = CMTimeGetSeconds(keyfram.startTime) * USEC_PER_SEC;
            
            if(offset >= (time - range) && offset <= (time + range)){
                [slot removeKeyframe:keyfram];
                newKeyframe.startTime = CMTimeMake(offset, USEC_PER_SEC);
                if(offset > time){//落在关键帧范围右侧
                    NLETrackSlot_OC* nextKeyframe = i < sortKeyframe.count - 1 ? sortKeyframe[i + 1] : nil;
                    newKeyframe = [self updateKeyframe:keyfram newKeyframe:newKeyframe nextKeyframe:nextKeyframe];
                }else if(offset < time){//落在关键帧范围左侧
                    NLETrackSlot_OC* nextKeyframe = i > 0 ? sortKeyframe[i - 1] : nil;
                    newKeyframe = [self updateKeyframe:keyfram newKeyframe:newKeyframe nextKeyframe:nextKeyframe];
                }else{
//                    NSLog(@"replace keyframe");
                }
                offset = time;//保持时间点不变，但是clone最新当前slot的keyframe数据
                update = YES;
            }else{
                ///某些特效资源发生改变，需要把涉及到的关键帧特效资源做替换
                syncKeyframe = [self syncEffectResource:slot fromKeyframe:keyfram];
                if(syncKeyframe != keyfram){
                    [slot removeKeyframe:keyfram];
                    [slot addKeyframe:syncKeyframe];
                    resChange = YES;
                }
            }
        }

        if (update || !resChange) {
            newKeyframe.startTime = CMTimeMake(offset, USEC_PER_SEC);
            [slot addKeyframe:newKeyframe];
        }
        [self.actionService commitNLE:commit message:DVEEditorDoneEventAddKeyframe];
        return newKeyframe.name;

    }
    
    return nil;
}



/// 计算时间点关键帧参数
/// @param targetKeyframe 目标关键帧 t1
/// @param newKeyfram 偏移关键帧 t2
/// @param nextKeyframe 参考关键帧 t3
-(NLETrackSlot_OC*)updateKeyframe:(NLETrackSlot_OC*)targetKeyframe newKeyframe:(NLETrackSlot_OC*)newKeyframe nextKeyframe:(NLETrackSlot_OC*)nextKeyframe
{
    if (nextKeyframe == nil) {
        return newKeyframe;
    }
    
    CGFloat percent = fabs(CMTimeGetSeconds(CMTimeSubtract(newKeyframe.startTime, targetKeyframe.startTime))/CMTimeGetSeconds(CMTimeSubtract(nextKeyframe.startTime, newKeyframe.startTime)));
    targetKeyframe.rotation = newKeyframe.rotation - (nextKeyframe.rotation - newKeyframe.rotation) * percent;
    targetKeyframe.scale = newKeyframe.scale - (nextKeyframe.scale - newKeyframe.scale) * percent;
    targetKeyframe.transformX = newKeyframe.transformX - (nextKeyframe.transformX - newKeyframe.transformX) * percent;
    targetKeyframe.transformY = newKeyframe.transformY - (nextKeyframe.transformY - newKeyframe.transformY) * percent;
    targetKeyframe.transformZ = newKeyframe.transformZ - (nextKeyframe.transformZ - newKeyframe.transformZ) * percent;

    if (targetKeyframe.getMask.count > 0 && newKeyframe.getMask.count > 0 && nextKeyframe.getMask.count > 0) {
        NLESegmentMask_OC* targetMask = targetKeyframe.getMask.firstObject.segmentMask;
        NLESegmentMask_OC* newMask = newKeyframe.getMask.firstObject.segmentMask;
        NLESegmentMask_OC* nextMask = nextKeyframe.getMask.firstObject.segmentMask;
        targetMask.aspectRatio = newMask.aspectRatio - (nextMask.aspectRatio - newMask.aspectRatio) * percent;
        targetMask.rotation = newMask.rotation - (nextMask.rotation - newMask.rotation) * percent;
        targetMask.width = newMask.width - (nextMask.width - newMask.width) * percent;
        targetMask.height = newMask.height - (nextMask.height - newMask.height) * percent;
        targetMask.centerX = newMask.centerX - (nextMask.centerX - newMask.centerX) * percent;
        targetMask.centerY = newMask.centerY - (nextMask.centerY - newMask.centerY) * percent;
        targetMask.feather = newMask.feather - (nextMask.feather - newMask.feather) * percent;
        targetMask.roundCorner = newMask.roundCorner - (nextMask.roundCorner - newMask.roundCorner) * percent;
    }else {
        if(newKeyframe.getMask.count > 0){
            if(targetKeyframe.getMask.count == 0){////当目标关键帧没有蒙版数据，就以当前slot快照关键帧蒙版数据为准
                [targetKeyframe addMask:newKeyframe.getMask.firstObject];
            }else if(nextKeyframe.getMask.count == 0){////当参考关键帧没有蒙版数据，目标关键帧有蒙版数据，也以当前slot快照关键帧蒙版数据为准
                [targetKeyframe clearMask];
                [targetKeyframe addMask:newKeyframe.getMask.firstObject];
            }
        }
    }
    
    NSMutableArray<NLEFilter_OC*>* targetFilters = targetKeyframe.getFilter;
    NSMutableArray<NLEFilter_OC*>* newFilters = newKeyframe.getFilter;
    NSMutableArray<NLEFilter_OC*>* nextFilters = nextKeyframe.getFilter;
    for (NLEFilter_OC* newFilter in newFilters) {
        NLEFilter_OC* targetFilter = nil;
        NLEFilter_OC* nextFilter = nil;
        for(NLEFilter_OC* f in targetFilters){
            if([f.segmentFilter.getResNode.resourceId isEqualToString:newFilter.segmentFilter.getResNode.resourceId]){
                targetFilter = f;
                break;
            }
        }
        [targetFilters removeObject:targetFilter];

        
        for (NLEFilter_OC* f in nextFilters) {
            if([f.segmentFilter.getResNode.resourceId isEqualToString:newFilter.segmentFilter.getResNode.resourceId]){
                nextFilter = f;
                break;
            }
        }
        [nextFilters removeObject:nextFilter];

        if(targetFilter != nil && nextFilter != nil){
            targetFilter.segmentFilter.intensity = newFilter.segmentFilter.intensity - (nextFilter.segmentFilter.intensity - newFilter.segmentFilter.intensity) * percent;
        }else if(targetFilter == nil){///新的keyframe存在filter，目标targetFilter不存在就插入
            [targetKeyframe addFilter:newFilter];
        }
    }
    ///新的keyframe不存在，但是存在于targetFilter的filter就移除掉
    for(NLEFilter_OC* f in targetFilters){
        [targetKeyframe removeFilter:f];
    }

    NLESegment_OC* seg = newKeyframe.segment;
    if([seg isKindOfClass:[NLESegmentAudio_OC class]] || [seg isKindOfClass:[NLESegmentVideo_OC class]]){
        NLESegmentAudio_OC* targetSegment = (NLESegmentAudio_OC*)targetKeyframe.segment;
        NLESegmentAudio_OC* newSegment = (NLESegmentAudio_OC*)newKeyframe.segment;
        NLESegmentAudio_OC* nextSegment = (NLESegmentAudio_OC*)nextKeyframe.segment;
        targetSegment.volume = newSegment.volume - (nextSegment.volume - newSegment.volume) * percent;
    }
    
    return targetKeyframe;
    
}

///替换特效资源
-(NLETrackSlot_OC*)syncEffectResource:(NLETrackSlot_OC*)slot fromKeyframe:(NLETrackSlot_OC*)keyframe
{
    BOOL change = NO;
    ///处理蒙版
    NLETrackSlot_OC* targetKeyframe = keyframe;
    NLEMask_OC* slotMask = slot.getMask.firstObject;
    NLEMask_OC* keyFrameMask = keyframe.getMask.firstObject;
    if(slotMask == nil){

    }else{
        if(keyFrameMask != nil){  //如果关键帧记录的蒙版资源与当前slot的蒙版资源不同，则更新关键帧记录的蒙版资源
            if(![slotMask.segmentMask.getResource.resourceId isEqualToString: keyFrameMask.segmentMask.getResource.resourceId]){
                [keyFrameMask.segmentMask setEffectSDKMask:slotMask.segmentMask.getResource];
                [keyFrameMask.segmentMask setMaskType:slotMask.segmentMask.maskType];
                change = YES;
            }
        } else {  //如果当前slot有蒙版资源，关键帧没有记录蒙版资源，则给关键帧添加蒙版资源
            NLEMask_OC* newMask = [slotMask deepClone:YES];
            [keyframe addMask:newMask];
            change = YES;
        }
    }
    
    
    ///滤镜
    
    
    
    ///调节
    
    
    
    ///more
    if(change){
        targetKeyframe = [keyframe deepClone:YES];
    }
    return targetKeyframe;
}

-(NLETrackSlot_OC*)cloneKeyframeSlot:(NLETrackSlot_OC*)slot
{
    NLETrackSlot_OC* keyframe = [slot createKeyframe];
    return keyframe;
}

-(BOOL)removeKeyframe:(NLETrackSlot_OC*)slot forTime:(CMTime)time
{
    NLESegment_OC* seg = slot.segment;
    CGFloat scale = 1.0f;
    if([seg isKindOfClass:[NLESegmentVideo_OC class]] || [seg isKindOfClass:[NLESegmentAudio_OC class]]){
        scale = ((NLESegmentAudio_OC*)seg).absSpeed;
        if(scale == 1.0f){
            scale = ((NLESegmentAudio_OC*)seg).avgCurveSpeed;
        }
    }
    
    if(CMTimeCompare(slot.startTime, time) <= 0){
        CGFloat offset = (CMTimeGetSeconds(time) - CMTimeGetSeconds(slot.startTime)) * USEC_PER_SEC;
        CGFloat range = NLEKeyframeRange/(2 * self.vcContext.mediaContext.timeScale) * scale;
        for(NLETrackSlot_OC* keyfram in slot.getKeyframe){
            CGFloat time = CMTimeGetSeconds(keyfram.startTime) * USEC_PER_SEC;
            if(offset >= (time - range) && offset <= (time + range)){
                [slot removeKeyframe:keyfram];
                [self.actionService commitNLE:YES message:DVEEditorDoneEventRemoveKeyframe];
                return YES;
            }
        }
    }
    return NO;
}

-(BOOL)hasKeyframe:(NLETrackSlot_OC*)slot
{
    return slot.getKeyframe.count > 0;
}

-(BOOL)hasKeyframe:(NLETrackSlot_OC*)slot forTime:(CMTime)time
{
    return [self keyframeInSlot:slot forTime:time] != nil;
}

-(NLETrackSlot_OC*)keyframeInSlot:(NLETrackSlot_OC*)slot forTime:(CMTime)time
{
    NLESegment_OC* seg = slot.segment;
    CGFloat scale = 1.0f;
    if([seg isKindOfClass:[NLESegmentVideo_OC class]] || [seg isKindOfClass:[NLESegmentAudio_OC class]]){
        scale = ((NLESegmentAudio_OC*)seg).absSpeed;
        if(scale == 1.0f){
            scale = ((NLESegmentAudio_OC*)seg).avgCurveSpeed;
        }
    }
    
    if(CMTimeCompare(slot.startTime, time) <= 0){
        CGFloat offset = (CMTimeGetSeconds(time) - CMTimeGetSeconds(slot.startTime)) * USEC_PER_SEC;
        CGFloat range = NLEKeyframeRange/(2 * self.vcContext.mediaContext.timeScale) * scale;
        for(NLETrackSlot_OC* keyfram in slot.getKeyframe){
            CGFloat time = CMTimeGetSeconds(keyfram.startTime) * USEC_PER_SEC;
            if(offset >= (time - range) && offset <= (time + range)){
                return keyfram;
            }
        }
    }
    
    return nil;
}

@end

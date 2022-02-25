//
//  DVEKeyFrameEditorWrapper.m
//  NLEEditor
//
//  Created by bytedance on 2021/8/23.
//

#import "DVEKeyFrameEditorWrapper.h"
#import "DVEKeyFrameEditor.h"
#import "DVELoggerImpl.h"

@interface DVEKeyFrameEditorWrapper ()

@property (nonatomic, strong) id<DVECoreKeyFrameProtocol> keyFrameEditor;

@end

@implementation DVEKeyFrameEditorWrapper

@synthesize vcContext = _vcContext;

- (instancetype)initWithContext:(DVEVCContext *)context
{
    if (self = [super init]) {
        _vcContext = context;
        _keyFrameEditor = [[DVEKeyFrameEditor alloc] initWithContext:context];
    }
    return self;
}

#pragma mark - DVECoreKeyFrameProtocol

-(NSString*)addOrUpdateKeyFrame:(NLETrackSlot_OC*)slot forTime:(CMTime)time commit:(BOOL)commit
{
    DVELogReport(@"EditorCoreFunctionCalled");
    return [self.keyFrameEditor addOrUpdateKeyFrame:slot forTime:time commit:commit];
}

-(NLETrackSlot_OC*)cloneKeyframeSlot:(NLETrackSlot_OC*)slot
{
    DVELogReport(@"EditorCoreFunctionCalled");
    return [self.keyFrameEditor cloneKeyframeSlot:slot];
}

-(BOOL)removeKeyframe:(NLETrackSlot_OC*)slot forTime:(CMTime)time
{
    DVELogReport(@"EditorCoreFunctionCalled");
    return [self.keyFrameEditor removeKeyframe:slot forTime:time];
}

-(BOOL)hasKeyframe:(NLETrackSlot_OC*)slot
{
    DVELogReport(@"EditorCoreFunctionCalled");
    return [self.keyFrameEditor hasKeyframe:slot];
}

-(BOOL)hasKeyframe:(NLETrackSlot_OC*)slot forTime:(CMTime)time
{
    DVELogReport(@"EditorCoreFunctionCalled");
    return [self.keyFrameEditor hasKeyframe:slot forTime:time];
}

- (NLETrackSlot_OC *)keyframeInSlot:(NLETrackSlot_OC *)slot forTime:(CMTime)time
{
    DVELogReport(@"EditorCoreFunctionCalled");
    return [self.keyFrameEditor keyframeInSlot:slot forTime:time];
}

@end

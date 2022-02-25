//
//   DVEActionService.m
//   NLEEditor
//
//   Created  by bytedance on 2021/4/25.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//
    

#import "DVEActionService.h"
#import "DVEVCContext.h"
#import "DVECustomerHUD.h"
#import "DVELoggerImpl.h"

@interface DVEActionService()

@property (nonatomic, strong) NSHashTable *undoRedoListeners;
@property (nonatomic, weak) id<DVENLEEditorProtocol> nleEditor;

@end

@implementation DVEActionService

DVEAutoInject(self.vcContext.serviceProvider, nleEditor, DVENLEEditorProtocol)

@synthesize vcContext;
@synthesize canRedo;
@synthesize canUndo;
@synthesize isNeedHideUnReDo;

- (instancetype)initWithContext:(DVEVCContext *)context
{
    if (self = [super init]) {
        self.vcContext = context;
    }
    return self;
}

- (NSHashTable *)undoRedoListeners
{
    if (!_undoRedoListeners) {
        _undoRedoListeners = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
    }
    
    return _undoRedoListeners;
}

- (void)refreshUndoRedo
{
    self.canRedo = [self.nleEditor canRedo];
    self.canUndo = [self.nleEditor canUndo];
}

- (void)excuteUndo
{
    if ([self.nleEditor canUndo]) {
        [self notifyUndoRedoWillClikeByUser];
        [self.nleEditor undo];
        [self notifyUndoRedoClikedByUser];
        [self.vcContext.mediaContext seekToCurrentTime];
    }
    [self refreshUndoRedo];
}

- (void)excuteRedo
{
    if ([self.nleEditor canRedo]) {
        [self notifyUndoRedoWillClikeByUser];
        [self.nleEditor redo];
        [self notifyUndoRedoClikedByUser];
        [self.vcContext.mediaContext seekToCurrentTime];
    }
    [self refreshUndoRedo];
}

- (void)notifyUndoRedoClikedByUser
{
    NSArray *arr = [self.undoRedoListeners allObjects];
    for (id<DVECoreActionNotifyProtocol> obj in arr) {
        if ([obj respondsToSelector:@selector(undoRedoClikedByUser)]) {
            [obj undoRedoClikedByUser];
        }
    }
}

- (void)notifyUndoRedoWillClikeByUser
{
    NSArray *arr = [self.undoRedoListeners allObjects];
    for (id<DVECoreActionNotifyProtocol> obj in arr) {
        if ([obj respondsToSelector:@selector(undoRedoWillClikeByUser)]) {
            [obj undoRedoWillClikeByUser];
        }
    }
}

- (void)addUndoRedoListener:(id<DVECoreActionNotifyProtocol>)listener
{
    for (id obj in self.undoRedoListeners) {
        if ([obj isEqual:listener]) {
            return;
        }
    }
    [self.undoRedoListeners addObject:listener];
}

- (void)removeUndoRedoListener:(id<DVECoreActionNotifyProtocol>)listener
{
    [self.undoRedoListeners removeObject:listener];
}

- (void)clearUndoRedoListener
{
    [self.undoRedoListeners removeAllObjects];
}

- (void)commitNLE:(BOOL)commit message:(NSString*)message
{
    [DVEAutoInline(self.vcContext.serviceProvider, DVECoreCanvasProtocol) saveCanvasSize];
    [self.nleEditor commit]; // git add

    if (commit) {
        BOOL isDone = [self.nleEditor done:message]; // git commit
        if (isDone) {
            DVELogInfo(@"undoredoflow------done");
        } else {
            DVELogInfo(@"undoredoflow------no done");
        }
        [self refreshUndoRedo];
    }

//    [self.vcContext.mediaContext seekToCurrentTime];
}

- (void)commitNLE:(BOOL)commit
{
    [self commitNLE:commit message:nil];
}

- (void)commitNLEWithoutNotify:(BOOL)commit
{
    [DVEAutoInline(self.vcContext.serviceProvider, DVECoreCanvasProtocol) saveCanvasSize];
    [self.nleEditor commit]; // git add

    if (commit) {
        BOOL isDone = [self.nleEditor done]; // git commit
        if (isDone) {
            DVELogInfo(@"undoredoflow------done");
        } else {
            DVELogInfo(@"undoredoflow------no done");
        }
        [self refreshUndoRedo];
    }

    CMTime time = CMTimeMake(self.vcContext.playerService.currentPlayerTime * USEC_PER_SEC, USEC_PER_SEC);
    [self.vcContext.playerService seekToTime:time isSmooth:YES];
}

@end

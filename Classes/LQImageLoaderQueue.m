
#import "LQImageLoaderQueue.h"


@interface LQImageLoaderQueue ()

@property (nonatomic, readonly) NSInteger maxCount;
@property (nonatomic, readonly, nonnull) NSMutableArray *running;
@property (nonatomic, readonly, nonnull) NSMutableArray *postponed;

@end


@implementation LQImageLoaderQueue

- (nonnull instancetype)initWithMaxConcurrentTaskCount:(NSInteger)count type:(LQImageLoaderQueueType)type {
    self = [super init];
    _maxCount = count;
    _type = type;
    _running = [NSMutableArray array];
    _postponed = [NSMutableArray array];
    return self;
}

- (BOOL)isEmpty {
    return (self.running.count == 0 && self.postponed.count == 0);
}

- (void)addTask:(nonnull NSURLSessionTask *)task {
    [self _addTask:task];
}

- (void)removeTask:(nonnull NSURLSessionTask *)task {
    [self.running removeObject:task];
    [self.postponed removeObject:task];
    [self addNextPostponedTask];
    [self.delegate imageLoaderQueue:self didRemoveTask:task];
}

- (void)unleashPostponedTasks {
    while ([self addNextPostponedTask]) {}
}

- (BOOL)isStartableTask:(nonnull NSURLSessionTask *)task {
    if (task.state != NSURLSessionTaskStateSuspended) {
        return NO;
    }
    BOOL canStart = (self.running.count < self.maxCount);
    if (canStart && self.delegate) {
        canStart = [self.delegate imageLoaderQueue:self canStartTask:task];
    }
    return canStart;
}

- (BOOL)_addTask:(nonnull NSURLSessionTask *)task {
    BOOL postponed = [self.postponed containsObject:task];
    if ([self isStartableTask:task]) {
        if (postponed) {
            [self.postponed removeObject:task];
        }
        [self.running addObject:task];
        [task resume];
        return YES;
    }
    if (!postponed) {
        [self.postponed addObject:task];
    }
    return NO;
}

- (BOOL)addNextPostponedTask {
    [self cleanPostponed];
    NSURLSessionTask *next;
    switch (self.type) {
        case LQImageLoaderQueueTypeLIFO:
            next = self.postponed.lastObject;
            break;
        case LQImageLoaderQueueTypeFIFO:
            next = self.postponed.firstObject;
            break;
    }
    if (next) {
        return [self _addTask:next];
    }
    return NO;
}

- (void)cleanPostponed {
    NSArray *postponed = [self.postponed copy];
    for (NSURLSessionTask *task in postponed) {
        if (task.state != NSURLSessionTaskStateSuspended) {
            [self.postponed removeObject:task];
        }
    }
}

@end

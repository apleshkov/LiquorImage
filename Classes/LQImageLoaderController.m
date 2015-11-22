
#import "LQImageLoaderController.h"
#import "LQImageLoaderTask+LQProtected.h"
#import "LQImageLoaderQueue.h"
#import "LQExtensions.h"
#import "LQImageLoaderAuthChallenging.h"
#import "LQImageHTTPCaching.h"


#pragma mark - _Task


@interface _LQImageLoaderControllerTask : NSObject

@property (nonatomic, copy) NSString *key;
@property (nonatomic, weak) NSURLSessionTask *URLTask;
@property (nonatomic) long long expectedContentLength;
@property (nonatomic, readonly) BOOL hasSenders;

- (void)addSender:(LQImageLoaderTask *)sender;
- (BOOL)removeSender:(LQImageLoaderTask *)sender;
- (NSSet<LQImageLoaderTask *> *)copyOfSenders;
- (void)appendData:(NSData *)data;
- (void)completeWithError:(NSError *)error;

@end


#pragma mark - Controller


@interface LQImageLoaderController ()
<
NSURLSessionDataDelegate,
LQImageLoaderQueueDelegate
>

@property (nonatomic, readonly, nonnull) NSRecursiveLock *recursiveLock;
@property (nonatomic, readonly) LQImageLoaderQueue *stack;
@property (nonatomic, readonly) NSMutableDictionary *internalTasks;
@property (nonatomic, readonly) NSHashTable *cancelledImageTasks;
@property (nonatomic, readonly) LQImageLoaderQueue *preloadingQueue;

@end


#define _rLock()    [self.recursiveLock lock]
#define _rUnlock()  [self.recursiveLock unlock]


@implementation LQImageLoaderController

- (instancetype)initWithMaxConcurrentTaskCount:(NSUInteger)count {
    NSParameterAssert(count > 0);
    self = [super init];
    _recursiveLock = [NSRecursiveLock new];
    _stack = ({
        LQImageLoaderQueue *queue = [[LQImageLoaderQueue alloc] initWithMaxConcurrentTaskCount:count type:LQImageLoaderQueueTypeLIFO];
        queue.delegate = self;
        queue;
    });
    _internalTasks = [NSMutableDictionary new];
    _cancelledImageTasks = [NSHashTable weakObjectsHashTable];
    _preloadingQueue = ({
        LQImageLoaderQueue *queue = [[LQImageLoaderQueue alloc] initWithMaxConcurrentTaskCount:count type:LQImageLoaderQueueTypeFIFO];
        queue.delegate = self;
        queue;
    });
    return self;
}

- (NSString *)internalTaskKeyForImageTask:(LQImageLoaderTask *)imageTask {
    return imageTask.URL.absoluteString;
}

static char _taskAK;

- (void)startImageTask:(LQImageLoaderTask *)imageTask {
    NSParameterAssert(imageTask);
    BOOL preloading = imageTask.preloading;
    NSURLSession *session = [self.dataSource imageLoaderControllerURLSession:self];
    NSParameterAssert(session);
    _rLock();
    if ([self.cancelledImageTasks containsObject:imageTask]) {
        [self.cancelledImageTasks removeObject:imageTask];
    } else {
        NSString *key = [self internalTaskKeyForImageTask:imageTask];
        _LQImageLoaderControllerTask *internalTask = self.internalTasks[key];
        if (internalTask) {
            [internalTask addSender:imageTask];
        } else {
            NSURLSessionTask *URLTask = [session dataTaskWithURL:imageTask.URL];
            internalTask = [_LQImageLoaderControllerTask new];
            internalTask.key = key;
            internalTask.URLTask = URLTask;
            [internalTask addSender:imageTask];
            self.internalTasks[key] = internalTask;
            objc_setAssociatedObject(URLTask, &_taskAK, internalTask, OBJC_ASSOCIATION_RETAIN);
            if (preloading) {
                [self.preloadingQueue addTask:URLTask];
            } else {
                [self.stack addTask:URLTask];
            }
        }
    }
    _rUnlock();
}

- (void)cancelImageTask:(nonnull LQImageLoaderTask *)imageTask {
    NSURLSessionTask *URLTask;
    _rLock();
    [self.cancelledImageTasks addObject:imageTask];
    NSString *key = [self internalTaskKeyForImageTask:imageTask];
    _LQImageLoaderControllerTask *internalTask = self.internalTasks[key];
    if (internalTask && [internalTask removeSender:imageTask]) {
        URLTask = internalTask.URLTask;
        if (URLTask) {
            objc_setAssociatedObject(URLTask, &_taskAK, nil, OBJC_ASSOCIATION_RETAIN);
            [URLTask cancel];
            [self.preloadingQueue removeTask:internalTask.URLTask];
            [self.stack removeTask:URLTask];
        }
        [self.internalTasks removeObjectForKey:key];
    }
    _rUnlock();
    [URLTask cancel];
}

- (BOOL)isLoadingImageTask:(nonnull LQImageLoaderTask *)imageTask {
    BOOL isLoading = NO;
    _rLock();
    NSString *key = [self internalTaskKeyForImageTask:imageTask];
    _LQImageLoaderControllerTask *internalTask = self.internalTasks[key];
    isLoading = internalTask.hasSenders;
    _rUnlock();
    return isLoading;
}

#pragma mark NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    _rLock();
    _LQImageLoaderControllerTask *internalTask = objc_getAssociatedObject(task, &_taskAK);
    if (internalTask) {
        [internalTask completeWithError:error];
        [self.preloadingQueue removeTask:internalTask.URLTask];
        [self.stack removeTask:internalTask.URLTask];
        [self.internalTasks removeObjectForKey:internalTask.key];
    }
    _rUnlock();
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    id<LQImageLoaderAuthChallenging> authChallenger = [self.dataSource imageLoaderControllerAuthChallenger:self];
    if (authChallenger) {
        [authChallenger URLSession:session task:task didReceiveChallenge:challenge completionHandler:completionHandler];
    } else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

#pragma mark NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    long long expected = response.expectedContentLength;
    if (expected == NSURLResponseUnknownLength) {
        expected = 0;
    }
    _rLock();
    _LQImageLoaderControllerTask *internalTask = objc_getAssociatedObject(dataTask, &_taskAK);
    internalTask.expectedContentLength = expected;
    _rUnlock();
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    _rLock();
    _LQImageLoaderControllerTask *internalTask = objc_getAssociatedObject(dataTask, &_taskAK);
    [internalTask appendData:data];
    _rUnlock();
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse *))completionHandler {
    id<LQImageHTTPCaching> cache = [self.dataSource imageLoaderControllerHTTPCache:self];
    if (cache) {
        [cache URLSession:session dataTask:dataTask willCacheResponse:proposedResponse completionHandler:completionHandler];
    } else {
        completionHandler(proposedResponse);
    }
}

#pragma mark LQImageLoaderQueueDelegate

- (BOOL)imageLoaderQueue:(nonnull LQImageLoaderQueue *)queue canStartTask:(nonnull NSURLSessionTask *)task {
    if (queue == self.preloadingQueue) {
        return self.stack.isEmpty;
    }
    return YES;
}

- (void)imageLoaderQueue:(nonnull LQImageLoaderQueue *)queue didRemoveTask:(nonnull NSURLSessionTask *)task {
    if (queue == self.stack) {
        if (self.stack.isEmpty) {
            [self.preloadingQueue unleashPostponedTasks];
        }
    }
}

@end


#pragma mark - _TaskImpl


@interface _LQImageLoaderControllerTask ()

@property (nonatomic, readonly) NSMutableSet *senders;
@property (nonatomic, readonly) NSMutableData *data;

@end


@implementation _LQImageLoaderControllerTask

- (id)init {
    if (self = [super init]) {
        _senders = [NSMutableSet set];
        _data = [NSMutableData data];
    }
    return self;
}

- (BOOL)hasSenders {
    return (self.senders.count > 0);
}

- (void)addSender:(LQImageLoaderTask *)sender {
    [self.senders addObject:sender];
}

- (BOOL)removeSender:(LQImageLoaderTask *)sender {
    [self.senders removeObject:sender];
    return self.senders.count == 0;
}

- (NSSet<LQImageLoaderTask *> *)copyOfSenders {
    return [self.senders copy];
}

- (void)appendData:(NSData *)data {
    [self.data appendData:data];
    
    long long expected = self.expectedContentLength;
    if (expected > 0) {
        long long recieved = self.data.length;
        for (LQImageLoaderTask *sender in self.senders) {
            [sender updateProgressWithRecievedContentLength:recieved expected:expected];
        }
    }
}

- (void)completeWithError:(NSError *)error {
    if (LQURLErrorIsCancelled(error)) {
        return;
    }
    NSData *data = [self.data copy];
    for (LQImageLoaderTask *sender in self.senders) {
        [sender completeWithData:data error:error];
    }
}

@end

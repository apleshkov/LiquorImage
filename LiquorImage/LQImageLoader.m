
#import "LQImageLoader.h"
#import "LQImageLoaderController.h"
#import "LQImageLoaderTask+LQProtected.h"
#import "LQExtensions.h"


@interface LQImageLoader ()
<
LQImageLoaderTaskClient,
LQImageLoaderControllerDataSource
>

@property (nonatomic, readonly, nonnull) LQImageLoaderController *controller;
@property (nonatomic, readonly, nonnull) NSURLSession *session;

@end


@implementation LQImageLoader

- (void)dealloc {
    [_session invalidateAndCancel];
}

- (nonnull instancetype)initWithMaxConcurrentTaskCount:(NSUInteger)count sessionConfiguration:(nonnull NSURLSessionConfiguration *)sessionConfiguration {
    NSParameterAssert(sessionConfiguration);
    if (self = [super init]) {
        _HTTPCache = [LQImageHTTPCache new];
        _controller = ({
            LQImageLoaderController *controller = [[LQImageLoaderController alloc] initWithMaxConcurrentTaskCount:count];
            controller.dataSource = self;
            controller;
        });
        _session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self.controller delegateQueue:({
            NSOperationQueue *queue = [NSOperationQueue new];
            queue;
        })];
    }
    return self;
}

- (nonnull instancetype)initWithMaxConcurrentTaskCount:(NSUInteger)count {
    return [self initWithMaxConcurrentTaskCount:count sessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
}

- (void)loadImageWithURL:(NSURL *)url completion:(void (^)(UIImage * _Nullable, NSError * _Nullable))completion {
    NSParameterAssert(url);
    NSParameterAssert(completion);
    LQImageLoaderTask *task = [[LQImageLoaderTask alloc] initWithURL:url];
    [task setInternalCompletionHandler:^(UIImage * _Nullable image, NSError * _Nullable error) {
        LQQueueMainAsync(^{
            completion(image, error);
        });
    }];
    [self startTask:task];
}

- (void)startTask:(nonnull LQImageLoaderTask *)imageTask {
    NSParameterAssert(imageTask);
    imageTask.client = self;
    dispatch_async(LQ_QUEUE_GLOBAL_DEFAULT, ^{
        if ([imageTask tryRestoreFromCache]) {
            return;
        }
        [self.controller startImageTask:imageTask];
    });
}

#pragma mark LQImageLoaderControllerDataSource

- (NSURLSession *)imageLoaderControllerURLSession:(LQImageLoaderController *)controller {
    return self.session;
}

- (id<LQImageLoaderAuthChallenging>)imageLoaderControllerAuthChallenger:(LQImageLoaderController *)controller {
    return self.authChallenger;
}

- (id<LQImageHTTPCaching>)imageLoaderControllerHTTPCache:(LQImageLoaderController *)controller {
    return self.HTTPCache;
}

#pragma mark LQImageLoaderTaskClient

- (void)cancelImageLoaderTask:(LQImageLoaderTask *)imageTask {
    dispatch_async(LQ_QUEUE_GLOBAL_DEFAULT, ^{
        [self.controller cancelImageTask:imageTask];
    });
}

@end


#pragma mark - Preloading


@interface LQImageLoaderPreloadingContext ()

@property (nonatomic) NSUInteger totalCount;
@property (nonatomic) NSUInteger completedCount;
@property (nonatomic) NSUInteger preloadedCount;

@end


@implementation LQImageLoader (LQImagePreloading)

- (void)preloadImageWithURL:(NSURL *)url completion:(void (^)(BOOL))completion {
    NSParameterAssert(url);
    LQImageLoaderTask *task = [[LQImageLoaderTask alloc] initWithURL:url];
    task.preloading = YES;
    task.memoryCache = nil;
    if (completion) {
        [task setInternalCompletionHandler:^(UIImage * _Nullable image, NSError * _Nullable error) {
            BOOL preloaded = !!image;
            LQQueueMainAsync(^{
                completion(preloaded);
            });
        }];
    }
    [self startTask:task];
}

- (void)preloadImageURLs:(NSArray<NSURL *> *)urls withProgress:(void (^)(LQImageLoaderPreloadingContext * _Nonnull))progress completion:(void (^)(LQImageLoaderPreloadingContext * _Nonnull))completion {
    NSParameterAssert(urls);
    urls = [urls copy];
    if (urls.count == 0) {
        if (completion) {
            LQQueueMainAsync(^{
                completion([LQImageLoaderPreloadingContext new]);
            });
        }
        return;
    }
    if (!completion) {
        for (NSURL *entry in urls) {
            [self preloadImageWithURL:entry completion:nil];
        }
        return;
    }
    LQImageLoaderPreloadingContext *context = [LQImageLoaderPreloadingContext new];
    context.totalCount = urls.count;
    for (NSURL *entry in urls) {
        [self preloadImageWithURL:entry completion:^(BOOL preloaded) {
            context.completedCount++;
            if (preloaded) {
                context.preloadedCount++;
            }
            if (progress) {
                progress(context);
            }
            if (context.totalCount == context.completedCount) {
                completion(context);
            }
        }];
    }
}

@end


@implementation LQImageLoaderPreloadingContext
                         
- (BOOL)allPreloaded {
    return (self.preloadedCount == self.totalCount);
}
                         
@end


@implementation LQImageLoader (LQSharedImageLoader)

static OSSpinLock spinLock = OS_SPINLOCK_INIT;
static LQImageLoader *sharedLoader;

+ (instancetype)shared {
    OSSpinLockLock(&spinLock);
    if (!sharedLoader) {
        sharedLoader = [[LQImageLoader alloc] initWithMaxConcurrentTaskCount:LQImageLoaderDefaultMaxConcurrentTaskCount];
    }
    OSSpinLockUnlock(&spinLock);
    return sharedLoader;
}

+ (void)setShared:(LQImageLoader *)loader {
    NSParameterAssert(loader);
    OSSpinLockLock(&spinLock);
    sharedLoader = loader;
    OSSpinLockUnlock(&spinLock);
}

@end


#import "LQImageLoaderTask.h"
#import "LQImageLoaderTask+LQProtected.h"
#import "LQExtensions.h"
#import "LQImageBuilding.h"
#import "LQImageMemoryCache.h"
#import "LQDefaultImageBuilder.h"


@interface LQImageLoaderTask ()

@property (getter = isCancelled) BOOL cancelled;
@property (weak, nullable) id<LQImageLoaderTaskClient> client;
@property (nonatomic) float progressValue;
@property BOOL preloading;
@property (copy, nullable) LQImageLoaderTaskInternalCompletionHandler internalCompletionHandler;

@end


#define _lock()     OSSpinLockLock(&_spinLock)
#define _unlock()   OSSpinLockUnlock(&_spinLock)


@implementation LQImageLoaderTask {
    OSSpinLock _spinLock;
    NSString *_memoryCacheIdentifier;
    LQImageMemoryCache *_memoryCache;
    id<LQImageBuilding> _imageBuilder;
    NSArray<id<LQImageTransforming>> *_imageTransformers;
}

- (instancetype)initWithURL:(NSURL *)url {
    NSParameterAssert(url);
    self = [super init];
    _spinLock = OS_SPINLOCK_INIT;
    _URL = url;
    _memoryCache = [LQImageMemoryCache shared];
    return self;
}

- (NSString *)memoryCacheIdentifier {
    NSString *identifier;
    _lock();
    identifier = _memoryCacheIdentifier;
    _unlock();
    return identifier;
}

- (LQImageMemoryCache *)memoryCache {
    LQImageMemoryCache *cache;
    _lock();
    cache = _memoryCache;
    _unlock();
    return cache;
}

- (void)setMemoryCache:(LQImageMemoryCache *)memoryCache {
    _lock();
    _memoryCache = memoryCache;
    _unlock();
}

- (void)setImageBuilder:(id<LQImageBuilding>)builder withMemoryCacheIdentifier:(NSString *)identifier {
    NSParameterAssert(builder);
    NSParameterAssert(identifier.length > 0);
    _lock();
    NSAssert(_memoryCache, @"Set memory cache with %@ to use this method", NSStringFromSelector(@selector(setMemoryCache:)));
    _imageBuilder = builder;
    _memoryCacheIdentifier = [identifier copy];
    _unlock();
}

- (void)setImageBuilderIgnoringMemoryCache:(id<LQImageBuilding>)builder {
    NSParameterAssert(builder);
    _lock();
    _imageBuilder = builder;
    _memoryCache = nil;
    _memoryCacheIdentifier = nil;
    _unlock();
}

- (void)cancel {
    [self.client cancelImageLoaderTask:self];
}

- (void)completeWithImage:(nullable UIImage *)image error:(nullable NSError *)error {
    void (^internalHandler)(UIImage *, NSError *) = self.internalCompletionHandler;
    if (internalHandler) {
        internalHandler(image, error);
    }
    LQQueueMainAsync(^{
        [self.delegate imageLoaderTask:self didCompleteWithImage:image error:error];
    });
}

- (nullable NSString *)_cacheKey {
    NSString *identifier;
    if (_memoryCache) {
        identifier = (_memoryCacheIdentifier ?: LQImageLoaderTaskDefaultMemoryCacheIdentifier);
    }
    if (!identifier) {
        return nil;
    }
    return [NSString stringWithFormat:@"%@-%@", identifier, self.URL.absoluteString];
}

- (nullable UIImage *)cachedImage {
    UIImage *image;
    _lock();
    NSString *key = [self _cacheKey];
    if (key) {
        image = [_memoryCache imageForKey:key];
    }
    _unlock();
    return image;
}

- (void)cacheImage:(nullable UIImage *)image {
    _lock();
    NSString *key = [self _cacheKey];
    if (key) {
        [_memoryCache setImage:image forKey:key];
    }
    _unlock();
}

- (void)completeWithData:(nullable NSData *)data error:(nullable NSError *)error {
    if (error || data.length == 0) {
        [self completeWithImage:nil error:error];
        return;
    }
    dispatch_async(LQ_QUEUE_GLOBAL_DEFAULT, ^{
        @autoreleasepool {
            UIImage *image = [self cachedImage];
            if (image) {
                [self completeWithImage:image error:nil];
            } else {
                NSError *error;
                _lock();
                id<LQImageBuilding> imageBuilder = _imageBuilder;
                _unlock();
                if (!imageBuilder) {
                    imageBuilder = [LQDefaultImageBuilder shared];
                }
                if (imageBuilder) {
                    image = [imageBuilder imageFromData:data error:&error];
                }
                if (image) {
                    [self cacheImage:image];
                    [self completeWithImage:image error:nil];
                } else {
                    [self completeWithImage:nil error:error];
                }
            }
        }
    });
}

- (BOOL)tryRestoreFromCache {
    UIImage *image = [self cachedImage];
    if (image) {
        [self completeWithImage:image error:nil];
        return YES;
    }
    return NO;
}

- (void)updateProgressWithRecievedContentLength:(long long)recieved expected:(long long)expected {
    LQQueueMainAsync(^{
        self.progressValue = ((float)recieved / (float)expected);
        if ([self.delegate respondsToSelector:@selector(imageLoaderTask:didUpdateProgressWithRecievedContentLength:expected:)]) {
            [self.delegate imageLoaderTask:self didUpdateProgressWithRecievedContentLength:recieved expected:expected];
        }
    });
}

@end

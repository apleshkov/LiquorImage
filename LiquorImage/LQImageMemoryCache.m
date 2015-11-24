
#import "LQImageMemoryCache.h"


@interface LQImageMemoryCache ()
@property (nonatomic) NSCache *internalCache;
@end


@implementation LQImageMemoryCache

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (nonnull instancetype)init {
    return [self initWithLimitInMegabytes:0];
}

- (nonnull instancetype)initWithLimitInMegabytes:(NSUInteger)megabytes {
    self = [super init];
    _internalCache = ({
        NSCache *cache = [NSCache new];
        cache.totalCostLimit = megabytes * 1024 * 1024; // bytes
        cache;
    });
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMemoryWarningNotification:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    return self;
}

- (void)setImage:(nullable UIImage *)image forKey:(nonnull NSString *)key {
    NSParameterAssert(key);
    if (!image) {
        [self.internalCache removeObjectForKey:key];
        return;
    }
    if (self.internalCache.totalCostLimit > 0) {
        [self.internalCache setObject:image forKey:key cost:({
            NSUInteger cost = 0;
            if (image) {
                CGImageRef ref = image.CGImage;
                NSUInteger bpp = CGImageGetBitsPerPixel(ref);
                cost = (CGImageGetWidth(ref) * CGImageGetHeight(ref) * bpp) / 8; // bytes
            }
            cost;
        })];
    } else {
        [self.internalCache setObject:image forKey:key];
    }
}

- (nullable UIImage *)imageForKey:(nonnull NSString *)key {
    NSParameterAssert(key);
    return [self.internalCache objectForKey:key];
}

- (void)handleMemoryWarningNotification:(NSNotification *)notification {
    [self.internalCache removeAllObjects];
}

@end


#import <libkern/OSAtomic.h>


@implementation LQImageMemoryCache (LQSharedImageMemoryCache)

static OSSpinLock spinLock = OS_SPINLOCK_INIT;
static LQImageMemoryCache *sharedCache;

+ (instancetype)shared {
    OSSpinLockLock(&spinLock);
    if (!sharedCache) {
        sharedCache = [LQImageMemoryCache new];
    }
    OSSpinLockUnlock(&spinLock);
    return sharedCache;
}

+ (void)setShared:(LQImageMemoryCache *)cache {
    NSParameterAssert(cache);
    OSSpinLockLock(&spinLock);
    sharedCache = cache;
    OSSpinLockUnlock(&spinLock);
}

@end


#import "LQImageHTTPCache.h"
#import "LQExtensions.h"


@interface LQImageHTTPCache ()

@property (nonatomic, readonly, nonnull) NSMutableDictionary<NSURL *, NSNumber *> *maxAges;

@end


#define _sLock()    OSSpinLockLock(&_spinLock)
#define _sUnlock()  OSSpinLockUnlock(&_spinLock)


@implementation LQImageHTTPCache {
    OSSpinLock _spinLock;
}

- (instancetype)init {
    self = [super init];
    _spinLock = OS_SPINLOCK_INIT;
    _maxAges = [NSMutableDictionary dictionary];
    return self;
}

- (void)setURL:(NSURL *)url maxAgeInSeconds:(LQImageHTTPCacheMaxAge)secs {
    NSParameterAssert(url);
    _sLock();
    _maxAges[url] = @(secs);
    _sUnlock();
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse * _Nullable))completionHandler {
    NSHTTPURLResponse *httpResponse = LQSafeCast(NSHTTPURLResponse, proposedResponse.response);
    if (httpResponse) {
        NSURL *url = httpResponse.URL;
        if (url) {
            _sLock();
            NSNumber *number = self.maxAges[url];
            _sUnlock();
            if (number) {
                LQImageHTTPCacheMaxAge maxAge = number.unsignedLongValue;
                NSMutableDictionary *headers = [httpResponse.allHeaderFields mutableCopy];
                headers[@"Cache-Control"] = [NSString stringWithFormat:@"max-age=%lu", maxAge];
                NSString *httpVersion = (__bridge NSString *)kCFHTTPVersion1_1;
                httpResponse = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:httpResponse.statusCode HTTPVersion:httpVersion headerFields:headers];
                completionHandler([[NSCachedURLResponse alloc] initWithResponse:httpResponse data:proposedResponse.data userInfo:proposedResponse.userInfo storagePolicy:proposedResponse.storagePolicy]);
                return;
            }
        }
    }
    completionHandler(proposedResponse);
}

@end

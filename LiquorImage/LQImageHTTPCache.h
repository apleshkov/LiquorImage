
#import <Foundation/Foundation.h>
#import "LQImageHTTPCaching.h"


typedef unsigned long LQImageHTTPCacheMaxAge;


@interface LQImageHTTPCache : NSObject <LQImageHTTPCaching>

- (void)setURL:(nonnull NSURL *)url maxAgeInSeconds:(LQImageHTTPCacheMaxAge)secs;

@end

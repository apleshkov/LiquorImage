
@import Foundation;
@import UIKit;


@interface LQImageMemoryCache : NSObject

- (nonnull instancetype)init;
- (nonnull instancetype)initWithLimitInMegabytes:(NSUInteger)megabytes NS_DESIGNATED_INITIALIZER; // 0 - no limit

- (void)setImage:(nullable UIImage *)image forKey:(nonnull NSString *)key;

- (nullable UIImage *)imageForKey:(nonnull NSString *)key;

@end


@interface LQImageMemoryCache (LQSharedImageMemoryCache)

+ (nonnull instancetype)shared;

+ (void)setShared:(nonnull LQImageMemoryCache *)cache;

@end

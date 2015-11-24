
@import Foundation;
@import UIKit;
#import "LQMacros.h"


@protocol LQImageLoaderTaskDelegate;
@protocol LQImageBuilding;
@protocol LQImageTransforming;
@class LQImageMemoryCache;

/**
 Represents the task to download and optionally build an image
 
 The only way to start the task is calling @c LQImageLoader @c -startTask:
 
 @code
 LQImageLoaderTask *task = [[LQImageLoaderTask alloc] initWithURL:<url>];
 
 [[LQImageLoader shared] startTask:task];
 @endcode
 */
@interface LQImageLoaderTask : NSObject

@property (nonatomic, readonly, nonnull) NSURL *URL;
/**
 The delegate is the only way to get the result of image loading
 @note The task doesn't retain image and error.
 */
@property (weak, nullable) id<LQImageLoaderTaskDelegate> delegate;
/**
 There's a possibility to store downloaded (and optionally built & transformed) image into a memory cache.
 
 The task uses [LQImageMemoryCache shared] *BY DEFAULT*, but you can provide a different memory cache or *DISABLE* memory caching at all by setting the @c memoryCache property to @c nil.
 
 You should NOT retrieve images downloaded via image tasks from the memory cache by yourself. It happens automatically.
 
 @code
 // disable memory cache
 imageTask.memoryCache = nil;
 @endcode
 
 @see memoryCacheIdentifier
 @see -setImageBuilder:withMemoryCacheIdentifier:
 @see -setImageBuilderIgnoringMemoryCache:
 */
@property (nullable) LQImageMemoryCache *memoryCache;
/**
 The memory cache identifier is used to retrieve an image from the @c memoryCache (if it's not @c nil). It *IS NOT* the memory cache key itself (which can be provided to LQImageMemoryCache -imageForKey:), but a pair of the @c memoryCacheIdentifier and the @c url with which this image task was created.
 
 @note It's a programmatic error to use the same custom memory cache identifier for tasks with different image builders.
 
 @see url
 @see memoryCache
 @see -setImageBuilder:withMemoryCacheIdentifier:
 @see LQImageLoaderTaskDefaultMemoryCacheIdentifier
 */
@property (readonly, nullable) NSString *memoryCacheIdentifier;
/**
 Some additional info
 */
@property (nullable) id userInfo;
/**
 Contains the progress of downloading image (from 0.0 to 1.0)
 
 Read this value from the @c delegate's @c -imageLoaderTask:didUpdateProgressWithRecievedContentLength:expected:
 
 @see delegate
 */
@property (nonatomic, readonly) float progressValue;

LQ_UNAVAILABLE_NSOBJECT_INIT

/**
 Creates new task
 
 @note Try to create the @c url in the background (e.g. while parsing input data from a server) to avoid any parsing on task creating
 */
- (nonnull instancetype)initWithURL:(nonnull NSURL *)url NS_DESIGNATED_INITIALIZER;

/**
 @see memoryCache
 @see memoryCacheIdentifier
 @see LQDefaultImageBuilder
 @see LQBlockImageBuilder
 */
- (void)setImageBuilder:(nonnull id<LQImageBuilding>)builder withMemoryCacheIdentifier:(nonnull NSString *)identifier;

/**
 @see -setImageBuilder:withMemoryCacheIdentifier:
 */
- (void)setImageBuilderIgnoringMemoryCache:(nonnull id<LQImageBuilding>)builder;

/**
 Cancels image downloading
 */
- (void)cancel;

@end


@protocol LQImageLoaderTaskDelegate <NSObject>

/// Called on the main thread
- (void)imageLoaderTask:(nonnull LQImageLoaderTask *)task didCompleteWithImage:(nullable UIImage *)image error:(nullable NSError *)error;

@optional

/** 
 Called on the main thread
 
 @see progressValue
 */
- (void)imageLoaderTask:(nonnull LQImageLoaderTask *)task didUpdateProgressWithRecievedContentLength:(long long)recieved expected:(long long)expected;

@end


/**
 Internal stuff, do not use the same identifier for custom builders
 
 @see LQImageLoaderTask -setImageBuilder:withMemoryCacheIdentifier:
 */
static NSString * _Nonnull const LQImageLoaderTaskDefaultMemoryCacheIdentifier = @"__DEFAULT__";

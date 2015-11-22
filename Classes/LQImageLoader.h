
#import <Foundation/Foundation.h>
@import UIKit;
#import "LQMacros.h"
#import "LQImageHTTPCache.h"


@class LQImageLoaderTask;
@class LQImageLoaderPreloadingContext;
@protocol LQImageLoaderAuthChallenging;


/**
 The main class for image downloading
 
 @see LQImageLoaderTask
 */
@interface LQImageLoader : NSObject

@property (nullable) id<LQImageLoaderAuthChallenging> authChallenger;

/// Created by default. Set it to nil to disable HTTP caching.
@property (nullable) LQImageHTTPCache *HTTPCache;

LQ_UNAVAILABLE_NSOBJECT_INIT

/**
 Creates the loader with max concurrent task count and corresponding @c NSURLSession configuration
 
 @see NSURLSessionConfiguration
 */
- (nonnull instancetype)initWithMaxConcurrentTaskCount:(NSUInteger)count sessionConfiguration:(nonnull NSURLSessionConfiguration *)sessionConfiguration NS_DESIGNATED_INITIALIZER;

/**
 Creates the loader with max concurrent task count and [NSURLSessionConfiguration defaultSessionConfiguration]
 
 @see -initWithMaxConcurrentTaskCount:sessionConfiguration:
 */
- (nonnull instancetype)initWithMaxConcurrentTaskCount:(NSUInteger)count;

/**
 Starts an image loading from the @c url or postpones it according to the provided max concurrent task count (see -initWithMaxConcurrentTaskCount:)
 */
- (void)loadImageWithURL:(nonnull NSURL *)url completion:(void (^ __nonnull)(UIImage * __nullable image, NSError * __nullable error))completion;

/**
 Starts the @c imageTask or postpones it according to the provided max concurrent task count (see -initWithMaxConcurrentTaskCount:)
 
 @see LQImageLoaderTask
 */
- (void)startTask:(nonnull LQImageLoaderTask *)imageTask;

@end


#pragma mark - Preloading


@interface LQImageLoader (LQImagePreloading)

/// The @c completion block is called on the main thread
- (void)preloadImageWithURL:(nonnull NSURL *)url completion:(void (^ __nullable)(BOOL preloaded))completion;

/// Both @c progress and @c completion blocks are called on the main thread
- (void)preloadImageURLs:(nonnull NSArray<NSURL *> *)urls withProgress:(void (^ __nullable)(LQImageLoaderPreloadingContext * __nonnull context))progress completion:(void (^ __nullable)(LQImageLoaderPreloadingContext * __nonnull context))completion;

@end


static const NSUInteger LQImageLoaderDefaultMaxConcurrentTaskCount = 10;

@interface LQImageLoader (LQSharedImageLoader)

+ (nonnull instancetype)shared;

+ (void)setShared:(nonnull LQImageLoader *)loader;

@end


@interface LQImageLoaderPreloadingContext : NSObject

/// Total count of image urls to preload
@property (nonatomic, readonly) NSUInteger totalCount;
/// Completed (also failed) count
@property (nonatomic, readonly) NSUInteger completedCount;
/// Successfully completed count
@property (nonatomic, readonly) NSUInteger preloadedCount;
/// @c totalCount == @c preloadedCount
@property (nonatomic, readonly) BOOL allPreloaded;

@end

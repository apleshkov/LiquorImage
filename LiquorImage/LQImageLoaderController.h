
@import Foundation;
#import "LQMacros.h"


@class LQImageLoaderTask;
@protocol LQImageLoaderControllerDataSource;
@protocol LQImageLoaderAuthChallenging;
@protocol LQImageHTTPCaching;


@interface LQImageLoaderController : NSObject <NSURLSessionDelegate>

@property (nullable) id<LQImageLoaderControllerDataSource> dataSource;

LQ_UNAVAILABLE_NSOBJECT_INIT

- (nonnull instancetype)initWithMaxConcurrentTaskCount:(NSUInteger)count NS_DESIGNATED_INITIALIZER;

- (void)startImageTask:(nonnull LQImageLoaderTask *)imageTask;

- (void)cancelImageTask:(nonnull LQImageLoaderTask *)imageTask;

- (BOOL)isLoadingImageTask:(nonnull LQImageLoaderTask *)imageTask;

@end


@protocol LQImageLoaderControllerDataSource <NSObject>

- (nonnull NSURLSession *)imageLoaderControllerURLSession:(nonnull LQImageLoaderController *)controller;

- (nullable id<LQImageLoaderAuthChallenging>)imageLoaderControllerAuthChallenger:(nonnull LQImageLoaderController *)controller;

- (nullable id<LQImageHTTPCaching>)imageLoaderControllerHTTPCache:(nonnull LQImageLoaderController *)controller;

@end

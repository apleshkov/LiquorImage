
#import "LQImageLoaderTask.h"


@protocol LQImageLoaderTaskClient;


typedef void(^LQImageLoaderTaskInternalCompletionHandler)(UIImage * _Nullable image, NSError * _Nullable error);


@interface LQImageLoaderTask (LQProtected)

@property (weak, nullable) id<LQImageLoaderTaskClient> client;
@property BOOL preloading;

- (void)completeWithData:(nullable NSData *)data error:(nullable NSError *)error;

- (BOOL)tryRestoreFromCache;

- (void)updateProgressWithRecievedContentLength:(long long)recieved expected:(long long)expected;

@property (copy, nullable) LQImageLoaderTaskInternalCompletionHandler internalCompletionHandler;

@end


@protocol LQImageLoaderTaskClient <NSObject>

- (void)cancelImageLoaderTask:(nonnull LQImageLoaderTask *)imageTask;

@end

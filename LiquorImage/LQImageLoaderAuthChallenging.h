
#import <Foundation/Foundation.h>

/**
 Controls auth challenges
 
 @see LQImageLoader authChallenger
 */
@protocol LQImageLoaderAuthChallenging <NSObject>

- (void)URLSession:(nonnull NSURLSession *)session task:(nonnull NSURLSessionTask *)task didReceiveChallenge:(nonnull NSURLAuthenticationChallenge *)challenge completionHandler:(void (^ __nonnull)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * __nullable credential))completionHandler;

@end

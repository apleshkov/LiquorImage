//
//  LQImageHTTPCaching.h
//  ImageLoaderSample
//
//  Created by Andrey on 08/11/15.
//
//

#import <Foundation/Foundation.h>

@protocol LQImageHTTPCaching <NSObject>

- (void)URLSession:(nonnull NSURLSession *)session dataTask:(nonnull NSURLSessionDataTask *)dataTask willCacheResponse:(nonnull NSCachedURLResponse *)proposedResponse completionHandler:(void (^ _Nonnull)(NSCachedURLResponse * _Nullable cachedResponse))completionHandler;

@end

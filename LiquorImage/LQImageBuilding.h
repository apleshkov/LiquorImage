
@import Foundation;
@import UIKit;


/** 
 Builds an image from raw data
 
 @see LQImageLoaderTask -setImageBuilder:withMemoryCacheIdentifier:
 @see LQImageLoaderTask -setImageBuilderIgnoringMemoryCache:
 @see LQDefaultImageBuilder
 */
@protocol LQImageBuilding <NSObject>

- (nullable UIImage *)imageFromData:(nonnull NSData *)data error:(NSError * _Nullable * _Nonnull)error;

@end

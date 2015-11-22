//
//  LQDefaultImageBuilder.h
//  ImageLoaderSample
//
//  Created by Andrey on 03/11/15.
//
//

#import <Foundation/Foundation.h>
#import "LQImageBuilding.h"

/** 
 Default image builder.
 Could be used in custom ones to get @c UIImage and then do additional transformations:
 
 @code
 @implementation CustomImageBuilder
 
 - (UIImage *)imageFromData:(NSData *)data error:(NSError *__autoreleasing  _Nullable *)error {
     UIImage *image = [[LQDefaultImageBuilder shared] imageFromData:data error:error];
     if (image) {
        return [image imageByAddingSomeCoolEffect];
     }
     return nil;
 }
 
 @end
 @endcode
 */
@interface LQDefaultImageBuilder : NSObject <LQImageBuilding>

/// thread-safe
+ (nonnull instancetype)shared;

@end

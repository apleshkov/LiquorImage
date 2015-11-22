//
//  LQBlockImageBuilder.h
//  ImageLoaderSample
//
//  Created by Andrey on 04/11/15.
//
//

#import <Foundation/Foundation.h>
#import "LQImageBuilding.h"
#import "LQMacros.h"


typedef UIImage * _Nullable (^LQBlockImageBuilderBlock)(NSData * _Nonnull data, NSError * _Nullable * _Nonnull error);


/**
 Image builder with block
 
 @note @c block calls in the background
 */
@interface LQBlockImageBuilder : NSObject <LQImageBuilding>

LQ_UNAVAILABLE_NSOBJECT_INIT

- (nonnull instancetype)initWithBlock:(nonnull LQBlockImageBuilderBlock)block NS_DESIGNATED_INITIALIZER;

@end

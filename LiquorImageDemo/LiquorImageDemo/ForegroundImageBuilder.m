//
//  ForegroundImageBuilder.m
//  LiquorImageDemo
//
//  Created by Andrew Pleshkov on 27.11.15.
//  Copyright © 2015 Andrew Pleshkov. All rights reserved.
//

#import "ForegroundImageBuilder.h"
#import <LQDefaultImageBuilder.h>
#import <UIImage+RoundedCorner.h>

@implementation ForegroundImageBuilder

- (UIImage *)imageFromData:(NSData *)data error:(NSError *__autoreleasing  _Nullable *)error {
    UIImage *image = [[LQDefaultImageBuilder shared] imageFromData:data error:error];
    if (image) {
        image = [image roundedCornerImage:15 borderSize:0];
    }
    return image;
}

@end

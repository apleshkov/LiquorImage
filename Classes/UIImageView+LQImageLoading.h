//
//  UIImageView+LQImageLoading.h
//  ImageLoaderSample
//
//  Created by Andrey on 08/09/15.
//
//

#import <UIKit/UIKit.h>
#import "LQImageLoader.h"
#import "LQImageLoaderTask.h"

@interface UIImageView (LQImageLoading)

@property (nonatomic, nullable) UIImage *lq_placeholder;

- (void)lq_setImageWithURL:(nullable NSURL *)url;

- (void)lq_setImageWithTask:(nullable LQImageLoaderTask *)task loader:(nullable LQImageLoader *)loader;

@end

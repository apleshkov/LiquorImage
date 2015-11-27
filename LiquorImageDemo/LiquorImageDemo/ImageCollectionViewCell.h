//
//  ImageCollectionViewCell.h
//  LiquorImageDemo
//
//  Created by Andrew Pleshkov on 27.11.15.
//  Copyright © 2015 Andrew Pleshkov. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FlickrImage;

@interface ImageCollectionViewCell : UICollectionViewCell

- (void)displayImage:(nonnull FlickrImage *)image;

@end

//
//  FlickrImage.h
//  LiquorImageDemo
//
//  Created by Andrew Pleshkov on 27.11.15.
//  Copyright © 2015 Andrew Pleshkov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FlickrImage : NSObject

@property (nonatomic, readonly, copy, nullable) NSString *authorID;
@property (nonatomic, readonly, nullable) NSURL *imageURL;

+ (void)loadImagesWithCompletion:(void (^ _Nonnull)(NSArray<FlickrImage *> * _Nullable images, NSError * _Nullable error))completion;

@end

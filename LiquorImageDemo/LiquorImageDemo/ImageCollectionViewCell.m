//
//  ImageCollectionViewCell.m
//  LiquorImageDemo
//
//  Created by Andrew Pleshkov on 27.11.15.
//  Copyright © 2015 Andrew Pleshkov. All rights reserved.
//

#import "ImageCollectionViewCell.h"
#import "FlickrImage.h"
#import <LiquorImage.h>
#import <PureLayout.h>
#import "ForegroundImageBuilder.h"

#import <LQDefaultImageBuilder.h>
#import <LQBlockImageBuilder.h>
#import <UIImage+Resize.h>
#import <UIImage+ImageEffects.h>


@interface ImageCollectionViewCell () <LQImageLoaderTaskDelegate>

@property (nonatomic, readonly, nonnull) UILabel *authorLabel;

@property (nonatomic, readonly, nonnull) UIImageView *thumbImageView;
@property (nonatomic, nullable) LQImageLoaderTask *thumbImageTask;

@property (nonatomic, readonly, nonnull) UIImageView *backgroundImageView;
@property (nonatomic, nullable) LQImageLoaderTask *backgroundImageTask;

@end


@implementation ImageCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    self.clipsToBounds = YES;
    _authorLabel = ({
        UILabel *label = [UILabel new];
        label.numberOfLines = 0;
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:12];
        label;
    });
    _thumbImageView = ({
        UIImageView *view = [UIImageView new];
        view.contentMode = UIViewContentModeScaleAspectFit;
        view;
    });
    _backgroundImageView = ({
        UIImageView *view = [[UIImageView alloc] initWithFrame:self.bounds];
        view.backgroundColor = [UIColor lightGrayColor];
        view.contentMode = UIViewContentModeScaleAspectFill;
        view;
    });
    [self.contentView addSubview:_backgroundImageView];
    [self.contentView addSubview:_thumbImageView];
    [self.contentView addSubview:_authorLabel];
    
    [_backgroundImageView autoPinEdgesToSuperviewEdges];
    
    [_thumbImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.contentView withMultiplier:0.6 relation:NSLayoutRelationEqual];
    [_thumbImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.contentView withMultiplier:0.6 relation:NSLayoutRelationEqual];
    [_thumbImageView autoCenterInSuperview];
    
    [_authorLabel autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(5, 5, 0, 5) excludingEdge:ALEdgeBottom];
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    [self clearImagesAndCancelLoading];
}

- (void)clearImagesAndCancelLoading {
    [self.thumbImageTask cancel];
    [self.backgroundImageTask cancel];
    self.thumbImageView.image = nil;
    self.backgroundImageView.image = nil;
}

- (void)displayImage:(FlickrImage *)image {
    NSParameterAssert(image);
    self.authorLabel.text = image.authorID;
    NSURL *url = image.imageURL;
    if (!url) {
        [self clearImagesAndCancelLoading];
        return;
    }
    
    self.thumbImageTask = ({
        LQImageLoaderTask *task = [[LQImageLoaderTask alloc] initWithURL:url];
        [task setImageBuilder:[ForegroundImageBuilder new] withMemoryCacheIdentifier:@"thumb"];
        task.delegate = self;
        task;
    });
    
    self.backgroundImageTask = ({
        LQImageLoaderTask *task = [[LQImageLoaderTask alloc] initWithURL:url];
        CGSize imageSize = self.backgroundImageView.bounds.size;
        id<LQImageBuilding> builder = [[LQBlockImageBuilder alloc] initWithBlock:^UIImage * _Nullable(NSData * _Nonnull data, NSError *__autoreleasing  _Nullable * _Nonnull error) {
            UIImage *image = [[LQDefaultImageBuilder shared] imageFromData:data error:error];
            image = [image resizedImage:imageSize interpolationQuality:kCGInterpolationDefault];
            image = [image applyDarkEffect];
            return image;
        }];
        [task setImageBuilder:builder withMemoryCacheIdentifier:@"bg"];
        task.delegate = self;
        task;
    });
    
    [[LQImageLoader shared] startTask:self.thumbImageTask];
    [[LQImageLoader shared] startTask:self.backgroundImageTask];
}

#pragma mark LQImageLoaderTaskDelegate

- (void)imageLoaderTask:(nonnull LQImageLoaderTask *)task didCompleteWithImage:(nullable UIImage *)image error:(nullable NSError *)error {
    if (self.thumbImageTask == task) {
        self.thumbImageView.image = image;
    } else if (self.backgroundImageTask == task) {
        self.backgroundImageView.image = image;
    }
}

@end

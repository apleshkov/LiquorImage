# LiquorImage

Image loading + background transforming.

Features:
- Transform downloaded images in the background before displaying
- Persistent caching
- Preloading
- iOS 7.0+

*[Demo](./LiquorImageDemo/) images are taken from the [Flickr public feed](https://www.flickr.com/services/feeds/docs/photos_public/).*

## Transforming

Want to resize and round a downloaded image, which originally is huge and square? Sometimes it's ok to do that via `CALayer` or so, but it could decrease performance of e.g. `UICollectionView`. So *LiquorImage* helps to transform downloaded images in the background:

*Each UICollectionView cell contains two different versions of the same (corresponding) image: blurred one as a background and resized & rounded in the foreground:*

![Demo](https://cloud.githubusercontent.com/assets/578119/11371533/0a32eed0-92da-11e5-877d-318e56e6238f.gif)

```
//////////////////////////////
// ForegroundImageBuilder.m //
//////////////////////////////

@implementation ForegroundImageBuilder

- (UIImage *)imageFromData:(NSData *)data error:(NSError *__autoreleasing  _Nullable *)error {
    UIImage *image = [[LQDefaultImageBuilder shared] imageFromData:data error:error];
    if (image) {
        image = [image roundedCornerImage:15 borderSize:0];
    }
    return image;
}

@end

////////////
// Cell.m //
////////////

...

- (void)displayImage:(FlickrImage *)image {
    ...

    self.thumbImageTask = ({
        LQImageLoaderTask *task = [[LQImageLoaderTask alloc] initWithURL:url];
        // setting ForegroundImageBuilder
        [task setImageBuilder:[ForegroundImageBuilder new] withMemoryCacheIdentifier:@"thumb"];
        task.delegate = self;
        task;
    });

    self.backgroundImageTask = ({
        LQImageLoaderTask *task = [[LQImageLoaderTask alloc] initWithURL:url];
        CGSize imageSize = self.backgroundImageView.bounds.size;
        // block-based image builder with blurring
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

    // start tasks
    [[LQImageLoader shared] startTask:self.thumbImageTask];
    [[LQImageLoader shared] startTask:self.backgroundImageTask];
}

...
```

## Preloading

*Preload images and optionally represent the progress before displaying a collection view:*

![Preloading demo](https://cloud.githubusercontent.com/assets/578119/11371531/0a03ca56-92da-11e5-904c-ba81511223c5.gif)

```
[[LQImageLoader shared] preloadImageURLs:preloads withProgress:^(LQImageLoaderPreloadingContext * _Nonnull context) {
    textLabel.text = [NSString stringWithFormat:@"Preloading:\n\n%lu / %lu", (unsigned long)context.completedCount, (unsigned long)context.totalCount];
} completion:^(LQImageLoaderPreloadingContext * _Nonnull context) {
    ...
}];
```

## Persistent Caching

The loader uses HTTP response cache info by default, but you can control the [`max-age`](http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.9.3) of an image via `HTTPCache`:

```
[[LQImageLoader shared].HTTPCache setURL:url maxAgeInSeconds:1000];
```

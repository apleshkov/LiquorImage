# LiquorImage

Image loading + background transforming.

Features:
- Transform downloaded images in the background before displaying
- Persistent caching
- Preloading
- iOS 7.0+

*Demo images are taken from [Flickr public feed](https://www.flickr.com/services/feeds/docs/photos_public/).*

## Transforming

Want to resize and round a downloaded image, which originally is huge and square? Sometimes it's ok to do that via `CALayer` or so, but it could decrease performance of e.g. UICollectionView. So *LiquorImage* helps to transform downloaded images in the background:

*Each UICollectionView cell contains two different versions of the same (corresponding) image: blurred one as a background and resized & rounded in the foreground:*
![Demo](https://cloud.githubusercontent.com/assets/578119/11371533/0a32eed0-92da-11e5-877d-318e56e6238f.gif)

```
example
```

## Preloading

*Preload images and optionally represent the progress before displaying a collection view:*
![Preloading demo](https://cloud.githubusercontent.com/assets/578119/11371531/0a03ca56-92da-11e5-904c-ba81511223c5.gif)

```
example
```

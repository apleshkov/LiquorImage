
#import "UIImageView+LQImageLoading.h"
#import "LQImageLoaderTask.h"
@import ObjectiveC;


@interface _LQInternalImageViewObject : NSObject <LQImageLoaderTaskDelegate>

@property (nonatomic, weak, nullable) UIImageView *thisImageView;
@property (nonatomic, nullable) UIImage *placeholder;
@property (nonatomic, nullable) LQImageLoaderTask *currentTask;

@end


@implementation UIImageView (LQImageLoading)

- (nonnull _LQInternalImageViewObject *)lq_internalObject {
    _LQInternalImageViewObject *object = objc_getAssociatedObject(self, _cmd);
    if (!object) {
        object = [_LQInternalImageViewObject new];
        object.thisImageView = self;
        objc_setAssociatedObject(self, _cmd, object, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return object;
}

- (UIImage * __nullable)lq_placeholder {
    return [self lq_internalObject].placeholder;
}

- (void)setLq_placeholder:(UIImage * __nullable)lq_placeholder {
    [self lq_internalObject].placeholder = lq_placeholder;
}

- (void)lq_setImageWithURL:(NSURL *)url {
    LQImageLoaderTask *task = (url ? [[LQImageLoaderTask alloc] initWithURL:url] : nil);
    [self lq_setImageWithTask:task loader:nil];
}

- (void)lq_setImageWithTask:(LQImageLoaderTask *)task loader:(LQImageLoader *)loader {
    _LQInternalImageViewObject *internalObject = [self lq_internalObject];
    [internalObject.currentTask cancel];
    if (task) {
        task.delegate = internalObject;
        internalObject.currentTask = task;
        [(loader ?: [LQImageLoader shared]) startTask:task];
    } else {
        internalObject.currentTask = nil;
        self.image = nil;
    }
}

- (void)lq_cancelImageLoading {
    _LQInternalImageViewObject *internalObject = [self lq_internalObject];
    [internalObject.currentTask cancel];
    internalObject.currentTask = nil;
}

@end


@implementation _LQInternalImageViewObject

#pragma mark LQImageLoaderTaskDelegate

- (void)imageLoaderTask:(nonnull LQImageLoaderTask *)task didCompleteWithImage:(nullable UIImage *)image error:(nullable NSError *)error {
    if (self.currentTask == task) {
        if (image) {
            self.thisImageView.image = image;
        } else {
            self.thisImageView.image = self.placeholder;
        }
    }
}

@end


#import "LQDefaultImageBuilder.h"

@implementation LQDefaultImageBuilder

- (UIImage *)imageFromData:(NSData *)data error:(NSError *__autoreleasing  _Nullable *)error {
    CGFloat scale = [UIScreen mainScreen].scale;
    return [[UIImage alloc] initWithData:data scale:scale];
}

+ (instancetype)shared {
    static LQDefaultImageBuilder *builder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        builder = [LQDefaultImageBuilder new];
    });
    return builder;
}

@end

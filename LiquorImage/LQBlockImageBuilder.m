
#import "LQBlockImageBuilder.h"


@interface LQBlockImageBuilder ()

@property (nonatomic, readonly, nonnull) LQBlockImageBuilderBlock block;

@end


@implementation LQBlockImageBuilder

- (instancetype)initWithBlock:(LQBlockImageBuilderBlock)block {
    NSParameterAssert(block);
    self = [super init];
    _block = [block copy];
    return self;
}

- (UIImage *)imageFromData:(NSData *)data error:(NSError *__autoreleasing  _Nullable *)error {
    return self.block(data, error);
}

@end


@import Foundation;
@import ObjectiveC;


#define LQSafeCast(CLAZZ, OBJ) ({ id __obj = (OBJ); ([__obj isKindOfClass:[CLAZZ class]] ? (CLAZZ *)__obj : nil); })


#define LQ_NOESCAPE __attribute__((noescape))


#define LQ_QUEUE_GLOBAL(priority)   (dispatch_get_global_queue((priority), 0))
#define LQ_QUEUE_GLOBAL_DEFAULT     (LQ_QUEUE_GLOBAL(DISPATCH_QUEUE_PRIORITY_DEFAULT))

static inline void LQQueueMainAsync(dispatch_block_t block) {
    NSCParameterAssert(block);
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}


static inline BOOL LQURLErrorIsCancelled(NSError *error) {
    return error && error.code == NSURLErrorCancelled && [error.domain isEqualToString:NSURLErrorDomain];
}

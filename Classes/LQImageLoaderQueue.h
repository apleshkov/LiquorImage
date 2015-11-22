//
//  LQImageLoaderQueue.h
//  ImageLoaderSample
//
//  Created by Andrey on 06/09/15.
//
//

#import <Foundation/Foundation.h>
#import "LQMacros.h"


@protocol LQImageLoaderQueueDelegate;


typedef NS_ENUM(NSInteger, LQImageLoaderQueueType) {
    LQImageLoaderQueueTypeLIFO = 0,
    LQImageLoaderQueueTypeFIFO
};


@interface LQImageLoaderQueue : NSObject

@property (nonatomic, weak, nullable) id<LQImageLoaderQueueDelegate> delegate;
@property (nonatomic, readonly) LQImageLoaderQueueType type;
@property (nonatomic, readonly, getter=isEmpty) BOOL empty;

LQ_UNAVAILABLE_NSOBJECT_INIT

- (nonnull instancetype)initWithMaxConcurrentTaskCount:(NSInteger)count type:(LQImageLoaderQueueType)type;

- (void)addTask:(nonnull NSURLSessionTask *)task;

- (void)removeTask:(nonnull NSURLSessionTask *)task;

- (void)unleashPostponedTasks;

@end


@protocol LQImageLoaderQueueDelegate <NSObject>

- (BOOL)imageLoaderQueue:(nonnull LQImageLoaderQueue *)queue canStartTask:(nonnull NSURLSessionTask *)task;

- (void)imageLoaderQueue:(nonnull LQImageLoaderQueue *)queue didRemoveTask:(nonnull NSURLSessionTask *)task;

@end

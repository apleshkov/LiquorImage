//
//  FlickrImage.m
//  LiquorImageDemo
//
//  Created by Andrew Pleshkov on 27.11.15.
//  Copyright © 2015 Andrew Pleshkov. All rights reserved.
//

#import "FlickrImage.h"
#import <LQExtensions.h>


@interface FlickrImage ()

@property (nonatomic, copy, nullable) NSString *authorID;
@property (nonatomic, nullable) NSURL *imageURL;

@end


@implementation FlickrImage

+ (void)loadImagesWithCompletion:(void (^)(NSArray<FlickrImage *> * _Nullable, NSError * _Nullable))completion {
    NSParameterAssert(completion);
    NSURL *url = [NSURL URLWithString:@"https://api.flickr.com/services/feeds/photos_public.gne?format=json&nojsoncallback=1"];
    [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSMutableArray<FlickrImage *> *images;
        if (data.length > 0 && !error) {
            NSDictionary *json = ({
                NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                str = [str stringByReplacingOccurrencesOfString:@"\\'" withString:@"'"];
                NSData *fixedData = [str dataUsingEncoding:NSUTF8StringEncoding];
                LQSafeCast(NSDictionary, [NSJSONSerialization JSONObjectWithData:fixedData options:kNilOptions error:nil]);
            });
            images = [NSMutableArray array];
            for (id entry in json[@"items"]) {
                NSDictionary *anItem = LQSafeCast(NSDictionary, entry);
                if (anItem) {
                    FlickrImage *anImage = [FlickrImage new];
                    anImage.authorID = LQSafeCast(NSString, anItem[@"author_id"]);
                    anImage.imageURL = ({
                        NSDictionary *media = LQSafeCast(NSDictionary, anItem[@"media"]);
                        NSString *m = LQSafeCast(NSString, media[@"m"]);
                        (m ? [NSURL URLWithString:m] : nil);
                    });
                    [images addObject:anImage];
                }
            }
        }
        LQQueueMainAsync(^{
            completion(images, error);
        });
    }] resume];
}

@end

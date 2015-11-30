//
//  PreloadingView.m
//  LiquorImageDemo
//
//  Created by Andrew Pleshkov on 27.11.15.
//  Copyright © 2015 Andrew Pleshkov. All rights reserved.
//

#import "PreloadingView.h"
#import <PureLayout.h>

@implementation PreloadingView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    self.backgroundColor = [UIColor whiteColor];
    _textLabel = ({
        UILabel *label = [UILabel new];
        label.numberOfLines = 0;
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
        label.textColor = [UIColor blackColor];
        label;
    });
    [self addSubview:_textLabel];
    self.layoutMargins = UIEdgeInsetsMake(10, 20, 10, 20);
    [_textLabel autoCenterInSuperviewMargins];
    return self;
}

@end

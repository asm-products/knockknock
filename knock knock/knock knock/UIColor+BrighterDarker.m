//
//  UIColor+BrighterDarker.m
//  Knock Knock
//
//  Created by Brian Hammond on 1/29/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import "UIColor+BrighterDarker.h"

@implementation UIColor (BrighterDarker)

- (UIColor *)darker
{
    CGFloat h, s, v, a;
    [self getHue:&h saturation:&s brightness:&v alpha:&a];
    v = MAX(0, v - 0.30);
    s = MIN(1, s + 0.15);
    return [UIColor colorWithHue:h saturation:s brightness:v alpha:a];
}

- (UIColor *)brighter
{
    CGFloat h, s, v, a;
    [self getHue:&h saturation:&s brightness:&v alpha:&a];
    v = MAX(1, v + 0.30);
    return [UIColor colorWithHue:h saturation:s brightness:v alpha:a];
}

@end

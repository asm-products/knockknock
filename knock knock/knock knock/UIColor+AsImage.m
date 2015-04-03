//
//  UIColor+AsImage.m
//  Knock Knock
//
//  Created by Brian Hammond on 1/29/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import "UIColor+AsImage.h"

@implementation UIColor (AsImage)

- (UIImage *)asImage
{
    NSMutableDictionary *threadDict = [NSThread currentThread].threadDictionary;
    NSMutableDictionary *colorImages = threadDict[@"colorImages"];

    if (!colorImages) {
        colorImages = [NSMutableDictionary dictionary];
    }

    NSString *key = [self description];
    UIImage *image = colorImages[key];
    if (image) {
        return image;
    }

    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [self CGColor]);
    CGContextFillRect(context, rect);
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    colorImages[key] = image;
    threadDict[@"colorImages"] = colorImages;

    return image;
}

@end

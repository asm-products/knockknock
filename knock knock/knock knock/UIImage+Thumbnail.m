//
//  UIImage+Thumbnail.m
//  Visuality360
//
//  Created by Brian Hammond on 11/4/13.
//  Copyright (c) 2013 Global Apparel Network. All rights reserved.
//

#import "UIImage+Thumbnail.h"

@implementation UIImage (Thumbnail)

- (UIImage *)makeThumbnailOfSize:(CGSize)size
{
    UIGraphicsBeginImageContextWithOptions(size, NO, UIScreen.mainScreen.scale);
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newThumbnail = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newThumbnail;
}

@end

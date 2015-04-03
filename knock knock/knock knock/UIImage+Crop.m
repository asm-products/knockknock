//
//  UIImage+Crop.m
//  Knock Knock
//
//  Created by Brian Hammond on 2/6/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import "UIImage+Crop.h"

@implementation UIImage (Crop)

- (UIImage *)crop:(CGRect)rect
{
    rect = CGRectMake(rect.origin.x*self.scale,
                      rect.origin.y*self.scale,
                      rect.size.width*self.scale,
                      rect.size.height*self.scale);

    CGImageRef imageRef = CGImageCreateWithImageInRect([self CGImage], rect);

    UIImage *result = [UIImage imageWithCGImage:imageRef
                                          scale:self.scale
                                    orientation:self.imageOrientation];

    CGImageRelease(imageRef);

    return result;
}

@end

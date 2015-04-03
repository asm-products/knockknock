//
//  UIView+AsImage.m
//  Knock Knock
//
//  Created by Brian Hammond on 2/11/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import "UIView+AsImage.h"

@implementation UIView (AsImage)

- (UIImage *)asImage
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.opaque, 0.0);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage* img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

@end

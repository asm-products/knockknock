//
//  UIImage+FixRotation.h
//  Visuality360
//
//  Created by Brian Hammond on 11/25/13.
//  Copyright (c) 2013 Global Apparel Network. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (FixRotation)

// http://stackoverflow.com/questions/5427656/ios-uiimagepickercontroller-result-image-orientation-after-upload/5427890#5427890

- (UIImage *)fixOrientation;

@end

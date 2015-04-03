//
//  UIViewController+LayoutUtils.m
//  Visuality360
//
//  Created by Brian Hammond on 9/24/13.
//  Copyright (c) 2013 Global Apparel Network. All rights reserved.
//

#import "UIViewController+LayoutUtils.h"

@implementation UIViewController (LayoutUtils)

- (NSString *)viewClassName
{
    NSString *viewControllerClassName = NSStringFromClass(self.class);
    return [viewControllerClassName substringToIndex:[viewControllerClassName rangeOfString:@"Controller"].location];
}

- (void)loadViewFromClass
{
    NSString *viewClassName = [self viewClassName];

    Class viewClass = NSClassFromString(viewClassName);
    if (viewClass == nil) {
        viewClass = UIView.class;
    }

    self.view = [[viewClass alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
}

- (void)setTitleFromClass
{
    NSString *viewClassName = [self viewClassName];

    self.title = [NSString stringWithFormat:@"%@", [viewClassName substringToIndex:[viewClassName rangeOfString:@"View"].location]];
}

- (CGFloat)navigationBarHeight
{
    CGFloat navigationBarHeight = 0;

    id nextResponder = [self nextResponder];
    while (nextResponder) {
        if ([nextResponder isKindOfClass:UINavigationController.class]) {
            navigationBarHeight = CGRectGetHeight([nextResponder navigationBar].bounds);
            break;
        }
        nextResponder = [nextResponder nextResponder];
    }

    return navigationBarHeight;
}

- (CGFloat)statusBarHeight
{
    CGRect statusBarFrame = [UIApplication sharedApplication].statusBarFrame;
    return MIN(CGRectGetHeight(statusBarFrame), CGRectGetWidth(statusBarFrame));
}

- (id)customView
{
    return self.view;
}

@end

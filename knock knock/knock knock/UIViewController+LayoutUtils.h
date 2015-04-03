//
//  UIViewController+LayoutUtils.h
//  Visuality360
//
//  Created by Brian Hammond on 9/24/13.
//  Copyright (c) 2013 Global Apparel Network. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (LayoutUtils)

// Creates a full-screen view using a class name derived from the class name of this view controller.
// e.g. FooViewController -> FooView. If no such class exists, the view class is that of UIView.

- (void)loadViewFromClass;

// So that you can avoid casting.

- (id)customView;

// Sets the title property to "Foo" from FooViewController.

- (void)setTitleFromClass;

// Height of the UINavigationBar of any UINavigationController this UIViewController is contained in.
// If not contained in a UINavigationController, returns 0.

- (CGFloat)navigationBarHeight;

// Height of the status bar.

- (CGFloat)statusBarHeight;

@end

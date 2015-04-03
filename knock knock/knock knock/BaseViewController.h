//
//  BaseViewController.h
//  Knock Knock
//
//  Created by Brian Hammond on 1/28/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BaseViewController : UIViewController

- (UIButton *)buttonWithText:(NSString *)text backgroundColor:(UIColor *)backgroundColor target:(UIViewController *)target selector:(SEL)selector;

- (void)addBackButton;
- (void)addForwardButton;

- (void)setCustomTitleViewWithText:(NSString *)title;

@end

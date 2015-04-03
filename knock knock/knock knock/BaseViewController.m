//
//  BaseViewController.m
//  Knock Knock
//
//  Created by Brian Hammond on 1/28/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import "BaseViewController.h"

@interface BaseViewController ()

@end

@implementation BaseViewController
{
    NSMutableDictionary *_colorBackgroundImages;
}

- (id)init
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _colorBackgroundImages = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)loadView
{
    CGRect screenRect = [UIScreen mainScreen].applicationFrame;
    CGRect frame = R(0, TopOffset(), CGRectGetWidth(screenRect), CGRectGetHeight(screenRect) - TopOffset());

    self.view = [[UIView alloc] initWithFrame:frame];
    self.view.backgroundColor = kColorDarkBrown;
    self.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight);
    self.view.autoresizesSubviews = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    int vcCount = self.navigationController.viewControllers.count;
    if (vcCount == 2) {
        // Only VCs one-away from the custom main VC fade in and out.
        self.view.alpha = 0;
        self.navigationController.navigationBar.alpha = 0;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    int vcCount = self.navigationController.viewControllers.count;
    if (vcCount == 2) {
        [UIView animateWithDuration:0.3 animations:^{
            self.view.alpha = 1;
            self.navigationController.navigationBar.alpha = 1;
        }];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (UIButton *)buttonWithText:(NSString *)text backgroundColor:(UIColor *)backgroundColor target:(UIViewController *)target selector:(SEL)selector
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];

    UIColor *darkerColor = [backgroundColor darker];
    UIImage *darkerColorImage = [darkerColor asImage];

    [button setBackgroundImage:darkerColorImage forState:UIControlStateHighlighted];
    button.backgroundColor = backgroundColor;

    [button setTitle:text forState:UIControlStateNormal];
    [button setTitleColor:[[UIColor blackColor] colorWithAlphaComponent:0.35] forState:UIControlStateNormal];
    [button setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.35] forState:UIControlStateHighlighted];
    button.titleLabel.font = [UIFont fontWithName:kCustomFontName size:FontSize()];
    button.titleLabel.numberOfLines = 0;
    button.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    button.titleEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    button.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    [button addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];

    [target.view addSubview:button];

    button.frame = R(20 * IdiomScale(),
                     40 * IdiomScale(),
                     target.view.width - 40 * IdiomScale(),
                     44 * IdiomScale());   // target vc will layout

    // If making circular buttons the background image would overflow on highlight otherwise.

    button.clipsToBounds = YES;

    return button;
}

- (void)addBackButton
{
    NIKFontAwesomeIconFactory *factory = [NIKFontAwesomeIconFactory buttonIconFactory];
    factory.size = 38; // use even number
    factory.colors = @[ [[UIColor blackColor] colorWithAlphaComponent:0.5] ];

    UIImage *backButtonImage = [factory createImageForIcon:NIKFontAwesomeIconCaretLeft];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:backButtonImage style:UIBarButtonItemStylePlain target:self action:@selector(navigateBackwards:)];
}

- (void)navigateBackwards:(id)sender
{
    [UIView animateWithDuration:0.3 animations:^{
        if (self.navigationController.viewControllers.count == 2) {
            self.view.alpha = 0;
            self.navigationController.navigationBar.alpha = 0;
        }
    } completion:^(BOOL finished) {
        if (self.presentingViewController) {
            [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        } else {
            BOOL animated = (self.navigationController.viewControllers.count > 2);
            [self.navigationController popViewControllerAnimated:animated];
        }
    }];
}

- (void)addForwardButton
{
    NIKFontAwesomeIconFactory *factory = [NIKFontAwesomeIconFactory buttonIconFactory];
    factory.size = 38; // use even number
    factory.colors = @[ [[UIColor blackColor] colorWithAlphaComponent:0.5] ];

    UIImage *backButtonImage = [factory createImageForIcon:NIKFontAwesomeIconCaretRight];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:backButtonImage style:UIBarButtonItemStylePlain target:self action:@selector(navigateForwards:)];
}

- (void)navigateForwards:(id)sender
{
    // Nop by default
}

- (void)setCustomTitleViewWithText:(NSString *)title
{
    UIFont *font = [UIFont fontWithName:kCustomFontName size:FontSize()];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.textColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    label.font = font;
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.text = title;
    [label sizeToFit];

    self.navigationItem.titleView = label;
}

@end

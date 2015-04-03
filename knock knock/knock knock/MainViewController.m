//
//  MainViewController.m
//  Knock Knock
//
//  Created by Brian Hammond on 1/28/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import "MainViewController.h"
#import "AuthViewController.h"
#import "FriendsViewController.h"
#import "CaptureViewController.h"
#import "SettingsViewController.h"
#import "CompletedCollagesViewController.h"

@interface MainViewController ()

@property (nonatomic, strong) UIButton *tlButton;
@property (nonatomic, strong) UIButton *trButton;
@property (nonatomic, strong) UIButton *blButton;
@property (nonatomic, strong) UIButton *brButton;
@property (nonatomic, strong) UIButton *knockButton;

@property (nonatomic, strong, readwrite) UILabel *unseenCompletedCollagesBadge;
@property (nonatomic, strong, readwrite) UILabel *friendRequestsBadge;

@end

@implementation MainViewController

- (void)loadView
{
    [super loadView];

    self.tlButton = [self buttonWithText:@"profile" backgroundColor:kColorPink target:self selector:@selector(onTopLeft:)];
    self.trButton = [self buttonWithText:@"collages" backgroundColor:kColorOrange target:self selector:@selector(onTopRight:)];
    self.blButton = [self buttonWithText:@"settings" backgroundColor:kColorBlue target:self selector:@selector(onBottomLeft:)];
    self.brButton = [self buttonWithText:@"friends" backgroundColor:kColorGreen target:self selector:@selector(onBottomRight:)];
    self.knockButton = [self buttonWithText:@"knock" backgroundColor:kColorCream target:self selector:@selector(onKnock:)];

    self.unseenCompletedCollagesBadge = [self makeBadge];
    self.friendRequestsBadge = [self makeBadge];

    [self.trButton addSubview:self.unseenCompletedCollagesBadge];
    [self.brButton addSubview:self.friendRequestsBadge];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.navigationController.navigationBarHidden = YES;

    _tlButton.bottomLeft = CGPointMake(0, 0);
    _trButton.bottomRight = CGPointMake(self.view.width, 0);
    _blButton.topLeft = CGPointMake(0, self.view.height);
    _brButton.topRight = CGPointMake(self.view.width, self.view.height);
    _knockButton.alpha = 0;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    CGFloat topOffset = TopOffset();

    [UIView animateWithDuration:0.3 animations:^{
        _tlButton.topLeft = CGPointMake(0, topOffset);
        _trButton.topRight = CGPointMake(self.view.width, topOffset);
        _blButton.bottomLeft = CGPointMake(0, self.view.height);
        _brButton.bottomRight = CGPointMake(self.view.width, self.view.height);
        _knockButton.alpha = 1;
    } completion:nil];
}

- (UILabel *)makeBadge
{
    UIFont *font = [UIFont fontWithName:kCustomFontName size:FontSize()/2];
    CGFloat maxWidth = [@"999" sizeWithFont:font].width;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, maxWidth, maxWidth)];
    label.layer.cornerRadius = maxWidth/2;
    label.backgroundColor = kColorCream;
    label.font = font;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    label.text = @"";
    label.hidden = YES;
    label.clipsToBounds = YES;
    return label;
}

- (void)viewWillLayoutSubviews
{
    CGFloat topOffset = TopOffset();

    CGFloat w = self.view.width;
    CGFloat h = self.view.height;

    _knockButton.width = _knockButton.height = MIN(h/2, w);
    _knockButton.center = CGPointMake(w/2, topOffset + (h - topOffset)/2);
    _knockButton.layer.cornerRadius = _knockButton.width/2;
    CGFloat remainingSpace = h - topOffset - _knockButton.width - 10 * IdiomScale();
    CGFloat buttonHeight = MIN(80 * IdiomScale(), remainingSpace/2);

    if (buttonHeight < 0)
        return;

    _tlButton.width = _trButton.width = _blButton.width = _brButton.width = w/2;
    _tlButton.height = _trButton.height = _blButton.height = _brButton.height = buttonHeight;

    _tlButton.topLeft = CGPointMake(0, topOffset);
    _trButton.topRight = CGPointMake(self.view.width, topOffset);
    _blButton.bottomLeft = CGPointMake(0, self.view.height);
    _brButton.bottomRight = CGPointMake(self.view.width, self.view.height);

    _unseenCompletedCollagesBadge.bottomRight = _friendRequestsBadge.bottomRight = CGPointMake(_trButton.width - 5, _trButton.height - 5);
}

- (void)onTopLeft:(id)sender
{
    [self hideButtonsThen:^{
        [self.navigationController pushViewController:[AuthViewController new] animated:NO];
    }];
}

- (void)onTopRight:(id)sender
{
    _unseenCompletedCollagesBadge.text = @"";
    _unseenCompletedCollagesBadge.hidden = YES;

    [self hideButtonsThen:^{
        [self.navigationController pushViewController:[CompletedCollagesViewController new] animated:NO];
    }];
}

- (void)onBottomLeft:(id)sender
{
    [self hideButtonsThen:^{
        [self.navigationController pushViewController:[SettingsViewController new] animated:NO];
    }];
}

- (void)onBottomRight:(id)sender
{
    _friendRequestsBadge.text = @"";
    _friendRequestsBadge.hidden = YES;

    [self hideButtonsThen:^{
        [self.navigationController pushViewController:[FriendsViewController new] animated:NO];
    }];
}

- (void)onKnock:(id)sender
{
    [self hideButtonsThen:^{
        [self.navigationController pushViewController:[CaptureViewController new] animated:NO];
    }];
}

- (void)hideButtonsThen:(void (^)(void))block
{
    [UIView animateWithDuration:0.3 animations:^{
        _tlButton.bottomLeft = CGPointMake(0, 0);
        _trButton.bottomRight = CGPointMake(self.view.width, 0);
        _blButton.topLeft = CGPointMake(0, self.view.height);
        _brButton.topRight = CGPointMake(self.view.width, self.view.height);
        _knockButton.alpha = 0;
    } completion:^(BOOL finished) {
        block();
    }];
}

@end

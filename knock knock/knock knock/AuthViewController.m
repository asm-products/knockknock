//
//  AuthViewController.m
//  Knock Knock
//
//  Created by Brian Hammond on 1/28/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import "AuthViewController.h"

@interface AuthViewController ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *usernameLabel;
@property (nonatomic, strong) UIButton *facebookButton;
@property (nonatomic, strong) UIButton *twitterButton;
@property (nonatomic, strong) UIButton *logoutButton;

@end

@implementation AuthViewController

- (void)loadView
{
    [super loadView];

    // Show logo or if there's a current user their profile photo.

    self.imageView = ({
        UIImage *image = [UIImage imageNamed:@"knocklogo"];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.clipsToBounds = YES;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView;
    });

    [self.view addSubview:_imageView];

    if ([PFUser currentUser]) {
        self.usernameLabel = ({
            UIFont *font = [UIFont fontWithName:kCustomFontName size:FontSize()];
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.textColor = kColorCream;
            label.font = font;
            label.textAlignment = NSTextAlignmentCenter;
            label.backgroundColor = [UIColor clearColor];
            label.lineBreakMode = NSLineBreakByWordWrapping;
            label.numberOfLines = 0;
            label;
        });

        self.navigationController.navigationBarHidden = NO;

        if ([self.navigationController.navigationBar respondsToSelector:@selector(setBarTintColor:)])
            self.navigationController.navigationBar.barTintColor = kColorPink;

        [self setCustomTitleViewWithText:@"profile"];

        [self addBackButton];

    } else {
        self.navigationController.navigationBarHidden = YES;
    }

    [self.view addSubview:_usernameLabel];

    self.facebookButton = [self buttonWithText:@"use facebook" backgroundColor:kColorDarkBlue target:self selector:@selector(doFacebook:)];
    self.twitterButton = [self buttonWithText:@"use twitter" backgroundColor:kColorBlue target:self selector:@selector(doTwitter:)];

    if ([PFUser currentUser]) {
        self.logoutButton = [self buttonWithText:@"sign out" backgroundColor:kColorPink target:self selector:@selector(doLogout:)];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if ([self.navigationController.navigationBar respondsToSelector:@selector(setBarTintColor:)])
        self.navigationController.navigationBar.barTintColor = kColorPink;
    else
        self.navigationController.navigationBar.tintColor = kColorPink;

    [self updateSocialMediaButtonStates];

    _imageView.alpha = 0;
    _usernameLabel.alpha = 0;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [UIView animateWithDuration:1.0 delay:0.65 options:0 animations:^{
        _imageView.alpha = 1;
        _usernameLabel.alpha = 1;
    } completion:nil];
}

- (void)viewDidLayoutSubviews
{
    CGFloat w = self.view.width;
    CGFloat h = self.view.height;
    CGFloat margin = 30 * IdiomScale();
    CGFloat bottom = h - margin;

    if ([PFUser currentUser]) {
        _logoutButton.hidden = NO;
        _logoutButton.bottom = bottom;
        bottom = _logoutButton.top - margin;
    } else {
        _imageView.layer.cornerRadius = 0;
        _logoutButton.hidden = YES;
    }

    _twitterButton.bottom = bottom;
    bottom = _twitterButton.top - margin;

    _facebookButton.bottom = bottom;
    bottom = _facebookButton.top - margin;

    if ([PFUser currentUser]) {
        CGFloat usernameHeight = [_usernameLabel.text sizeWithFont:_usernameLabel.font constrainedToSize:CGSizeMake(_usernameLabel.width, 9999) lineBreakMode:NSLineBreakByWordWrapping].height;
        _usernameLabel.frame = R(0, bottom - usernameHeight, w, usernameHeight);
        
        bottom = _usernameLabel.top - margin;
    }

    CGFloat top = TopOffset() + 44 + margin;
    CGFloat imageSize = MIN(_imageView.image.size.width, bottom - top);
    _imageView.frame = R(w/2 - imageSize/2, top + (bottom - top)/2 - imageSize/2, imageSize, imageSize);

    if ([PFUser currentUser]) {
        _imageView.layer.cornerRadius = _imageView.width/2;
    }
}

- (void)updateSocialMediaButtonStates
{
    if ([PFUser currentUser]) {
        NSString *photoURL = [PFUser currentUser][@"profilePhotoURL"];
        if (photoURL.length > 0) {
            [_imageView sd_setImageWithURL:[NSURL URLWithString:photoURL] placeholderImage:_imageView.image options:SDWebImageCacheMemoryOnly completed:nil];
        }
    }

    _usernameLabel.text = [[PFUser currentUser] displayName];

    if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        [_facebookButton setTitle:@"linked with facebook" forState:UIControlStateNormal];
        [_facebookButton setTitle:@"linked with facebook" forState:UIControlStateDisabled];
        _facebookButton.enabled = NO;
        _facebookButton.alpha = 0.5;
    } else {
        [_facebookButton setTitle:@"use facebook" forState:UIControlStateNormal];
        _facebookButton.enabled = YES;
        _facebookButton.alpha = 1.0;
    }

    if ([PFTwitterUtils isLinkedWithUser:[PFUser currentUser]]) {
        [_twitterButton setTitle:@"linked with twitter" forState:UIControlStateNormal];
        [_twitterButton setTitle:@"linked with twitter" forState:UIControlStateDisabled];
        _twitterButton.enabled = NO;
        _twitterButton.alpha = 0.5;
    } else {
        [_twitterButton setTitle:@"use twitter" forState:UIControlStateNormal];
        _twitterButton.enabled = YES;
        _twitterButton.alpha = 1.0;
    }
}

#pragma mark - facebook

- (void)doFacebook:(id)sender
{
    _facebookButton.enabled = _twitterButton.enabled = NO;

    __weak typeof(self) weakSelf = self;

    PFBooleanResultBlock block = ^(BOOL ok, NSError *error) {
        [weakSelf updateSocialMediaButtonStates];
    };

    if ([PFUser currentUser]) {
        [[PFUser currentUser] linkWithFacebookBlock:block];
    } else {
        [PFUser loginWithFacebookBlock:block];
    }
}

#pragma mark - twitter

- (void)doTwitter:(id)sender
{
    _facebookButton.enabled = _twitterButton.enabled = NO;

    __weak typeof(self) weakSelf = self;

    PFBooleanResultBlock block = ^(BOOL ok, NSError *error) {
        [weakSelf updateSocialMediaButtonStates];
    };

    if ([PFUser currentUser]) {
        [[PFUser currentUser] linkWithTwitterBlock:block];
    } else {
        [PFUser loginWithTwitterBlock:block];
    }
}

#pragma mark - logout

- (void)doLogout:(id)sender
{
    DDLogInfo(@"logout");

    [PFUser logOut];

    [[NSNotificationCenter defaultCenter] postNotificationName:kLogoutNotification object:nil];
}

@end

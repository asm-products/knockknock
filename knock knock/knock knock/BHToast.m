//
//  BHToast.m
//  Visuality360
//
//  Created by Brian Hammond on 11/6/13.
//  Copyright (c) 2013 Global Apparel Network. All rights reserved.
//

#import "BHToast.h"

#define ToastHeight   (50 * IdiomScale())

#define ScreenWidth   [UIScreen mainScreen].bounds.size.width
#define ScreenHeight  [UIScreen mainScreen].bounds.size.height

@interface BHToast ()

@property (strong, nonatomic) UILabel *messageLabel;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (strong, nonatomic) UIProgressView *progressView;
@property (strong, nonatomic) UITapGestureRecognizer *tapGR;

@end

@implementation BHToast

- (id)init
{
    self = [super init];

    if (self) {
        self.frame = CGRectMake(0.0, ScreenHeight - ToastHeight, ScreenWidth, ToastHeight);

        self.windowLevel = UIWindowLevelStatusBar + 1.0f;
        self.hidden = YES;

        self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];

        _progressView.frame = CGRectMake(ScreenWidth - ScreenWidth/4, ToastHeight/2 - _progressView.bounds.size.height/2, ScreenWidth/4 - 10 * IdiomScale(), _progressView.bounds.size.height);

        _progressView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleWidth);
        _progressView.hidden = YES;
        _progressView.backgroundColor = [UIColor clearColor];
        [self addSubview:_progressView];

        self.messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(10 * IdiomScale(), 0.0f, _progressView.frame.origin.x - 10 * IdiomScale(), ToastHeight)];
        self.messageLabel.textColor = kColorCream;
        self.messageLabel.backgroundColor = [UIColor clearColor];
        self.messageLabel.font = [UIFont fontWithName:kCustomFontName size:FontSize()*0.65];
        self.messageLabel.autoresizingMask = (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleRightMargin);
        [self addSubview:self.messageLabel];

        [self bringSubviewToFront:_progressView];

        self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        self.activityIndicatorView.hidden = YES;
        [self addSubview:self.activityIndicatorView];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeStatusBarFrame:) name:UIApplicationWillChangeStatusBarFrameNotification object:nil];

        self.tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
        [self addGestureRecognizer:_tapGR];
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (instancetype)sharedToast
{
    static dispatch_once_t token;
    static BHToast *sharedToastView;

    dispatch_once(&token, ^{
        sharedToastView = [[BHToast alloc] init];
    });

    [sharedToastView didChangeStatusBarFrame:nil];

    return sharedToastView;
}

- (void)setMessage:(NSString *)message
{
    _message = [message copy];
    _messageLabel.text = message;
}

- (void)setToastType:(BHToastType)toastType
{
    _toastType = toastType;

    switch (toastType) {
        case BHToastTypeActivity: {
            _activityIndicatorView.hidden = NO;
            [_activityIndicatorView startAnimating];

            CGRect frame = _messageLabel.frame;
            frame.origin.x = _activityIndicatorView.frame.origin.x + _activityIndicatorView.bounds.size.width + 5;
            frame.size.width = _progressView.frame.origin.x - frame.origin.x;
            _messageLabel.frame = frame;

            self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];

            self.progressView.hidden = NO;
            break;
        }

        case BHToastTypePlain:
            _activityIndicatorView.hidden = YES;
            [_activityIndicatorView stopAnimating];

            _messageLabel.frame = CGRectInset(self.bounds, 10 * IdiomScale(), 2);
            self.backgroundColor = kColorDarkBrown;

            self.progressView.progress = 0;
            self.progressView.hidden = YES;
            break;

        case BHToastTypeError:
            _activityIndicatorView.hidden = YES;
            [_activityIndicatorView stopAnimating];

            _messageLabel.frame = CGRectInset(self.bounds, 10 * IdiomScale(), 2);
            _messageLabel.text = [NSString stringWithFormat:@"😕 %@", _message];

            self.backgroundColor = [UIColor colorWithRed:0.6 green:0.2 blue:0.2 alpha:0.8];

            self.progressView.progress = 0;
            self.progressView.hidden = YES;
            break;

        case BHToastTypeSuccess:
            _activityIndicatorView.hidden = YES;
            [_activityIndicatorView stopAnimating];

            _messageLabel.frame = CGRectInset(self.bounds, 10 * IdiomScale(), 2);
            _messageLabel.text = [NSString stringWithFormat:@"😃 %@", _message];

            self.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:0.2 alpha:0.8];

            self.progressView.progress = 0;
            self.progressView.hidden = YES;

            break;
    }
}

- (void)setProgress:(float)progress
{
    _progress = progress;
    _progressView.progress = progress;
    _progressView.hidden = NO;
}

- (void)didChangeStatusBarFrame:(NSNotification *)notification
{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;

    switch (orientation) {
        case UIDeviceOrientationPortrait:
            self.transform = CGAffineTransformIdentity;
            self.frame = CGRectMake(0.0, ScreenHeight - ToastHeight, ScreenWidth, ToastHeight);
            break;

        case UIDeviceOrientationLandscapeLeft:
            self.transform = CGAffineTransformMakeRotation(M_PI * (90.0f) / 180.0f);
            self.frame = CGRectMake(0.0f, 0.0f, ToastHeight, ScreenHeight);
            break;

        case UIDeviceOrientationLandscapeRight:
            self.transform = CGAffineTransformMakeRotation(M_PI * (-90.0f) / 180.0f);
            self.frame = CGRectMake(ScreenWidth - ToastHeight, 0.0f, ToastHeight, ScreenHeight);
            break;

        case UIDeviceOrientationPortraitUpsideDown:
            self.transform = CGAffineTransformMakeRotation(M_PI);
            self.frame = CGRectMake(0.0f, 0.0f, ScreenWidth, ToastHeight);

        default:
            break;
    }
}

- (void)didTap:(UITapGestureRecognizer *)tapGR
{
    if (_tapBlock) {
        _tapBlock();
    }

    self.hidden = YES;
}

@end

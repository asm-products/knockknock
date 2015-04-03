//
//  CaptureReviewViewController.m
//  Knock Knock
//
//  Created by Brian Hammond on 2/6/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import "CaptureReviewViewController.h"
#import "CaptionedImageView.h"
#import "CollageInvitesViewController.h"

@interface CaptureReviewViewController ()

@property (nonatomic, strong) UIImage *image;

@property (nonatomic, strong) UIButton *tlButton;
@property (nonatomic, strong) UIButton *trButton;
@property (nonatomic, strong) UIButton *blButton;
@property (nonatomic, strong) UIButton *brButton;

@property (strong, nonatomic) CaptionedImageView *imageView;

@property (assign) BOOL acceptInProgress;

@end

@implementation CaptureReviewViewController

- (id)initWithImage:(UIImage *)capturedImage
{
    self = [super init];
    if (self) {
        self.image = capturedImage;

        [self registerForKeyboardNotifications];
    }
    return self;
}

- (void)loadView
{
    [super loadView];

    self.tlButton = [self buttonWithText:@"cancel" backgroundColor:kColorPink target:self selector:@selector(onTopLeft:)];
    self.trButton = [self buttonWithText:@"" backgroundColor:kColorOrange target:self selector:@selector(onTopRight:)];
    self.blButton = [self buttonWithText:@"retake" backgroundColor:kColorBlue target:self selector:@selector(onBottomLeft:)];
    self.brButton = [self buttonWithText:@"" backgroundColor:kColorGreen target:self selector:@selector(onBottomRight:)];

    _trButton.userInteractionEnabled = (_collage != nil);

    self.imageView = [[CaptionedImageView alloc] initWithImage:_image];
    [self.view addSubview:_imageView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.navigationController.navigationBarHidden = YES;

    // One may only caption their photo if they are the initiator of a collage.
    // In that case, there will be no collage already that the captured photo will
    // be added to as it is created in the last step of the collage creation flow.

    if (_collage) {
        // We are reviewing a captured image to be added to a collage.

        [self observeCountdown];

        [_brButton setTitle:@"send" forState:UIControlStateNormal];

        _imageView.userInteractionEnabled = NO;
    } else {
        // We are the initiator of a new collage.

        [_trButton setTitle:@"caption" forState:UIControlStateNormal];
        _trButton.userInteractionEnabled = YES;
        
        [_brButton setTitle:@"accept" forState:UIControlStateNormal];

        _imageView.userInteractionEnabled = YES;
    }
}

- (void)observeCountdown
{
    __weak typeof(self) weakSelf = self;

    [_countdown bk_addObserverForKeyPath:@"secondsRemaining" task:^(id sender) {
        NSInteger seconds = weakSelf.countdown.secondsRemaining;
        NSString *text = [NSString stringWithFormat:@"%ds", seconds];
        [weakSelf.trButton setTitle:text forState:UIControlStateNormal];

        if (seconds == 0 && weakSelf.navigationController.topViewController == weakSelf) {
            [weakSelf.trButton setTitle:@"" forState:UIControlStateNormal];

            if (!weakSelf.acceptInProgress) {
                [weakSelf onBottomRight:weakSelf.brButton];
            }
        }
    }];
}

- (void)viewWillLayoutSubviews
{
    CGFloat topOffset = TopOffset();

    _imageView.width = _imageView.height = self.view.width;
    _imageView.center = CGPointMake(self.view.width/2, topOffset + (self.view.height - topOffset)/2);

    CGFloat remainingSpace = self.view.height - topOffset - self.view.width;
    CGFloat buttonHeight = remainingSpace/2;

    _tlButton.width = _trButton.width = _blButton.width = _brButton.width = self.view.width/2;
    _tlButton.height = _trButton.height = _blButton.height = _brButton.height = buttonHeight;

    _tlButton.topLeft = CGPointMake(0, topOffset);
    _trButton.topRight = CGPointMake(self.view.width, topOffset);
    _blButton.bottomLeft = CGPointMake(0, self.view.height);
    _brButton.bottomRight = CGPointMake(self.view.width, self.view.height);
}

- (void)onTopLeft:(id)sender
{
    // Cancel

    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)onTopRight:(id)sender
{
    // caption

    [_imageView becomeFirstResponder];
}

- (void)onBottomLeft:(id)sender
{
    // retake

    [self.navigationController popViewControllerAnimated:NO];
}

- (void)onBottomRight:(id)sender
{
    self.acceptInProgress = YES;

    if (!_collage) {
        // accept -- we are creaating new collage so invite some friends to join.

        id vc = [[CollageInvitesViewController alloc] initWithImage:_image caption:_imageView.caption invitees:nil mode:CollageInvitesViewControllerModeFriends];
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        // send -- we are adding the captured photo to an existing collage.

        __weak typeof(self) weakSelf = self;

        [SVProgressHUD showWithStatus:@"Sending..." maskType:SVProgressHUDMaskTypeClear];

        PFObject *collagePhoto = [PFObject objectWithClassName:@"CollagePhoto"];
        collagePhoto[@"collage"] = _collage;
        collagePhoto[@"author"] = [PFUser currentUser];
        collagePhoto[@"imageFile"] = [PFFile fileWithData:UIImagePNGRepresentation(_image)];
        [collagePhoto saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (error) {
                [SVProgressHUD dismiss];
                [error displayParseError:@"send your knock"];
            } else {
                [SVProgressHUD showSuccessWithStatus:@"Your photo has been sent!"];

                [UIView animateWithDuration:1.5 animations:^{
                    weakSelf.tlButton.alpha = weakSelf.trButton.alpha = weakSelf.blButton.alpha = weakSelf.brButton.alpha = 0;
                } completion:^(BOOL finished) {
                    [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                        weakSelf.imageView.left = -20 * IdiomScale();
                    } completion:^(BOOL finished) {
                        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                            weakSelf.imageView.left = weakSelf.view.width * 2;
                            weakSelf.imageView.alpha = 0;
                        } completion:^(BOOL finished) {
                            [weakSelf.navigationController popToRootViewControllerAnimated:NO];
                        }];
                    }];
                }];
            }
        }];
    }
}

- (void)sendPhoto
{
    if (_collage && !_acceptInProgress) {
        [self onBottomRight:nil];
    }
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

//    [_countdown bk_remove];
}

- (void)keyboardWillShow:(NSNotification*)aNotification
{
    NSDictionary *info = [aNotification userInfo];
    CGSize kbSize = [info[UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    CGFloat duration = [info[UIKeyboardAnimationDurationUserInfoKey] floatValue];

    [UIView animateWithDuration:duration animations:^{
        _imageView.bottom = self.view.height - kbSize.height;
        _tlButton.alpha = _trButton.alpha = _blButton.alpha = _brButton.alpha = 0;
    }];
}

- (void)keyboardWillHide:(NSNotification*)aNotification
{
    NSDictionary *info = [aNotification userInfo];
    CGFloat duration = [info[UIKeyboardAnimationDurationUserInfoKey] floatValue];

    [UIView animateWithDuration:duration animations:^{
        [self viewWillLayoutSubviews];
        _tlButton.alpha = _trButton.alpha = _blButton.alpha = _brButton.alpha = 1;
    }];
}

@end

//
//  CollageSenderViewController.m
//  Knock Knock
//
//  Created by Brian Hammond on 2/7/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import "CollageSenderViewController.h"
#import "CaptionedImageView.h"
#import "LQAudioManager.h"
#import "CollageFinalizer.h"

@interface CollageSenderViewController ()

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, copy) NSString *caption;
@property (nonatomic, copy) NSArray *invitees;

@property (nonatomic, strong) UIButton *topButton;
@property (nonatomic, strong) UIButton *bottomButton;
@property (nonatomic, strong) UIButton *knockButton;
@property (nonatomic, strong) CaptionedImageView *imageView;
@property (nonatomic, strong) NSArray *backgroundBarViews;

@end

@implementation CollageSenderViewController

- (id)initWithImage:(UIImage *)image
            caption:(NSString *)caption
           invitees:(NSArray *)invitees
{
    self = [super init];
    if (self) {
        self.image = image;
        self.caption = caption;
        self.invitees = invitees;
    }
    return self;
}

- (void)loadView
{
    [super loadView];

    self.knockButton = [self buttonWithText:@"knock" backgroundColor:kColorCream target:self selector:@selector(onKnockButton:)];
    self.knockButton.userInteractionEnabled = NO;

    self.topButton = [self buttonWithText:@"back" backgroundColor:kColorPink target:self selector:@selector(onTopButton:)];

    self.bottomButton = [self buttonWithText:@"pull down photo to send" backgroundColor:kColorCream target:self selector:@selector(onBottomButton:)];
    self.bottomButton.userInteractionEnabled = NO;

    self.backgroundBarViews = [@[ kColorPink, kColorOrange, kColorBlue, kColorGreen ] bk_map:^id(UIColor *backgroundColor) {
        UIView *barView = [[UIView alloc] initWithFrame:CGRectZero];
        barView.backgroundColor = backgroundColor;
        [self.view addSubview:barView];
        return barView;
    }];

    self.imageView = [[CaptionedImageView alloc] initWithImage:_image caption:_caption];
    _imageView.editable = NO;
    [self.view addSubview:_imageView];

    UIPanGestureRecognizer *panGR = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPanCaptionedImageView:)];
    [_imageView addGestureRecognizer:panGR];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewWillLayoutSubviews
{
    CGFloat topOffset = TopOffset();

    _imageView.width = _imageView.height = self.view.width;
    _imageView.center = CGPointMake(self.view.width/2, topOffset + (self.view.height - topOffset)/2);

    CGFloat remainingSpace = self.view.height - topOffset - self.view.width;
    CGFloat buttonHeight = remainingSpace/2;

    _topButton.width = _bottomButton.width = self.view.width;
    _topButton.height = _bottomButton.height = buttonHeight;

    _topButton.topLeft = CGPointMake(0, topOffset);
    _bottomButton.bottomLeft = CGPointMake(0, self.view.height);

    _knockButton.frame = _topButton.frame;

    __block CGFloat barTop = _topButton.bottom;
    CGFloat barWidth = self.view.width;
    CGFloat barHeight = 20 * IdiomScale();

    [_backgroundBarViews enumerateObjectsUsingBlock:^(UIView *barView, NSUInteger idx, BOOL *stop) {
        barView.frame = R(0, barTop, barWidth, barHeight);
        barTop += barHeight;
    }];
}

- (void)didPanCaptionedImageView:(UIPanGestureRecognizer *)panGR
{
    CGFloat firstBarTop = [_backgroundBarViews[0] top];
    CGFloat lastBarBottom = [[_backgroundBarViews lastObject] bottom];

    if (panGR.state == UIGestureRecognizerStateBegan || panGR.state == UIGestureRecognizerStateChanged) {
        [_topButton setTitle:nil forState:UIControlStateNormal];

        CGPoint translation = [panGR translationInView:self.view];
        CGFloat desiredTop = firstBarTop + translation.y;

        _imageView.top = MAX(firstBarTop, MIN(lastBarBottom, desiredTop));

        CGFloat percentageOfFullPull = (_imageView.top - firstBarTop) / (lastBarBottom - firstBarTop);
        _topButton.alpha = 1 - percentageOfFullPull;
        return;
    }

    if (panGR.state == UIGestureRecognizerStateEnded) {
        CGFloat percentageOfFullPull = (_imageView.top - firstBarTop) / (lastBarBottom - firstBarTop);

        if (percentageOfFullPull > 0.99) {
            // Pulled down far enough, send it.
            [self doSendAnimation];
        } else {
            [self reset];
        }

        return;
    }

    if (panGR.state == UIGestureRecognizerStateCancelled || panGR.state == UIGestureRecognizerStateFailed) {
        [self reset];
    }
}

- (void)reset
{
    [_topButton setTitle:@"back" forState:UIControlStateNormal];

    CGFloat firstBarTop = [_backgroundBarViews[0] top];

    [UIView animateWithDuration:0.4 animations:^{
        _topButton.alpha = 1;
        _imageView.top = firstBarTop;
    }];
}

- (void)doSendAnimation
{
    CGFloat firstBarTop = [_backgroundBarViews[0] top];

    [_knockButton setTitle:@"" forState:UIControlStateNormal];
    [_bottomButton setTitle:@"" forState:UIControlStateNormal];

    [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        _topButton.alpha = 0;
        _imageView.bottom = firstBarTop;
        _knockButton.alpha = 0;
        _bottomButton.alpha = 0;

        [_backgroundBarViews enumerateObjectsUsingBlock:^(UIView *barView, NSUInteger idx, BOOL *stop) {
            barView.alpha = 0;
        }];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            _imageView.bottom = -1000;
        } completion:^(BOOL finished) {
            _imageView.alpha = 0;

            [[LQAudioManager sharedManager] playEffect:kEffectKnock];

            [self bk_performBlock:^(id sender) {
                [_knockButton setTitle:@"knock" forState:UIControlStateNormal];
                _knockButton.alpha = 1;
            } afterDelay:0.2];

            [self bk_performBlock:^(id sender) {
                [_bottomButton setTitle:@"knock" forState:UIControlStateNormal];
                _bottomButton.alpha = 1;
            } afterDelay:0.4];

            [self bk_performBlock:^(id sender) {
                [self sendCollage];
            } afterDelay:1.0];
        }];
    }];
}

- (void)sendCollage
{
    [SVProgressHUD showWithStatus:@"Sending..." maskType:SVProgressHUDMaskTypeClear];

    __weak typeof(self) weakSelf = self;

    // Initiator and ≤ 3 invitees ... ≤ 4 people ... 2x2 collage.
    // Initiator and > 3 invitees ... > 4 people ... 3x3 collage.
    //
    // Note: previous VC will ensure that non-upgraded users will be unable
    // to invite more than 3 people.  That is, only those who upgrade are
    // eligible to use a 3x3 collage.

    NSInteger collageSize = _invitees.count > 3 ? 3 : 2;

    PFUser *currentUser = [PFUser currentUser];

    PFObject *collage = [PFObject objectWithClassName:@"Collage"];
    collage[@"initiator"] = currentUser;
    collage[@"invitees"] = _invitees;
    collage[@"participants"] = @[ currentUser ];
    collage[@"size"] = @(collageSize);
    collage[@"caption"] = weakSelf.caption;
    [collage saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error) {
            [SVProgressHUD dismiss];
            [error displayParseError:@"send your knock"];
            [weakSelf.navigationController popViewControllerAnimated:YES];
            return;
        }
        NSString *collageObjectID = collage.objectId;

        PFObject *collagePhoto = [PFObject objectWithClassName:@"CollagePhoto"];
        collagePhoto[@"collage"] = collage;
        collagePhoto[@"author"] = currentUser;
        collagePhoto[@"imageFile"] = [PFFile fileWithData:UIImagePNGRepresentation(weakSelf.image)];
        [collagePhoto saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (error) {
                [SVProgressHUD dismiss];
                [error displayParseError:@"send your knock"];
                [weakSelf.navigationController popViewControllerAnimated:YES];
                return;
            }

            [SVProgressHUD showSuccessWithStatus:@"Your knock has been sent!"];

            [UIView animateWithDuration:1.0 animations:^{
                weakSelf.knockButton.bottom = 0;
                weakSelf.bottomButton.top = weakSelf.view.height;
                weakSelf.knockButton.alpha = weakSelf.bottomButton.alpha = 0;
            } completion:^(BOOL finished) {
                [weakSelf.navigationController popToRootViewControllerAnimated:NO];
            }];

            [[CollageFinalizer sharedFinalizer] finalizeLater:collageObjectID];

            // This used to be done automatically in an after-save on Collage but there
            // were times when the push was received before the initiator's photo was done
            // being uploaded... Thus, now we wait.

            [PFCloud callFunctionInBackground:@"sendInvites" withParameters:@{ @"collageId": collage.objectId } block:^(id object, NSError *error) {
                if (error) {
                    [error displayParseError:@"Failed to send invites"];
                }
            }];
        }];
    }];
}

- (void)onKnockButton:(id)sender
{
    // nop
}

- (void)onTopButton:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onBottomButton:(id)sender
{
    // nop
}

@end

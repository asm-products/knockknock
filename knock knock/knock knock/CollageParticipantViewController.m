//
//  CollageParticipantViewController.m
//  Knock Knock
//
//  Created by Brian Hammond on 2/7/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import "CollageParticipantViewController.h"
#import "CaptionedImageView.h"
#import "CaptureViewController.h"
#import "BHCountdown.h"

@interface CollageParticipantViewController ()

@property (strong, nonatomic) PFObject *collage;

@property (nonatomic, strong) UIButton *tlButton;
@property (nonatomic, strong) UIButton *trButton;
@property (nonatomic, strong) UIButton *blButton;
@property (nonatomic, strong) UIButton *brButton;

@property (strong, nonatomic) CaptionedImageView *imageView;

@property (strong, nonatomic) BHCountdown *countdown;
@property (strong, nonatomic) NSString *countdownObserver;

@end

@implementation CollageParticipantViewController

- (id)initWithCollage:(PFObject *)collage
{
    self = [super init];
    if (self) {
        self.collage = collage;
    }
    return self;
}

- (void)loadView
{
    [super loadView];

    PFUser *initiator = (PFUser *)_collage[@"initiator"];

    self.tlButton = [self buttonWithText:[initiator displayName] backgroundColor:kColorPink target:self selector:@selector(onTopLeft:)];
    self.trButton = [self buttonWithText:@"" backgroundColor:kColorOrange target:self selector:@selector(onTopRight:)];
    self.blButton = [self buttonWithText:@"pass" backgroundColor:kColorBlue target:self selector:@selector(onBottomLeft:)];
    self.brButton = [self buttonWithText:@"accept" backgroundColor:kColorGreen target:self selector:@selector(onBottomRight:)];

    _tlButton.userInteractionEnabled = NO;
    _trButton.userInteractionEnabled = NO;
}

- (void)loadInitiatorImage
{
    __weak typeof(self) weakSelf = self;

    [SVProgressHUD showWithStatus:@"Loading..."];

    PFUser *initiator = (PFUser *)_collage[@"initiator"];

    PFQuery *query = [PFQuery queryWithClassName:@"CollagePhoto"];
    [query whereKey:@"author" equalTo:initiator];
    [query whereKey:@"collage" equalTo:_collage];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            [SVProgressHUD dismiss];
            [error displayParseError:@"fetch collage photo"];
            return;
        }

        if (objects.count == 0) {
            [SVProgressHUD showErrorWithStatus:@"The image is missing!"];
            DDLogError(@"no initiator photo found?!");
            return;
        }

        PFObject *collagePhoto = objects[0];
        PFFile *imageFile = collagePhoto[@"imageFile"];
        [imageFile getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
            [SVProgressHUD dismiss];
            if (!error) {
                UIImage *image = [UIImage imageWithData:imageData];
                weakSelf.imageView = [[CaptionedImageView alloc] initWithImage:image caption:weakSelf.collage[@"caption"]];
                [weakSelf.view addSubview:weakSelf.imageView];
                weakSelf.imageView.userInteractionEnabled = YES;
            }
        }];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.navigationController.navigationBarHidden = YES;

    [self loadInitiatorImage];

    self.countdown = [BHCountdown countdownWithSeconds:kParticipantTimeout];
    [self observeCountdown];
}

- (void)observeCountdown
{
    __weak typeof(self) weakSelf = self;

    self.countdownObserver = [_countdown bk_addObserverForKeyPath:@"secondsRemaining" task:^(id sender) {
        NSInteger seconds = weakSelf.countdown.secondsRemaining;
        NSString *text = [NSString stringWithFormat:@"%ds", seconds];
        [weakSelf.trButton setTitle:text forState:UIControlStateNormal];

        if (seconds == 0 && weakSelf.navigationController.topViewController == weakSelf) {
            // Didn't accept in time -- you lose your chance to join in on this collage.

            [weakSelf.trButton setTitle:@"" forState:UIControlStateNormal];
            [weakSelf.navigationController popToRootViewControllerAnimated:YES];
        }
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [_countdown bk_removeAllBlockObservers];
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
    // nop
}

- (void)onTopRight:(id)sender
{
    // nop
}

- (void)onBottomLeft:(id)sender
{
    // pass

    NSString *key = @"passedCollages";
    id passedCollages = [[[NSUserDefaults standardUserDefaults] objectForKey:key] mutableCopy];
    if (!passedCollages) passedCollages = [NSMutableSet set];
    [passedCollages addObject:_collage.objectId];
    [[NSUserDefaults standardUserDefaults] setObject:[passedCollages allObjects] forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)onBottomRight:(id)sender
{
    // accept

    CaptureViewController *vc = [CaptureViewController new];
    vc.collage = _collage;
    vc.countdown = _countdown;
    [self.navigationController pushViewController:vc animated:YES];
}

@end

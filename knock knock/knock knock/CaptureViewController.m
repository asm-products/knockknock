//
//  CaptureViewController.m
//  Knock Knock
//
//  Created by Brian Hammond on 1/28/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import "CaptureViewController.h"
#import "GPUImage.h"
#import "UIImage+Crop.h"
#import "CaptureReviewViewController.h"
#import "BHCountdown.h"

@interface CaptureViewController ()

@property (nonatomic, strong) UIButton *tlButton;
@property (nonatomic, strong) UIButton *trButton;
@property (nonatomic, strong) UIButton *blButton;
@property (nonatomic, strong) UIButton *brButton;

@property (strong, nonatomic) GPUImageView *imageView;
@property (strong, nonatomic) GPUImageStillCamera *camera;
@property (strong, nonatomic) GPUImageGammaFilter *filter;
@property (assign, nonatomic) BOOL hasFrontCamera;
@property (assign, nonatomic) AVCaptureDevicePosition cameraPosition;

@end

@implementation CaptureViewController

- (void)loadView
{
    [super loadView];

    self.tlButton = [self buttonWithText:@"cancel" backgroundColor:kColorPink target:self selector:@selector(onTopLeft:)];
    self.trButton = [self buttonWithText:@"" backgroundColor:kColorOrange target:self selector:@selector(onTopRight:)];
    self.blButton = [self buttonWithText:@"capture" backgroundColor:kColorBlue target:self selector:@selector(onBottomLeft:)];
    self.brButton = [self buttonWithText:@"front" backgroundColor:kColorGreen target:self selector:@selector(onBottomRight:)];

    // Top-right isn't really a button but I'm lazy and I already have it
    // styled the desired way as a button.

    _trButton.userInteractionEnabled = NO;

    // Default to back/rear-facing camera to allow the user to preview what
    // they will capture on the front/display.

    self.cameraPosition = AVCaptureDevicePositionBack;

    if (!_countdown && _collage) {   // Initiator has no countdown
        self.countdown = [BHCountdown countdownWithSeconds:_collage ? kParticipantTimeout : kInitiatorTimeout];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.navigationController.navigationBarHidden = YES;

    [self setupCamera];
    [self observeCountdown];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    CGFloat topOffset = TopOffset();

    [self.view layoutIfNeeded];  // give buttons a size.

    _tlButton.bottomLeft = CGPointMake(0, 0);
    _trButton.bottomRight = CGPointMake(self.view.width, 0);
    _blButton.topLeft = CGPointMake(0, self.view.height);
    _brButton.topRight = CGPointMake(self.view.width, self.view.height);

    [UIView animateWithDuration:0.3 animations:^{
        _tlButton.topLeft = CGPointMake(0, topOffset);
        _trButton.topRight = CGPointMake(self.view.width, topOffset);
        _blButton.bottomLeft = CGPointMake(0, self.view.height);
        _brButton.bottomRight = CGPointMake(self.view.width, self.view.height);
    } completion:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];


    [self teardownCamera];
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
            [weakSelf countdownDidComplete];
        }
    }];
}

- (void)countdownDidComplete
{
    DDLogInfo(@"countdown complete in capture vc");

    [_trButton setTitle:@"" forState:UIControlStateNormal];

    if (!_collage) {
        // When creating a new collage and time out, go home.

        [self.navigationController popToRootViewControllerAnimated:YES];
    } else {
        // When the user has accepted an invite (a "knock") to an existing collage,
        // and here in the capture vc they let it timeout, automatically capture
        // an image and keep going.

        [self capturePhotoAndSend:YES];
    }

    [_countdown bk_removeAllBlockObservers];
}

- (void)setupCamera
{
    self.imageView = [[GPUImageView alloc] init];
    _imageView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
    [self.view addSubview:_imageView];

    _imageView.alpha = 0;
    [UIView animateWithDuration:0.4 animations:^{
        _imageView.alpha = 1;
    }];

    self.camera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetMedium cameraPosition:_cameraPosition];
    _camera.outputImageOrientation = UIInterfaceOrientationPortrait;
    self.hasFrontCamera = self.camera.frontFacingCameraPresent;

    // We do not actually want any filters but at least one filter is required.
    // The Gamma filter with defaults is a pass-through filter.

    self.filter = [[GPUImageGammaFilter alloc] init];
    [self.camera addTarget:_filter];
    [_filter addTarget:_imageView];

    [_camera startCameraCapture];
}

- (void)teardownCamera
{
    if (_camera) {
        [_filter removeAllTargets];
        [_camera removeAllTargets];
        [_camera stopCameraCapture];

        [UIView animateWithDuration:0.4 animations:^{
            _imageView.alpha = 0;
        } completion:^(BOOL finished) {
            [_imageView removeFromSuperview];
        }];
    }
}

- (void)viewWillLayoutSubviews
{
    CGFloat topOffset = TopOffset();

    CGFloat w = self.view.width;
    CGFloat h = self.view.height;

    _imageView.width = _imageView.height = h > w ? w : MIN(h * 0.8, w);
    _imageView.center = CGPointMake(w/2, topOffset + (h - topOffset)/2);

    CGFloat remainingSpace = h - topOffset - _imageView.width;
    CGFloat buttonHeight = remainingSpace/2;

    if (buttonHeight < 0)
        return;

    _tlButton.width = _trButton.width = _blButton.width = _brButton.width = w/2;
    _tlButton.height = _trButton.height = _blButton.height = _brButton.height = buttonHeight;

//    _tlButton.topLeft = CGPointMake(0, topOffset);
//    _trButton.topRight = CGPointMake(self.view.width, topOffset);
//    _blButton.bottomLeft = CGPointMake(0, self.view.height);
//    _brButton.bottomRight = CGPointMake(self.view.width, self.view.height);
}

- (void)onTopLeft:(id)sender
{
    // Cancel

    [UIView animateWithDuration:0.3 animations:^{
        _tlButton.bottomLeft = CGPointMake(0, 0);
        _trButton.bottomRight = CGPointMake(self.view.width, 0);
        _blButton.topLeft = CGPointMake(0, self.view.height);
        _brButton.topRight = CGPointMake(self.view.width, self.view.height);
    } completion:^(BOOL finished) {
        [self.navigationController popViewControllerAnimated:NO];
    }];

}

- (void)onTopRight:(id)sender
{
    // Nothing
}

- (void)onBottomLeft:(id)sender
{
    // Capture

    [self capturePhotoAndSend:NO];
}

- (void)capturePhotoAndSend:(BOOL)doSend
{
    [_camera capturePhotoAsImageProcessedUpToFilter:_filter withCompletionHandler:^(UIImage *processedImage, NSError *error) {
        if (error) {
            DDLogError(@"%@", [error localizedDescription]);
            return;
        }

        // We have to crop to a square centered in the captured photo since the presets are not square.
        // Our orientation is portrait so let's take the width as the square size.

        DDLogInfo(@"captured image of size: %@", NSStringFromCGSize(processedImage.size));

        CGFloat croppedSize = processedImage.size.width;
        CGRect cropRect = R(0, processedImage.size.height/2 - croppedSize/2, croppedSize, croppedSize);
        UIImage *croppedImage = [processedImage crop:cropRect];

        CaptureReviewViewController *vc = [[CaptureReviewViewController alloc] initWithImage:croppedImage];
        vc.collage = _collage;
        vc.countdown = _countdown;
        [self.navigationController pushViewController:vc animated:NO];

        if (doSend) {
            [vc sendPhoto];
        }
    }];
}

- (void)onBottomRight:(id)sender
{
    // Toggle front/rear cameras if possible

    if (_hasFrontCamera) {
        if (_cameraPosition == AVCaptureDevicePositionBack) {
            _cameraPosition = AVCaptureDevicePositionFront;
            [_brButton setTitle:@"back" forState:UIControlStateNormal];
        } else {
            _cameraPosition = AVCaptureDevicePositionBack;
            [_brButton setTitle:@"front" forState:UIControlStateNormal];
        }

        [self teardownCamera];

        __weak typeof(self) weakSelf = self;

        [self bk_performBlock:^(id sender) {
            [weakSelf setupCamera];
        } afterDelay:1];
    }
}

@end

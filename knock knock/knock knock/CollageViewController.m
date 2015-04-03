//
//  CollageViewController.m
//  Knock Knock
//
//  Created by Brian Hammond on 2/7/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import "CollageViewController.h"
#import "CollageView.h"
#import "UIView+AsImage.h"
#import "MGInstagram.h"

@interface CollageViewController ()

@property (strong, nonatomic) PFObject *collage;
@property (strong, nonatomic) NSArray *collagePhotos;

@property (nonatomic, strong) UIButton *tlButton;
@property (nonatomic, strong) UIButton *trButton;
@property (nonatomic, strong) UIButton *blButton;
@property (nonatomic, strong) UIButton *brButton;

@property (nonatomic, strong) UIButton *fbButton;
@property (nonatomic, strong) UIButton *twButton;
@property (nonatomic, strong) UIButton *igButton;

@property (strong, nonatomic) CollageView *collageView;

@end

@implementation CollageViewController

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

    self.tlButton = [self buttonWithText:@"home" backgroundColor:kColorPink target:self selector:@selector(onTopLeft:)];
    self.trButton = [self buttonWithText:@"who" backgroundColor:kColorOrange target:self selector:@selector(onTopRight:)];
    self.brButton = [self buttonWithText:@"save" backgroundColor:kColorGreen target:self selector:@selector(onBottomRight:)];
    self.fbButton = [self buttonWithText:@"facebook" backgroundColor:kColorDarkBlue target:self selector:@selector(onShareFacebook:)];
    self.twButton = [self buttonWithText:@"twitter" backgroundColor:kColorBlue target:self selector:@selector(onShareTwitter:)];
    self.igButton = [self buttonWithText:@"instagram" backgroundColor:kColorGreen target:self selector:@selector(onShareInstagram:)];
    self.blButton = [self buttonWithText:@"share" backgroundColor:kColorBlue target:self selector:@selector(onBottomLeft:)];

    _fbButton.hidden = _twButton.hidden = _igButton.hidden = YES;

    self.collageView = [[CollageView alloc] initWithCollage:_collage];
    [self.view addSubview:_collageView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.navigationController.navigationBarHidden = YES;

    [self loadPhotos];
}

- (void)loadPhotos
{
    __weak typeof(self) weakSelf = self;

    [SVProgressHUD showWithStatus:@"Loading..."];

    PFQuery *query = [PFQuery queryWithClassName:@"CollagePhoto"];

    [query whereKey:@"collage" equalTo:_collage];
    [query orderByAscending:@"createdAt"];
    [query includeKey:@"author"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            [SVProgressHUD dismiss];
            [error displayParseError:@"fetch photos of collage"];
            return;
        }

        if (objects.count == 0) {
            [SVProgressHUD showErrorWithStatus:@"No photos found!"];

            [weakSelf bk_performBlock:^(id sender) {
                [weakSelf.navigationController popViewControllerAnimated:YES];
            } afterDelay:2];

            return;
        }

        [SVProgressHUD dismiss];

        weakSelf.collagePhotos = objects;
        [weakSelf.collageView setPhotos:objects];
    }];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    CGFloat w = self.view.width;
    CGFloat h = self.view.height;

    CGFloat topOffset = TopOffset();
    CGFloat collageViewSize = h > w ? w : roundf(h * 0.8);
    CGFloat remainingSpace = h - collageViewSize - topOffset;
    CGFloat buttonHeight = remainingSpace/2;

    _collageView.frame = R(w/2 - collageViewSize/2, topOffset, collageViewSize, collageViewSize);

    if (buttonHeight < 0)
        return;

    _blButton.height = _brButton.height = _tlButton.height = _trButton.height = buttonHeight;
    _blButton.width = _brButton.width = _tlButton.width = _trButton.width = collageViewSize/2;

    _blButton.bottomLeft = CGPointMake(_collageView.left, self.view.height);
    _brButton.bottomRight = CGPointMake(_collageView.right, self.view.height);
    _tlButton.bottomLeft = _blButton.topLeft;
    _trButton.bottomRight = _brButton.topRight;
}

- (void)onTopLeft:(id)sender
{
    // home

    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)onTopRight:(id)sender
{
    // who

    _collageView.showUsernames = !_collageView.showUsernames;

    UIColor *titleColor = _collageView.showUsernames ? kColorCream : [[UIColor blackColor] colorWithAlphaComponent:0.5];
    [sender setTitleColor:titleColor forState:UIControlStateNormal];
}

- (void)onBottomLeft:(id)sender
{
    // share

    if (_fbButton.hidden) {
        _fbButton.frame = _twButton.frame = _igButton.frame = _blButton.frame;
        _fbButton.hidden = _twButton.hidden = _igButton.hidden = NO;
        _fbButton.alpha = _twButton.alpha = _igButton.alpha = 0;

        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            _fbButton.frame = _tlButton.frame;
            _fbButton.alpha = 1;
        } completion:nil];

        [UIView animateWithDuration:0.3 delay:0.15 options:UIViewAnimationOptionCurveEaseOut animations:^{
            _twButton.frame = _trButton.frame;
            _twButton.alpha = 1;
        } completion:nil];

        [UIView animateWithDuration:0.3 delay:0.45 options:UIViewAnimationOptionCurveEaseOut animations:^{
            _igButton.frame = _brButton.frame;
            _igButton.alpha = 1;
        } completion:nil];

        [_blButton setTitleColor:kColorCream forState:UIControlStateNormal];
    } else {
        [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            _fbButton.frame = _twButton.frame = _igButton.frame = _blButton.frame;
            _fbButton.alpha = _twButton.alpha = _igButton.alpha = 0;
        } completion:^(BOOL finished) {
            _fbButton.hidden = _twButton.hidden = _igButton.hidden = YES;
            [_blButton setTitleColor:[[UIColor blackColor] colorWithAlphaComponent:0.5] forState:UIControlStateNormal];
        }];
    }
}

- (void)onBottomRight:(id)sender
{
    // save [to camera roll]

    UIImage *selfImage = [self.collageView asImage];
    UIImageWriteToSavedPhotosAlbum(selfImage, nil, nil, nil);

    [SVProgressHUD showSuccessWithStatus:@"Saved!"];
}

- (void)onShareFacebook:(id)sender
{
    UIImage *selfImage = [self.collageView asImage];

    if (![PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        __weak typeof(self) weakSelf = self;

        [[PFUser currentUser] linkWithFacebookBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                [weakSelf obtainFacebookPermissionsToUpload:selfImage];
            }
        }];
    } else {
        [self obtainFacebookPermissionsToUpload:selfImage];
    }
}

- (void)obtainFacebookPermissionsToUpload:(UIImage *)image
{
    if ([FBSession.activeSession.permissions indexOfObject:@"publish_actions"] == NSNotFound) {
        DDLogInfo(@"FB: no publish_actions... requesting...");

        [SVProgressHUD showWithStatus:@"Sharing..." maskType:SVProgressHUDMaskTypeClear];

        __weak typeof(self) weakSelf = self;

        [FBSession openActiveSessionWithPublishPermissions:@[@"publish_actions"] defaultAudience:FBSessionDefaultAudienceFriends allowLoginUI:YES completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
            [SVProgressHUD dismiss];
            
            if (FBSession.activeSession.isOpen && !error) {
                DDLogInfo(@"granted publish_actions...");
                [weakSelf postImageToFacebook:image];
            } else {
                DDLogInfo(@"not granted publish_actions -- user likely confused.");
                [SVProgressHUD showErrorWithStatus:@"Canceled!"];
            }
        }];
    } else {
        [self postImageToFacebook:image];
    }
}

- (void)postImageToFacebook:(UIImage *)image
{
    [SVProgressHUD showWithStatus:@"Sharing..." maskType:SVProgressHUDMaskTypeClear];

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"picture"] = image;
    if ([_collage[@"caption"] length] > 0) {
        params[@"message"] = [NSString stringWithFormat:@"I just used knockknock to create a collage with my friends: %@", _collage[@"caption"]];
    }

    FBRequest *request = [FBRequest requestWithGraphPath:@"me/photos" parameters:params HTTPMethod:@"POST"];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (error) {
            DDLogError(@"failed to upload photo to fb: %@", [error localizedDescription]);
            [SVProgressHUD showErrorWithStatus:@"Failed to share!"];
        } else {
            DDLogInfo(@"uploaded photo to fb: %@", result);
            [SVProgressHUD showSuccessWithStatus:@"Shared!"];
        }
    }];
}

- (void)onShareTwitter:(id)sender
{
    [SVProgressHUD showWithStatus:@"Sharing..." maskType:SVProgressHUDMaskTypeClear];

    UIImage *selfImage = [self.collageView asImage];

    if (![PFTwitterUtils isLinkedWithUser:[PFUser currentUser]]) {
        __weak typeof(self) weakSelf = self;

        [[PFUser currentUser] linkWithTwitterBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                [weakSelf performSelectorInBackground:@selector(postImageToTwitter:) withObject:selfImage];
//                [weakSelf postImageToTwitter:selfImage];
            }
        }];
    } else {
//        [self postImageToTwitter:selfImage];
        [self performSelectorInBackground:@selector(postImageToTwitter:) withObject:selfImage];

    }
}

- (void)postImageToTwitter:(UIImage *)image
{
    [SVProgressHUD showWithStatus:@"Sharing..." maskType:SVProgressHUDMaskTypeClear];

    // There has to be an easier way to accomplish this.

    NSURL *requestURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/update_with_media.json"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    request.HTTPMethod = @"POST";

    NSString *stringBoundary = @"---------------------------14737809831466499882746641449";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", stringBoundary];
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];

    NSMutableData *body = [NSMutableData data];

    NSString *text = [[NSString stringWithFormat:@"%@ #knockknock", ([_collage[@"caption"] length] > 0 ? [_collage[@"caption"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] : @"")] trimWhitespace];
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"status\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"%@\r\n", text] dataUsingEncoding:NSUTF8StringEncoding]];

    NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
    if (imageData) {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Disposition: form-data; name=\"media[]\"; filename=\"image.jpg\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:imageData];
        [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    }

    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];

    [request setHTTPBody:body];
    [request setURL:requestURL];

    [[PFTwitterUtils twitter] signRequest:request];

    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *data1 = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

    if (error) {
        NSString *responseBody = [[NSString alloc] initWithData:data1 encoding:NSUTF8StringEncoding];
        DDLogError(@"error posting to twitter: %@", responseBody);
        [SVProgressHUD showErrorWithStatus:@"Failed to share!"];
    } else {
        [SVProgressHUD showSuccessWithStatus:@"Shared!"];
    }
}

- (void)onShareInstagram:(id)sender
{
    if (![MGInstagram isAppInstalled]) {
        [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"Instagram", nil) message:NSLocalizedString(@"Instagram is not installed on this device.", nil) cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil handler:^(UIAlertView *alert, NSInteger buttonPressed) {}];

        return;
    }

    UIImage *selfImage = [self.collageView asImage];

    if (![MGInstagram isImageCorrectSize:selfImage]) {
        DDLogWarn(@"share to instagram -- image is too small and will be upscaled; size = %@", NSStringFromCGSize(selfImage.size));
    }

    [MGInstagram setPhotoFileName:kInstagramOnlyPhotoFileName];

    if ([_collage[@"caption"] length] > 0) {
        NSString *text = [NSString stringWithFormat:@"%@ #knockknock", _collage[@"caption"]];
        [MGInstagram postImage:selfImage withCaption:text inView:self.view];
    } else {
        [MGInstagram postImage:selfImage inView:self.view];
    }
}

@end

#import "PFUser-AppAdditions.h"

#import "AppDelegate.h"

@implementation PFUser (AppAdditions)

#pragma mark - push notifications

// Push channel names cannot start with number and objectId values can; thus, use 'u' prefix.

- (NSString *)pushChannelName
{
    return [@"u" stringByAppendingString:self.objectId];
}

- (void)subscribeToMyChannel
{
    NSString *channelName = [self pushChannelName];

    [PFPush subscribeToChannelInBackground:channelName block:^(BOOL succeeded, NSError *error) {
        if (!succeeded) {
            DDLogError(@"aps: failed to subscribe: %@", [error localizedDescription]);
        }
    }];
}

- (void)unsubscribeFromMyChannel
{
    NSString *channelName = [self pushChannelName];
    [PFPush unsubscribeFromChannelInBackground:channelName];
}

- (void)refresh
{
    __block BOOL didRefresh = NO;

    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];

    [self bk_performBlock:^(id sender) {
        if (!didRefresh) {
            [SVProgressHUD dismiss];

            dispatch_async(dispatch_get_main_queue(), ^{
                [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"Network Error", nil) message:NSLocalizedString(@"We're having trouble connecting to the server. Please retry in a little while.", nil) cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil handler:^(UIAlertView *alert, NSInteger buttonPressed) {}];

                [[NSNotificationCenter defaultCenter] postNotificationName:kLogoutNotification object:nil];
            });
        }
    } afterDelay:20];

    [[PFUser currentUser] refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        didRefresh = YES;

        [SVProgressHUD dismiss];

        if (error) {
            if (error.code == kPFErrorObjectNotFound) {     // user perhaps banned/deleted
                DDLogError(@"previously authenticated user account was deleted -- logging out");

                [PFUser logOut];

                [[NSNotificationCenter defaultCenter] postNotificationName:kLogoutNotification object:nil];
            } else {
                DDLogError(@"failed to refresh current user: %@", [error localizedDescription]);
            }
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:kUserWasRefreshedNotification object:nil userInfo:nil];
        }
    }];
}

- (NSString *)displayName
{
    // This app wants to display names in lower case ... stylish!

    NSString *displaySource = self[@"displaySource"];

    if (!displaySource) {
        if ([self[@"signupMethod"] isEqualToString:@"tw"])
            displaySource = @"tw";
        else
            displaySource = @"fb";
    }

    // Use twitter handle (e.g. "@brian")

    if ([displaySource isEqualToString:@"tw"] && [self[@"twScreenNameLC"] length] > 0) {
        return [@"@" stringByAppendingString:self[@"twScreenNameLC"]];
    }

    // Else use Full Name which we might have gotten from Facebook info.

    return self[@"fullNameLC"];
}

#pragma mark - facebook

+ (void)loginWithFacebookBlock:(PFBooleanResultBlock)block
{
    [SVProgressHUD showWithStatus:@"Logging in with Facebook" maskType:SVProgressHUDMaskTypeClear];

    [PFFacebookUtils logInWithPermissions:@[] block:^(PFUser *user, NSError *error) {
        if (error) {
            [SVProgressHUD dismiss];

            if ([[[error userInfo] objectForKey:@"com.facebook.sdk:ErrorLoginFailedReason"] isEqualToString:@"com.facebook.sdk:SystemLoginDisallowedWithoutError"]) {
                [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"Facebook Access", nil) message:NSLocalizedString(@"The device settings disallow this app from accessing Facebook.  Go to the home screen and tap on the Settings icon.  Enable the app option in the Facebook section.  Finally, return here and login via Facebook again.", nil) cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil handler:^(UIAlertView *alert, NSInteger buttonPressed) {}];
            } else {
                [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"Error", nil) message:[error localizedDescription] cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil handler:^(UIAlertView *alert, NSInteger buttonPressed) {}];
            }

            block(NO, error);
        } else {
            [user loadFacebookInfoBlock:block isLogin:YES];
        }
    }];
}

- (void)linkWithFacebookBlock:(PFBooleanResultBlock)block
{
    [SVProgressHUD showWithStatus:@"Linking with Facebook" maskType:SVProgressHUDMaskTypeClear];

    __weak typeof(self) weakSelf = self;

    [PFFacebookUtils linkUser:[PFUser currentUser] permissions:@[] block:^(BOOL succeeded, NSError *error) {
        if (error) {
            [weakSelf handleError:error];
            block(NO, error);
        } else if (succeeded) {
            [weakSelf loadFacebookInfoBlock:block isLogin:NO];
        } else {
            [SVProgressHUD dismiss];
        }
    }];
}

- (void)loadFacebookInfoBlock:(PFBooleanResultBlock)block isLogin:(BOOL)isLogin
{
    __weak typeof(self) weakSelf = self;

    [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        typeof(weakSelf) strongSelf = weakSelf;

        DDLogVerbose(@"got facebook 'me' info: %@ error: %@", result, error);

        if (error) {
            [strongSelf handleError:error];
            block(NO, error);
            return;
        }

        self[@"fbID"] = result[@"id"];

        BOOL isSignup = !self[@"signupMethod"];

        if (isSignup)
            self[@"signupMethod"] = @"fb";

        NSString *name = result[@"name"];
        NSString *profilePhotoURL = result[@"id"] ? [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", result[@"id"]] : nil;

        if (isSignup || (isLogin && [self[@"signupMethod"] isEqualToString:@"fb"])) {
            if (name.length > 0)
                strongSelf[@"fullName"] = name;
            
            if (profilePhotoURL.length > 0)
                strongSelf[@"profilePhotoURL"] = profilePhotoURL;

            [strongSelf finishSocialMediaLinkageBySaving:block isLogin:isLogin];
        } else if (!isLogin && (name.length > 0 || profilePhotoURL.length > 0)) {
            UIAlertView *alert = [UIAlertView bk_alertViewWithTitle:@"Facebook Info" message:@"Would you like to update your profile with your Facebook info?"];
            
            [alert bk_addButtonWithTitle:@"No" handler:^{
                [strongSelf finishSocialMediaLinkageBySaving:block isLogin:isLogin];
            }];
            
            [alert bk_addButtonWithTitle:@"Yes" handler:^{
                if (name.length > 0)
                    strongSelf[@"fullName"] = name;
                
                if (profilePhotoURL.length > 0)
                    strongSelf[@"profilePhotoURL"] = profilePhotoURL;

                strongSelf[@"displaySource"] = @"fb";
                
                [strongSelf finishSocialMediaLinkageBySaving:block isLogin:isLogin];
            }];

            [alert show];
        } else {
            [strongSelf finishSocialMediaLinkageBySaving:block isLogin:isLogin];
        }
    }];
}

#pragma mark - twitter

- (void)linkWithTwitterBlock:(PFBooleanResultBlock)block
{
    [SVProgressHUD showWithStatus:@"Linking with twitter" maskType:SVProgressHUDMaskTypeClear];

    __weak typeof(self) weakSelf = self;

    [PFTwitterUtils linkUser:self block:^(BOOL succeeded, NSError *error) {
        if (error) {
            [weakSelf handleError:error];
            block(NO, error);
        } else if (succeeded) {
            [weakSelf loadTwitterInfoBlock:block isLogin:NO];
        } else {
            [SVProgressHUD dismiss];
        }
    }];
}

+ (void)loginWithTwitterBlock:(PFBooleanResultBlock)block
{
    [SVProgressHUD showWithStatus:@"Logging in with twitter" maskType:SVProgressHUDMaskTypeClear];

    [PFTwitterUtils logInWithBlock:^(PFUser *user, NSError *error) {
        if (error) {
            [user handleError:error];
            block(NO, error);
        } else {
            [user loadTwitterInfoBlock:block isLogin:YES];
        }
    }];
}

- (NSString *)twitterScreenName
{
    return [PFTwitterUtils twitter].screenName;
}

- (void)makeTwitterAPICall:(NSString *)url block:(PFIdResultBlock)block
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];

    [[PFTwitterUtils twitter] signRequest:request];

    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];   // XXX Yes, synchronous.

    if (error) {
        [self handleError:error];
        block(nil, error);
        return;
    }

    error = nil;
    id dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];

    if (error) {
        [self handleError:error];
        block(nil, error);
        return;
    }

    if (dict[@"errors"]) {
        NSError *error = [NSError errorWithDomain:@"twitter" code:[dict[@"errors"][0][@"code"] integerValue] userInfo:@{ NSLocalizedDescriptionKey: dict[@"errors"][0][@"message"] }];

        [self handleError:error];

        block(nil, error);
        return;
    }

    block(dict, nil);
}

- (void)loadTwitterInfoBlock:(PFBooleanResultBlock)block isLogin:(BOOL)isLogin
{
    self[@"twID"] = [PFTwitterUtils twitter].userId;

    // If the user already signed up, they can unlink from twitter

    BOOL isSignup = !self[@"signupMethod"];

    if (isSignup)
        self[@"signupMethod"] = @"tw";

    NSString *screenName = [self twitterScreenName];

    __weak typeof(self) weakSelf = self;

    // Load profile photo URL and name (etc)

    NSString *url = [NSString stringWithFormat:@"https://api.twitter.com/1.1/users/show.json?screen_name=%@", screenName];

    [self makeTwitterAPICall:url block:^(id dict, NSError *error) {
        if (error) {
            [weakSelf handleError:error];
            block(NO, error);
            return;
        }

        typeof(weakSelf) strongSelf = weakSelf;

        strongSelf[@"twScreenName"] = screenName;
        
        // Default profile photo is only 48x48 ... Just get the large version of their profile photo.
        // See https://dev.twitter.com/docs/user-profile-images-and-banners for more info.
        
        NSString *name = [dict[@"name"] trimWhitespace];
        NSString *profilePhotoURL = [dict[@"profile_image_url"] stringByReplacingOccurrencesOfString:@"_normal" withString:@""];
        
        if (isSignup || (isLogin && [self[@"signupMethod"] isEqualToString:@"tw"])) {
            if (name.length > 0)
                strongSelf[@"fullName"] = name;
            
            if (profilePhotoURL.length > 0)
                strongSelf[@"profilePhotoURL"] = profilePhotoURL;
            
            [strongSelf finishSocialMediaLinkageBySaving:block isLogin:isLogin];
        } else if (!isLogin && (name.length > 0 || profilePhotoURL.length > 0)) {
            UIAlertView *alert = [UIAlertView bk_alertViewWithTitle:@"Twitter Info" message:@"Would you like to update your profile with your twitter info?"];
            
            [alert bk_addButtonWithTitle:@"No" handler:^{
                [strongSelf finishSocialMediaLinkageBySaving:block isLogin:isLogin];
            }];
            
            [alert bk_addButtonWithTitle:@"Yes" handler:^{
                if (name.length > 0)
                    strongSelf[@"fullName"] = name;
                
                if (profilePhotoURL.length > 0)
                    strongSelf[@"profilePhotoURL"] = profilePhotoURL;

                strongSelf[@"displaySource"] = @"tw";

                [strongSelf finishSocialMediaLinkageBySaving:block isLogin:isLogin];
            }];
            
            [alert show];
        } else {
            [strongSelf finishSocialMediaLinkageBySaving:block isLogin:isLogin];
        }
    }];
}

- (void)finishSocialMediaLinkageBySaving:(PFBooleanResultBlock)block isLogin:(BOOL)isLogin
{
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];

    __weak typeof(self) weakSelf = self;

    [self saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!succeeded) {
            [weakSelf handleError:error];
            block(NO, error);
            return;
        }
        
        DDLogInfo(@"linked with social media account");

        [SVProgressHUD showSuccessWithStatus:@"OK!"];

        if (isLogin)
            [[NSNotificationCenter defaultCenter] postNotificationName:kLoginNotification object:nil];   // technically, signup

        block(YES, nil);
    }];
}

#pragma mark - error display

- (void)handleError:(NSError *)error
{
    [SVProgressHUD dismiss];

    __weak typeof(self) weakSelf = self;

    [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"Error", nil) message:[error localizedDescription] cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil handler:^(UIAlertView *alert, NSInteger buttonPressed) {
        [PFUser logOut];
        
        if (weakSelf.isNew && weakSelf.isAuthenticated) {
            // This constitutes a failed signup attempt.

            [[NSNotificationCenter defaultCenter] postNotificationName:kLogoutNotification object:nil];
            [weakSelf deleteEventually];
        }
    }];
}

@end
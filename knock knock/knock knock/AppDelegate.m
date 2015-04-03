//
//  AppDelegate.m
//  Knock Knock
//
//  Created by Brian Hammond on 1/14/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import "AppDelegate.h"
#import "DDTTYLogger.h"
#import "AuthViewController.h"
#import "UIColor+BrighterDarker.h"
#import "BHToast.h"
#import "FriendsViewController.h"
#import "CollageViewController.h"
#import "CollageParticipantViewController.h"
#import "LQAudioManager.h"
#import "CollageFinalizer.h"
#import "CollageViewController.h"
#import "AZColoredNavigationBar.h"

NSString * const kUpgradeNotification = @"UpgradeNotification";
NSString * const kUserWasRefreshedNotification = @"UserWasRefreshedNotification";
NSString * const kSignupNotification = @"UserDidSignup";
NSString * const kLoginNotification = @"UserDidLogin";
NSString * const kLogoutNotification = @"UserDidLogout";

UIColor *kColorPink;
UIColor *kColorOrange;
UIColor *kColorGray;
UIColor *kColorGreen;
UIColor *kColorYellow;
UIColor *kColorDarkBrown;
UIColor *kColorDarkBlue;
UIColor *kColorBlue;
UIColor *kColorCream;

NSString * const kCustomFontName = @"Quicksand-Regular";

NSTimeInterval kNetworkTimeoutDuration = 30;

NSTimeInterval kCollageFinalizedDuration = 60;
NSTimeInterval kInitiatorTimeout = 60;
NSTimeInterval kParticipantTimeout = 30;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self setupTestFlight];
    [self setupCrashlytics];
    [self setupLogging];
    [self setupParseLaunchOptions:launchOptions];
    [self logAppInfo];
    [self setupAppearance];
    [self setupNotifications];
    [self setupViewController];
    [self setupPush:application launchOptions:launchOptions];
    return YES;
}

- (void)setupViewController
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = kColorDarkBrown;

    self.mainVC = [MainViewController new];

    self.navController = [[UINavigationController alloc] initWithNavigationBarClass:[AZColoredNavigationBar class] toolbarClass:[UIToolbar class]];
    _navController.viewControllers = @[ _mainVC ];
    _navController.navigationBarHidden = YES;

    self.window.rootViewController = _navController;

    [self.window makeKeyAndVisible];

    if (![PFUser currentUser]) {
        [_navController presentViewController:[AuthViewController new] animated:NO completion:nil];
    }
}

- (void)setupAppearance
{
    kColorPink = [UIColor colorWithHexString:@"FFE6E6" alpha:1];
    kColorOrange = [UIColor colorWithHexString:@"FFECC7" alpha:1];
    kColorGray = [UIColor colorWithHexString:@"DADEE6" alpha:1];
    kColorGreen = [UIColor colorWithHexString:@"D1E6C3" alpha:1];
    kColorYellow = [UIColor colorWithHexString:@"FFFDE6" alpha:1];
    kColorDarkBrown = [UIColor colorWithHexString:@"57493D" alpha:1];
    kColorDarkBlue = [UIColor colorWithHexString:@"BCBFC7" alpha:1];
    kColorBlue = [UIColor colorWithHexString:@"C5CDE2" alpha:1];
    kColorCream = [UIColor colorWithHexString:@"FFFEDD" alpha:1];

    [[SVProgressHUD appearance] setHudBackgroundColor:[[kColorDarkBrown darker] colorWithAlphaComponent:0.95]];
    [[SVProgressHUD appearance] setHudForegroundColor:kColorCream];
    [[SVProgressHUD appearance] setHudFont:[UIFont fontWithName:kCustomFontName size:floor(FontSize() * 0.8)]];
}

- (void)setupLogging
{
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
    [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor darkGrayColor] backgroundColor:nil forFlag:LOG_FLAG_VERBOSE];
    [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor cyanColor] backgroundColor:nil forFlag:LOG_FLAG_DEBUG];
    [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor lightGrayColor] backgroundColor:nil forFlag:LOG_FLAG_INFO];
    [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor yellowColor] backgroundColor:nil forFlag:LOG_FLAG_WARN];
    [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor redColor] backgroundColor:nil forFlag:LOG_FLAG_ERROR];
    [DDLog addLogger:[CrashlyticsLogger sharedInstance]];
}

- (void)setupNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didLogin:) name:kLoginNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didLogout:) name:kLogoutNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSignup:) name:kSignupNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRefreshCurrentUser:) name:kUserWasRefreshedNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupParseLaunchOptions:(NSDictionary *)launchOptions
{
    // knockknock on Parse.com under Justin Kelly's account
    [Parse setApplicationId:@"ps0JcGZd5mCXreRyqL6Swj5bAWR6pKbLXxk0hWRY" clientKey:@"gZjXNswQg5sGS1pKbgDWgLaKnme4Q7UiSFwwfbgn"];

    [PFFacebookUtils initializeFacebook];  // See FacebookAppID in info plist.
    [PFTwitterUtils initializeWithConsumerKey:@"kXVbKDnfP9a6oSxYVsRg" consumerSecret:@"wOWPz1qVKyjht40JNfm9FYJJkuNxaMfdFg6Z3lQoXUo"];
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];

#if DEBUG || ADHOC
    PFUser *currentUser = [PFUser currentUser];
    DDLogInfo(@"current user: %@", currentUser.objectId);
#endif
}

- (void)setupTestFlight
{
    [TestFlight takeOff:@"f142c274-adc8-44ae-aa24-6220c6ec6f3f"];
}

- (void)setupCrashlytics
{
    [Crashlytics startWithAPIKey:@"4f05322b39c4c444634bd2bccb82ffd74759bf6f"];
}

- (void)logAppInfo
{
#if DEBUG || ADHOC
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *name = [infoDictionary objectForKey:@"CFBundleDisplayName"];
    NSString *version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString *build = [infoDictionary objectForKey:@"CFBundleVersion"];
    NSString *label = [NSString stringWithFormat:@"%@ v%@ (build %@)", name,version,build];
    int runCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"runCount"];
    [[NSUserDefaults standardUserDefaults] setInteger:runCount+1 forKey:@"runCount"];
    DDLogInfo(@"%@; run # %d", label, runCount+1);
#endif
}

#pragma mark - push notifications

// Setup Parse with a Development Push certificate for local developer testing:
// - developer.apple.com, iOS, Member Center, App ID, configure for push
// - generate a certificate request with Keychain, upload, etc
// - download generated certificate, import into Keychain Access
// - in sidebar, pick Certificates, search for Development and select the Push Services one for the app
// - File > Export Item, .p12 file with no password
// - Parse.com dashboard, settings, push notifications, certificate
// - Add the certificate
// - Run the development build on 2 different devices
// - If you run in the Simulator, you won't receive push notifications

// When ready to distribute ad hoc and/or app store builds:
// - [same as above to download, import, export push certificate but here for production]
// - Parse.com dashboard, settings, push notifications, certificate
// - Delete the existing dev push certificate (assuming you don't have a paid Parse account)
// - Add the production push certificate in its place
// - Distribute your Ad Hoc and/or App Store builds (release builds)

// Parse paid accounts allow *multiple* push certificates (dev and prod).
// It'll figure out which to use based on the build type.

// In the app:
// - Your app will handle the push when not running by calling handleInboundPush:launched: with YES.
//   Called from setupPush:launchOptions:
// - While running, the app will receive the push via application:didReceiveRemoteNotification:
//   which called handleInboundPush:launched: with NO

// To test manually for development (where logging is enabled):
// - Run the app on a device
// - On Parse.com, go to Push Notifications tab for the app
// - Send out a push notification on the "" channel (global broadcast)
// - View the device logs and see the push notification as it arrives (see handleInboundPush: below)

- (void)setupPush:(UIApplication *)application launchOptions:(NSDictionary *)launchOptions
{
    [application registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeSound)];

    NSDictionary *pushInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];

    if (pushInfo && [PFUser currentUser]) {
        [self bk_performBlock:^(id sender) {
            [self handleInboundPush:pushInfo launched:YES];
        } afterDelay:2];    // Let the app settle down a bit.
    }
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)token
{
    [PFPush storeDeviceToken:token];

    if ([PFUser currentUser]) {
        [[PFUser currentUser] refresh];
    } else {
        [self setupForCurrentUser];
    }
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    if ([error code] != 3010) {   // Known issue: push doesnt work in ios simulator.
        DDLogError(@"didFailToRegisterForRemoteNotificationsWithError: %@", error);

        [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"Oops", nil) message:NSLocalizedString(@"Please enable notifications for the best experience. Launch the Settings app. Select Notification Center. Select knockknock. Finally, select either Banners or Alerts. Thanks!", nil) cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil handler:^(UIAlertView *alert, NSInteger buttonPressed) {
            exit(0);  // This app does not work without push notifications enabled.
         }];
    } else {
        if ([PFUser currentUser]) {
            [[PFUser currentUser] refresh];
        } else {
            [self setupForCurrentUser];
        }
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    UIApplicationState state = [UIApplication sharedApplication].applicationState;
    BOOL launched = (state == UIApplicationStateBackground || state == UIApplicationStateInactive);
    [self handleInboundPush:userInfo launched:launched];
}

- (void)loadCollageByID:(NSString *)collageObjectID block:(PFObjectResultBlock)block
{
    [SVProgressHUD showWithStatus:@"Loading..."];

    PFQuery *query = [PFQuery queryWithClassName:@"Collage"];
    [query whereKey:@"objectId" equalTo:collageObjectID];

    // Cannot already be completed. Can happen when user opens an older notification in Notification Center.

    [query whereKeyDoesNotExist:@"completedAt"];

    // If the user opens an older notification in Notification Center
    // for a collage whose creation they were a participant, deny!

    [query whereKey:@"participants" notEqualTo:[PFUser currentUser]];

    [query includeKey:@"initiator"];

    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            [error displayParseError:@"fetch collage"];
            return;
        }

        if (objects.count == 0) {
            [SVProgressHUD showErrorWithStatus:@"Expired"];    // Catch-all language.
            return;
        }


        PFObject *collage = objects[0];

        // Loading a notification again for a collage that the user already passed on is illegal.

        NSString *key = @"passedCollages";
        id passedCollages = [[NSUserDefaults standardUserDefaults] objectForKey:key];
        if (passedCollages) {
            passedCollages = [NSSet setWithArray:passedCollages];
            if ([passedCollages containsObject:collage.objectId]) {
                [SVProgressHUD showErrorWithStatus:@"Already Passed"];
                return;
            }
        }

        [SVProgressHUD dismiss];

        block(collage, nil);
    }];
}

- (void)handleInboundPush:(NSDictionary *)userInfo launched:(BOOL)launched
{
    DDLogInfo(@"push received: %@ launched: %d", userInfo, launched);

    __weak typeof(self) weakSelf = self;

    NSString *pushType = userInfo[@"type"];

    if ([pushType isEqualToString:@"knockComplete"]) {
        NSInteger unseenCount = [_mainVC.unseenCompletedCollagesBadge.text integerValue];
        _mainVC.unseenCompletedCollagesBadge.text = [NSString stringWithFormat:@"%d", unseenCount + 1];
        _mainVC.unseenCompletedCollagesBadge.hidden = NO;

        NSString *collageID = userInfo[@"collageID"];
        [BHToast sharedToast].tapBlock = ^{
            DDLogInfo(@"user tapped toast to view collage %@", collageID);

            [weakSelf loadCollageByID:userInfo[@"collageID"] block:^(PFObject *collage, NSError *error) {
                if (!error) {
                    [weakSelf.navController pushViewController:[[CollageViewController alloc] initWithCollage:collage] animated:YES];

                }
            }];
        };
    } else if ([pushType isEqualToString:@"friendRequest"]) {
        NSInteger reqCount = [_mainVC.friendRequestsBadge.text integerValue];
        _mainVC.friendRequestsBadge.text = [NSString stringWithFormat:@"%d", reqCount + 1];
        _mainVC.friendRequestsBadge.hidden = NO;

        [BHToast sharedToast].tapBlock = ^{
            [weakSelf.navController pushViewController:[FriendsViewController new] animated:YES];

            weakSelf.mainVC.friendRequestsBadge.text = @"";
            weakSelf.mainVC.friendRequestsBadge.hidden = YES;
        };
    } else if ([pushType isEqualToString:@"invite"]) {     // This is the result of sending a "knock"
        void(^block)() = ^{
            [weakSelf loadCollageByID:userInfo[@"collageID"] block:^(PFObject *collage, NSError *error) {
                if (!error) {
                    [weakSelf.navController popToRootViewControllerAnimated:NO];
                    [weakSelf.navController pushViewController:[[CollageParticipantViewController alloc] initWithCollage:collage] animated:YES];
                }
            }];
        };

        if (launched) {
            block();
            return;
        }

        [[LQAudioManager sharedManager] playEffect:kEffectKnock];
        [BHToast sharedToast].tapBlock = block;
    } else {
        return;
    }

    [BHToast sharedToast].message = [userInfo valueForKeyPath:@"aps.alert"];
    [BHToast sharedToast].toastType = BHToastTypePlain;
    [BHToast sharedToast].hidden = NO;
    [self bk_performBlock:^(id sender) {
        [BHToast sharedToast].hidden = YES;
        [BHToast sharedToast].tapBlock = nil;
    } afterDelay:8];
}

- (void)setupPushChannelSubscriptions
{
    [PFPush getSubscribedChannelsInBackgroundWithBlock:^(NSSet *channels, NSError *error) {
        if (error) {
            DDLogError(@"failed to get subscribed channels: %@", [error localizedDescription]);
            [PFPush subscribeToChannelInBackground:@""];  // global broadcasts
            return;
        }

        for (NSString *existingChannel in channels) {
            [PFPush unsubscribeFromChannelInBackground:existingChannel];
        }

        [PFPush subscribeToChannelInBackground:@""];  // global broadcasts

        if ([PFUser currentUser]) {
            [[PFUser currentUser] subscribeToMyChannel];
        }
    }];
}

#pragma mark - notifications about the current user

- (void)setupForCurrentUser
{
    if ([PFUser currentUser]) {
        [TestFlight addCustomEnvironmentInformation:[PFUser currentUser].objectId forKey:@"userID"];
        [[Crashlytics sharedInstance] setUserName:[PFUser currentUser].objectId];

        [self setupPushChannelSubscriptions];

        [PFPurchase addObserverForProduct:@"upgrade" block:^(SKPaymentTransaction *transaction) {
            [PFUser currentUser][@"hasUpgraded"] = [NSNumber numberWithBool:YES];
            [[PFUser currentUser] saveEventually];
        }];

        // Kick off any collage finalizations that might need to be done if the app
        // was shutdown before we could finalize (after local collage initiation).

        (void)[CollageFinalizer sharedFinalizer];
    } else {
        [TestFlight addCustomEnvironmentInformation:@"" forKey:@"userID"];
        [[Crashlytics sharedInstance] setUserName:@""];
    }

    [self clearBadge];
}

- (void)didRefreshCurrentUser:(NSNotification *)notification
{
    DDLogInfo(@"refreshed current user %@", [PFUser currentUser].objectId);
    [self setupForCurrentUser];
}

- (void)didLogin:(NSNotification *)notification
{
    [_navController dismissViewControllerAnimated:YES completion:nil];
    [self setupForCurrentUser];
}

- (void)didLogout:(NSNotification *)notification
{
    [_navController dismissViewControllerAnimated:NO completion:nil];
    [_navController popToRootViewControllerAnimated:YES];
    [_navController presentViewController:[AuthViewController new] animated:YES completion:nil];
    [self setupForCurrentUser];
}

- (void)didSignup:(NSNotification *)notification
{
    [_navController dismissViewControllerAnimated:YES completion:nil];
    [self setupForCurrentUser];
}

#pragma mark - util

- (void)clearBadge
{
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;

    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    currentInstallation.badge = 0;
    [currentInstallation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error) {
            [currentInstallation saveEventually];
        }
    }];
}

#pragma mark - facebook

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication withSession:[PFFacebookUtils session]];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [self clearBadge];
    [FBAppCall handleDidBecomeActiveWithSession:[PFFacebookUtils session]];
}

@end

//
//  SettingsViewController.m
//  Knock Knock
//
//  Created by Brian Hammond on 2/11/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import "SettingsViewController.h"

@interface SettingsTableCell : UITableViewCell

@end

@implementation SettingsTableCell

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.contentView.frame = CGRectInset(self.bounds, 10 * IdiomScale(), 5 * IdiomScale());
    self.textLabel.top = 0;
    self.textLabel.height = self.contentView.height;
    self.imageView.top = self.contentView.height/2 - self.imageView.image.size.height/2;
}

@end

@interface SettingsViewController ()

@end

@implementation SettingsViewController

- (id)init
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.accentColor = kColorBlue;
        self.title = @"settings";
    }
    return self;
}

#pragma mark - table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[PFUser currentUser][@"hasUpgraded"] boolValue] ? 3 : 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([[PFUser currentUser][@"hasUpgraded"] boolValue]) {
        switch (section) {
            case 0: return 2; // accounts
            case 1: return 3; // notifications
            case 2: return 4; // support
        }
    } else {
        switch (section) {
            case 0: return 1; // upgrade
            case 1: return 2; // accounts
            case 2: return 3; // notifications
            case 3: return 4; // support
        }
    }

    return 0;
}

- (float)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40 * IdiomScale();
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *text;

    if ([[PFUser currentUser][@"hasUpgraded"] boolValue]) {
        switch (section) {
            case 0: text = @"accounts"; break;
            case 1: text = @"notifications"; break;
            case 2: text = @"support"; break;
        }
    } else {
        switch (section) {
            case 0: text = @"upgrade"; break;
            case 1: text = @"accounts"; break;
            case 2: text = @"notifications"; break;
            case 3: text = @"support"; break;
        }
    }

    CGFloat height = [self tableView:self.tableView heightForHeaderInSection:0];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20 * IdiomScale(), 0, self.view.width - 40 * IdiomScale(), height)];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont fontWithName:kCustomFontName size:FontSize()*0.8];
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = 0.25;
    label.textColor = kColorCream;
    label.text = text;
    [self.view addSubview:label];

    UIView *wrapper = [[UIView alloc] initWithFrame:R(0,0,self.view.width,0)];
    wrapper.backgroundColor = self.view.backgroundColor;
    [wrapper addSubview:label];

    return wrapper;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60 * IdiomScale();
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"cell";

    SettingsTableCell *cell = (SettingsTableCell *)[tableView dequeueReusableCellWithIdentifier:identifier];

    if (!cell) {
        cell = [[SettingsTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.textLabel.font = [UIFont fontWithName:kCustomFontName size:FontSize()*0.8];
        cell.textLabel.textColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        cell.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;    // make it look like they are tapping a button
    }

    NSString *text;
    UIColor *backgroundColor;
    UIImage *icon;
    BOOL isBoolSetting = NO;
    BOOL boolValue;
    BOOL isEnabled = YES;
    NSTextAlignment textAlignment = NSTextAlignmentLeft;

    int upgradeSection = 0, accountsSection = 1, notificationsSection = 2, supportSection = 3;

    if ([[PFUser currentUser][@"hasUpgraded"] boolValue]) {
        upgradeSection = -1;
        accountsSection = 0;
        notificationsSection = 1;
        supportSection = 2;
    }

    if (indexPath.section == upgradeSection) {
        text = @"invite up to 8 friends";
        backgroundColor = kColorCream;
        textAlignment = NSTextAlignmentCenter;
    } else if (indexPath.section == accountsSection) {
        NIKFontAwesomeIconFactory *factory = [NIKFontAwesomeIconFactory buttonIconFactory];
        factory.size = 38; // use even number
        factory.colors = @[ [[UIColor blackColor] colorWithAlphaComponent:0.5] ];

        switch (indexPath.row) {
            case 0:
                isEnabled = ![[PFUser currentUser][@"signupMethod"] isEqualToString:@"fb"];
                backgroundColor = kColorDarkBlue;
                icon = [factory createImageForIcon:NIKFontAwesomeIconFacebookSquare];
                isBoolSetting = YES;
                boolValue = [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]];
                text = @"facebook";
                break;

            case 1:
                isEnabled = ![[PFUser currentUser][@"signupMethod"] isEqualToString:@"tw"];
                backgroundColor = kColorBlue;
                icon = [factory createImageForIcon:NIKFontAwesomeIconTwitterSquare];
                isBoolSetting = YES;
                boolValue = [PFTwitterUtils isLinkedWithUser:[PFUser currentUser]];
                text = @"twitter";
                break;
        }
    } else if (indexPath.section == notificationsSection) {
        backgroundColor = kColorGreen;

        switch (indexPath.row) {
            case 0:
                text = @"receive a knock";
                isBoolSetting = YES;
                boolValue = [[PFUser currentUser][@"pushReceiveKnock"] boolValue];
                break;
            case 1:
                text = @"collage complete";
                isBoolSetting = YES;
                boolValue = [[PFUser currentUser][@"pushCollageComplete"] boolValue];
                break;
            case 2:
                text = @"friend requests";
                isBoolSetting = YES;
                boolValue = [[PFUser currentUser][@"pushFriendRequests"] boolValue];
                break;
        }
    } else if (indexPath.section == supportSection) {
        backgroundColor = kColorPink;
        textAlignment = NSTextAlignmentCenter;

        switch (indexPath.row) {
            case 0:
                text = @"tutorial";
                break;
            case 1:
                text = @"feedback";
                break;
            case 2:
                text = @"terms of service";
                break;
            case 3:
                text = @"privacy policy";
                break;
        }
    }

    cell.imageView.image = icon;
    cell.textLabel.textAlignment = textAlignment;
    cell.textLabel.text = text;
    cell.contentView.backgroundColor = backgroundColor;
    cell.accessoryView = nil;

    if (isBoolSetting) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = boolValue ? kColorCream : [[UIColor blackColor] colorWithAlphaComponent:0.5];
        label.text = boolValue ? @"ON" : @"OFF";
        label.font = [UIFont boldSystemFontOfSize:FontSize()];
        [label sizeToFit];
        label.width += 20 * IdiomScale();
        cell.accessoryView = label;
    }

    // TODO no RECEIVE section at this time.

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    int upgradeSection = 0, accountsSection = 1, notificationsSection = 2, supportSection = 3;

    if ([[PFUser currentUser][@"hasUpgraded"] boolValue]) {
        upgradeSection = -1;
        accountsSection = 0;
        notificationsSection = 1;
        supportSection = 2;
    }

    if (indexPath.section == upgradeSection) {
        [PFPurchase buyProduct:@"upgrade" block:^(NSError *error) {
            if (error) {
                DDLogError(@"IAP error: %@", [error localizedDescription]);

#if DEBUG || ADHOC
                [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"We encountered an error trying to upgrade. Please try again later.\n\nSince this is an internal build: please go check that you set IAP up for the app on itunesconnect.apple.com", nil) cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil handler:^(UIAlertView *alert, NSInteger buttonPressed) {}];
#else
                [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"We encountered an error trying to upgrade. Please try again later.", nil) cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil handler:^(UIAlertView *alert, NSInteger buttonPressed) {}];
#endif
            } else {
                [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"Upgrade", nil) message:NSLocalizedString(@"Thanks for upgrading!", nil) cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil handler:^(UIAlertView *alert, NSInteger buttonPressed) {}];

                [PFUser currentUser][@"hasUpgraded"] = [NSNumber numberWithBool:YES];
                [[PFUser currentUser] saveEventually];
            }
        }];
    } else if (indexPath.section == accountsSection) {
        switch (indexPath.row) {
            case 0:
                if ([[PFUser currentUser][@"signupMethod"] isEqualToString:@"fb"]) {
                    [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"Sorry", nil) message:NSLocalizedString(@"You signed up via Facebook and thus cannot unlink it without deleting your account here.", nil) cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil handler:^(UIAlertView *alert, NSInteger buttonPressed) {}];

                    return;
                }

                if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
                    [PFFacebookUtils unlinkUser:[PFUser currentUser]];
                    [self.tableView reloadData];
                } else {
                    __weak typeof(self) weakSelf = self;
                    [[PFUser currentUser] linkWithFacebookBlock:^(BOOL succeeded, NSError *error) {
                        [weakSelf.tableView reloadData];
                    }];
                }

                break;

            case 1:
                if ([[PFUser currentUser][@"signupMethod"] isEqualToString:@"tw"]) {
                    [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"Sorry", nil) message:NSLocalizedString(@"You signed up via twitter and thus cannot unlink it without deleting your account here.", nil) cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil handler:^(UIAlertView *alert, NSInteger buttonPressed) {}];

                    return;
                }

                if ([PFTwitterUtils isLinkedWithUser:[PFUser currentUser]]) {
                    [PFTwitterUtils unlinkUser:[PFUser currentUser]];
                    [self.tableView reloadData];
                } else {
                    __weak typeof(self) weakSelf = self;
                    [[PFUser currentUser] linkWithTwitterBlock:^(BOOL succeeded, NSError *error) {
                        [weakSelf.tableView reloadData];
                    }];
                }

                break;
        }
    } else if (indexPath.section == notificationsSection) {
        switch (indexPath.row) {
            case 0:
                [PFUser currentUser][@"pushReceiveKnock"] = [NSNumber numberWithBool:![[PFUser currentUser][@"pushReceiveKnock"] boolValue]];
                break;

            case 1:
                [PFUser currentUser][@"pushCollageComplete"] = [NSNumber numberWithBool:![[PFUser currentUser][@"pushCollageComplete"] boolValue]];
                break;

            case 2:
                [PFUser currentUser][@"pushFriendRequests"] = [NSNumber numberWithBool:![[PFUser currentUser][@"pushFriendRequests"] boolValue]];
                break;

            default:
                break;
        }

        [[PFUser currentUser] saveEventually];
        [self.tableView reloadData];
    } else if (indexPath.section == supportSection) {
        switch (indexPath.row) {
            case 0:
                [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"Tutorial", nil) message:NSLocalizedString(@"Find your friends, send them a knock, wait a minute, see the final collage.", nil) cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil handler:^(UIAlertView *alert, NSInteger buttonPressed) {}];

                break;

            case 1:
                [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"Feedback", nil) message:NSLocalizedString(@"...", nil) cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil handler:^(UIAlertView *alert, NSInteger buttonPressed) {}];

                break;

            case 2:
                [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"Terms of Service", nil) message:NSLocalizedString(@"Don't hack us", nil) cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil handler:^(UIAlertView *alert, NSInteger buttonPressed) {}];

                break;

            case 3:
                [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"Privacy Policy", nil) message:NSLocalizedString(@"We don't sell your info.", nil) cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil handler:^(UIAlertView *alert, NSInteger buttonPressed) {}];

                break;

            default:
                break;
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // In case Facebook got linked in the browser and the user is returned to the app.

    [self.tableView reloadData];

    self.navigationController.navigationBarHidden = NO;
}

- (void)setupSearch
{
    // no search, thanks
}

@end

//
//  FriendFinder.m
//  Knock Knock
//
//  Created by Brian Hammond on 2/7/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import "FriendFinder.h"

@interface FriendFinder ()

@property (nonatomic, copy, readwrite) NSArray *friends;
@property (nonatomic, copy, readwrite) NSArray *facebookFriendsWithApp;
@property (nonatomic, copy, readwrite) NSArray *twitterFriendsWithApp;

@end

@implementation FriendFinder

- (void)loadFriends:(PFBooleanResultBlock)block
{
    [SVProgressHUD showWithStatus:@"Loading Friends ..." maskType:SVProgressHUDMaskTypeClear];

    __weak typeof(self) weakSelf = self;

    PFQuery *query = [[[PFUser currentUser] relationForKey:@"friends"] query];
    query.limit = 1000;
    [query orderByDescending:@"createdAt"];   // newest on top
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        [SVProgressHUD dismiss];

        if (error) {
            [error displayParseError:@"load your friends"];
            weakSelf.friends = nil;
            block(NO, error);
        } else {
            weakSelf.friends = objects;
            block(YES, nil);
        }
    }];
}

- (void)findFacebookFriendsWithTheApp:(PFBooleanResultBlock)block
{
    [SVProgressHUD showWithStatus:@"Loading Facebook friends" maskType:SVProgressHUDMaskTypeClear];

    __weak typeof(self) weakSelf = self;

    FBRequest *request = [FBRequest requestForMyFriends];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        [SVProgressHUD dismiss];

        if (error) {
            [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"Error", nil) message:[NSString stringWithFormat:@"Failed to fetch Facebook friends.\n\n%@", [error localizedDescription]] cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil handler:^(UIAlertView *alert, NSInteger buttonPressed) {}];

            return;
        }

        // Extract fb user ids and then remove those that match any of the user's existing friends.
        // We are showing the user those which they may friend-request after all.

        NSMutableArray *fbIDs = [[(NSArray *)[result valueForKeyPath:@"data.id"] bk_select:^BOOL(NSString *fbID) {
            return [[weakSelf.friends bk_select:^BOOL(PFUser *friend) {
                return [friend[@"fbID"] isEqualToString:fbID];
            }] count] == 0;
        }] mutableCopy];

        if (fbIDs.count == 0) {
            [SVProgressHUD showErrorWithStatus:@"No eligible friends from Facebook were found."];
            weakSelf.facebookFriendsWithApp = nil;
            block(YES, nil);
            return;
        }

        NSInteger initialFacebookFriendsCount = fbIDs.count;

        NSMutableArray *usersWithTheApp = [NSMutableArray array];

        [weakSelf findSocialMediaUsersWithTheAppInstalled:fbIDs socialMediaUserIDKey:@"fbID" into:usersWithTheApp completion:^{
            DDLogInfo(@"found %d users with the app installed from %d facebook friends",
                      usersWithTheApp.count, initialFacebookFriendsCount);
            
            if (usersWithTheApp.count == 0) {
                [SVProgressHUD showErrorWithStatus:@"No eligible friends from Facebook were found."];
                weakSelf.facebookFriendsWithApp = nil;
            } else {
                weakSelf.facebookFriendsWithApp = usersWithTheApp;
            }
            
            block(YES, nil);
         }];
    }];

}

- (void)findTwitterFriendsWithTheApp:(PFBooleanResultBlock)block
{
    [SVProgressHUD showWithStatus:@"Finding twitter friends" maskType:SVProgressHUDMaskTypeClear];

    __weak typeof(self) weakSelf = self;

    NSString *url = [NSString stringWithFormat:@"https://api.twitter.com/1.1/friends/ids.json"];

    // NB: as per https://dev.twitter.com/docs/api/1.1/get/friends/ids
    // this will return at most 5000 twitter followings/friends in most-recently-followed-first order.

    [[PFUser currentUser] makeTwitterAPICall:url block:^(id result, NSError *error) {
        if (!error) {
            DDLogError(@"twitter friends: %@", result);

            NSArray *numericTwitterIDs = (NSArray *)[result valueForKeyPath:@"ids"];

            NSMutableArray *twIDs = [[[numericTwitterIDs bk_map:^id(NSNumber *twitterID) {
                return [twitterID stringValue];
            }] bk_select:^BOOL(NSString *twID) {
                return [[_friends bk_select:^BOOL(PFUser *friend) {
                    return [friend[@"twID"] isEqualToString:twID];
                }] count] == 0;
            }] mutableCopy];

            if (twIDs.count == 0) {
                [SVProgressHUD showErrorWithStatus:@"No eligible friends from twitter were found."];
                weakSelf.twitterFriendsWithApp = nil;
                block(YES, nil);
                return;
            }

            NSInteger initialTwitterFriendsCount = twIDs.count;

            NSMutableArray *usersWithTheApp = [NSMutableArray array];

            [weakSelf findSocialMediaUsersWithTheAppInstalled:twIDs socialMediaUserIDKey:@"twID" into:usersWithTheApp completion:^{
                [SVProgressHUD dismiss];

                DDLogInfo(@"found %d users with the app installed from %d twitter friends", usersWithTheApp.count, initialTwitterFriendsCount);

                if (usersWithTheApp.count == 0) {
                    [SVProgressHUD showErrorWithStatus:@"No eligible friends from twitter were found."];
                    weakSelf.twitterFriendsWithApp = nil;
                } else {
                    weakSelf.twitterFriendsWithApp = usersWithTheApp;
                }

                block(YES, nil);
            }];
        }
    }];
}

- (void)findSocialMediaUsersWithTheAppInstalled:(NSMutableArray *)socialMediaUserIDs socialMediaUserIDKey:(NSString *)socialMediaUserIDKey into:(NSMutableArray *)usersWithTheApp completion:(void (^)(void))completionBlock
{
    if (socialMediaUserIDs.count == 0) {
        completionBlock();
        return;
    }

    if (usersWithTheApp.count == 0) {
        [SVProgressHUD showWithStatus:@"Finding your friends" maskType:SVProgressHUDMaskTypeClear];
    } else {
        NSString *statusMessage = [NSString stringWithFormat:@"Finding for your friends (%d to go, found %d so far).", socialMediaUserIDs.count, usersWithTheApp.count];
        [SVProgressHUD showWithStatus:statusMessage];
    }

    // Parse staff say that performance of containedIn with > 500 elements is severely degraded.
    // Thus, we should repeat the same query but with 500 objects at a time until we work through them all.

    NSInteger remainingCount = socialMediaUserIDs.count;
    NSInteger toQuery = MIN(remainingCount, 500);
    NSRange range = NSMakeRange(0, toQuery);
    NSArray *idsToQuery = [socialMediaUserIDs subarrayWithRange:range];
    [socialMediaUserIDs removeObjectsInRange:range];

    __weak typeof(self) weakSelf = self;

    PFQuery *query = [PFUser query];
    query.limit = idsToQuery.count;

    [query whereKey:socialMediaUserIDKey containedIn:idsToQuery];

    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            [error displayParseError:@"finding your friends"];
            completionBlock();
            return;
        }

        if (objects.count == 0) {
            completionBlock();
            return;
        }

        [usersWithTheApp addObjectsFromArray:objects];

        [weakSelf findSocialMediaUsersWithTheAppInstalled:socialMediaUserIDs socialMediaUserIDKey:socialMediaUserIDKey into:usersWithTheApp completion:completionBlock];
    }];
}

@end

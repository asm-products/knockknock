//
//  FriendFinder.h
//  Knock Knock
//
//  Created by Brian Hammond on 2/7/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import <Foundation/Foundation.h>

// Helpers for common friend/user relationship management patterns.
// _User: fbID (String), twID (String), friends (relation to _User)

@interface FriendFinder : NSObject

// Other users with which the current user has an established friendship relationship.
- (void)loadFriends:(PFBooleanResultBlock)block;
@property (nonatomic, copy, readonly) NSArray *friends;

// Other users that the current user is friends with on Facebook but not in the app.
- (void)findFacebookFriendsWithTheApp:(PFBooleanResultBlock)block;
@property (nonatomic, copy, readonly) NSArray *facebookFriendsWithApp;

// Other users that the current user follows on Twitter but is not friends with in the app.
- (void)findTwitterFriendsWithTheApp:(PFBooleanResultBlock)block;  // AKA followings
@property (nonatomic, copy, readonly) NSArray *twitterFriendsWithApp;

@end

//
//  UserProfileImageListView.h
//  Knock Knock
//
//  Created by Brian Hammond on 2/7/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UserProfileImageListView;

@protocol UserProfileImageListViewDelegate <NSObject>

- (void)didTapUser:(PFUser *)user inProfileImageListView:(UserProfileImageListView *)profileImageListView;

@end

@interface UserProfileImageListView : UIView

- (void)addUser:(PFUser *)user;
- (void)removeUser:(PFUser *)user;

@property (assign, nonatomic) CGFloat preferredImageDiameter;
@property (weak, nonatomic) id<UserProfileImageListViewDelegate> delegate;

@end

//
//  FriendTableViewCell.h
//  Knock Knock
//
//  Created by Brian Hammond on 1/29/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BHRevealTableViewCell.h"

@interface FriendTableViewCell : BHRevealTableViewCell

@property (assign, nonatomic) BOOL useCircularImageView;
@property (copy, nonatomic) NSIndexPath *indexPath;
@property (strong, nonatomic) UIImageView *rightImageView;    // Cannot use accessoryView as its not in contentView and we need to be able to swipe left.

- (void)usePlusForRightImage;
- (void)useCheckForRightImage;

@end

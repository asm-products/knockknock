//
//  CollageInvitesViewController.h
//  Knock Knock
//
//  Created by Brian Hammond on 2/6/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import "BaseTableViewController.h"

enum
{
    CollageInvitesViewControllerModeFriends,
    CollageInvitesViewControllerFollowings
};

@interface CollageInvitesViewController : BaseTableViewController

- (id)initWithImage:(UIImage *)image caption:(NSString *)caption invitees:(NSArray *)invitees mode:(NSInteger)mode;

@end

//
//  FriendsViewController.m
//  Knock Knock
//
//  Created by Brian Hammond on 1/29/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import "FriendsViewController.h"
#import "BHRevealTableViewCell.h"
#import "FriendRequestViewController.h"
#import "FriendTableViewCell.h"
#import "FriendFinder.h"

enum
{
    SectionFriendRequests,
    SectionFriends,
    SectionFindFriends   // if this changes, update the numberOfSections since it assumes its last.
};

enum
{
    FindFriendsByFacebook,
    FindFriendsByTwitter
};

@interface FindFriendsTableCell : UITableViewCell

@end

@implementation FindFriendsTableCell

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.contentView.frame = CGRectInset(self.bounds, 10 * IdiomScale(), 5 * IdiomScale());
    self.textLabel.top = 0;
    self.textLabel.height = self.contentView.height;
    self.imageView.top = self.contentView.height/2 - self.imageView.image.size.height/2;
}

@end

@interface FriendsViewController () <BHRevealTableViewCellDelegate>

@property (nonatomic, strong) NSMutableArray *friendRequests;
@property (strong, nonatomic) NSArray *friendRequestMatches;
@property (nonatomic, strong) NSMutableArray *friends;
@property (strong, nonatomic) NSArray *friendMatches;
@property (nonatomic, strong) FriendFinder *friendFinder;

@end

@implementation FriendsViewController

- (id)init
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.accentColor = kColorGreen;
        self.title = @"friends";

        self.friendFinder = [FriendFinder new];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self findFriendRequests];
}

#pragma mark - load remote data

- (void)findFriendRequests
{
    [SVProgressHUD showWithStatus:@"Loading Friend Requests ..." maskType:SVProgressHUDMaskTypeClear];

    __weak typeof(self) weakSelf = self;

    PFQuery *query = [PFQuery queryWithClassName:@"FriendRequest"];
    [query whereKey:@"targetUser" equalTo:[PFUser currentUser]];
    query.limit = 1000;
    [query includeKey:@"sourceUser"];
    [query orderByDescending:@"createdAt"];   // newest on top
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        [SVProgressHUD dismiss];

        FriendsViewController *strongSelf = weakSelf;

        if (error) {
            [error displayParseError:@"load friend requests"];
            strongSelf.friendRequests = nil;
        } else {
            strongSelf.friendRequests = [objects mutableCopy];
        }

        [strongSelf.tableView reloadData];
        [strongSelf loadFriends];
    }];
}

- (void)loadFriends
{
    __weak typeof(self) weakSelf = self;

    [_friendFinder loadFriends:^(BOOL succeeded, NSError *error) {
        FriendsViewController *strongSelf = weakSelf;

        if (succeeded) {
            strongSelf.friends = [strongSelf.friendFinder.friends mutableCopy];
        } else {
            strongSelf.friends = nil;
        }

        [strongSelf.tableView reloadData];
    }];
}

- (void)updateMatchesForSearchString:(NSString *)searchString
{
    self.friendRequestMatches = [_friendRequests bk_select:^BOOL(PFObject *friendRequest) {
        PFUser *requestor = friendRequest[@"sourceUser"];
        return [[[requestor displayName] lowercaseString] rangeOfString:[searchString lowercaseString]].location != NSNotFound;
    }];

    self.friendMatches = [_friends bk_select:^BOOL(PFUser *friend) {
        return [[[friend displayName] lowercaseString] rangeOfString:[searchString lowercaseString]].location != NSNotFound;
    }];
}

#pragma mark - table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return (tableView == self.tableView) ? 3 : 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case SectionFriendRequests: {
            int N = (tableView == self.tableView) ? _friendRequests.count : _friendRequestMatches.count;
            return N;
        }

        case SectionFindFriends:
            return 2;

        case SectionFriends: {
            int N = (tableView == self.tableView) ? _friends.count : _friendMatches.count;
            return N;
        }

        default:
            break;
    }

    return 0;
}

- (float)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 20 * IdiomScale();
}

// Let the sections breathe.

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *header = [UIView new];
    header.backgroundColor = [UIColor clearColor];
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;

    if (section == SectionFriendRequests && _friendRequests.count == 0)
        return 0;

    if (section == SectionFriends && _friends.count == 0)
        return 0;

    return 60 * IdiomScale();
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"cell";

    FriendTableViewCell *cell = (FriendTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifier];

    if (!cell) {
        cell = [[FriendTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }

    self.tableView.tableHeaderView.layer.borderColor=[UIColor redColor].CGColor;
    self.tableView.tableHeaderView.layer.borderWidth=1;


    NSArray *friendRequests = (tableView == self.tableView) ? _friendRequests : _friendRequestMatches;
    NSArray *friends = (tableView == self.tableView) ? _friends : _friendMatches;

    switch (indexPath.section) {
        case SectionFriendRequests: {
            PFObject *friendRequest = friendRequests[indexPath.row];
            PFUser *requestor = friendRequest[@"sourceUser"];
            NSURL *requestorProfilePhotoURL = [NSURL URLWithString:requestor[@"profilePhotoURL"]];
            UIImage *placeholderImage = [UIImage imageNamed:@""];

            __weak UITableViewCell *weakCell = cell;

            [cell.imageView sd_setImageWithURL:requestorProfilePhotoURL placeholderImage:placeholderImage options:SDWebImageLowPriority completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) { [weakCell setNeedsLayout]; }];

            cell.textLabel.text = [requestor displayName];
            cell.detailTextLabel.text = @"wants to be your friend";

            [cell usePlusForRightImage];
            break;
        }

        case SectionFindFriends: {
            // No reuse here. Just 2 rows.

            FindFriendsTableCell *mediaCell = [[FindFriendsTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            mediaCell.backgroundColor = [UIColor clearColor];
            mediaCell.textLabel.font = [UIFont fontWithName:kCustomFontName size:FontSize()*0.7];

            NIKFontAwesomeIconFactory *factory = [NIKFontAwesomeIconFactory buttonIconFactory];
            factory.size = 38; // use even number
            factory.colors = @[ [[UIColor blackColor] colorWithAlphaComponent:0.5] ];

            mediaCell.textLabel.textColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];

            switch (indexPath.row) {
                  case FindFriendsByFacebook:
                    mediaCell.textLabel.text = @"add facebook friends";
                    mediaCell.imageView.image = [factory createImageForIcon:NIKFontAwesomeIconFacebookSquare];
                    mediaCell.contentView.backgroundColor = kColorDarkBlue;
                    break;

                case FindFriendsByTwitter:
                    mediaCell.textLabel.text = @"add twitter friends";
                    mediaCell.imageView.image = [factory createImageForIcon:NIKFontAwesomeIconTwitterSquare];
                    mediaCell.contentView.backgroundColor = kColorBlue;
                    break;
                    
                default:
                    break;
            }

            return mediaCell;
        }

        case SectionFriends: {
            PFUser *friend = friends[indexPath.row];
            NSURL *profilePhotoURL = [NSURL URLWithString:friend[@"profilePhotoURL"]];
            UIImage *placeholderImage = [UIImage imageNamed:@""];

            __weak UITableViewCell *weakCell = cell;

            [cell.imageView sd_setImageWithURL:profilePhotoURL placeholderImage:placeholderImage options:SDWebImageLowPriority completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) { [weakCell setNeedsLayout]; }];
            cell.textLabel.text = [friend displayName];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
    }

    [self setRightViewForCell:cell indexPath:indexPath];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];

    NSArray *friendRequests = (tableView == self.tableView) ? _friendRequests : _friendRequestMatches;
    NSArray *friends = (tableView == self.tableView) ? _friends : _friendMatches;

    switch (indexPath.section) {
        case SectionFriendRequests:
            [self didSelectFriendRequest:friendRequests[indexPath.row]];
            break;

        case SectionFindFriends:
            [self didSelectFriendSearchMethod:indexPath.row];
            break;

        case SectionFriends:
            [self didSelectFriend:friends[indexPath.row]];

        default:
            break;
    }
}

#pragma mark - operations on objects

- (void)didSelectFriendRequest:(PFObject *)friendRequest
{
    PFUser *requestor = friendRequest[@"sourceUser"];

    __weak typeof(self) weakSelf = self;

    [PFCloud
     callFunctionInBackground:@"becomeFriends"
     withParameters:@{ @"requestorID": requestor.objectId }
     block:^(id object, NSError *error) {
         if (error) {
             [error displayParseError:@"accept friend request"];
         } else {
             [weakSelf.friendRequests removeObject:friendRequest];

             [weakSelf.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:SectionFriendRequests]
                               withRowAnimation:UITableViewRowAnimationAutomatic];

             [friendRequest deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                 [weakSelf loadFriends];
             }];
         }
     }];

}

- (void)didSelectFriendSearchMethod:(NSInteger)which
{
    // TODO consider moving this to FriendFinder

    switch (which) {
        case FindFriendsByFacebook:
            if (![PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
                __weak typeof(self) weakSelf = self;

                [[PFUser currentUser] linkWithFacebookBlock:^(BOOL succeeded, NSError *error) {
                    if (succeeded) {
                        [weakSelf findAndDisplayFacebookFriends];
                    }
                }];
            } else {
                [self findAndDisplayFacebookFriends];
            }

            break;

        case FindFriendsByTwitter:
            if (![PFTwitterUtils isLinkedWithUser:[PFUser currentUser]]) {
                __weak typeof(self) weakSelf = self;

                [[PFUser currentUser] linkWithTwitterBlock:^(BOOL succeeded, NSError *error) {
                    if (succeeded) {
                        [weakSelf findAndDisplayTwitterFriends];
                    }
                }];
            } else {
                [self findAndDisplayTwitterFriends];
            }

            break;

        default:
            break;
    }
}

- (void)showInstructionsOnFriendRequests
{
    dispatchOncePersistent(@"show instructions for friend requests", ^{
        [SVProgressHUD showSuccessWithStatus:@"Select a friend to send them a friend request"];
    });
}

- (void)findAndDisplayFacebookFriends
{
    __weak typeof(self) weakSelf = self;

    [_friendFinder findFacebookFriendsWithTheApp:^(BOOL succeeded, NSError *error) {
        if (succeeded && weakSelf.friendFinder.facebookFriendsWithApp.count > 0) {
            [weakSelf showInstructionsOnFriendRequests];

            FriendRequestViewController *vc = [[FriendRequestViewController alloc] initWithUsers:weakSelf.friendFinder.facebookFriendsWithApp accentColor:kColorDarkBlue];
            vc.title = @"facebook friends";
            [weakSelf.navigationController pushViewController:vc animated:YES];
        }
    }];
}

- (void)findAndDisplayTwitterFriends
{
    __weak typeof(self) weakSelf = self;

    [_friendFinder findTwitterFriendsWithTheApp:^(BOOL succeeded, NSError *error) {
        if (succeeded && weakSelf.friendFinder.twitterFriendsWithApp.count > 0) {
            [weakSelf showInstructionsOnFriendRequests];

            FriendRequestViewController *vc = [[FriendRequestViewController alloc] initWithUsers:weakSelf.friendFinder.twitterFriendsWithApp accentColor:kColorBlue];
            vc.title = @"twitter friends";
            [weakSelf.navigationController pushViewController:vc animated:YES];
        }
    }];
}

- (void)didSelectFriend:(PFUser *)friend
{
    // yeah, great, good for you.
}

#pragma mark - sliding cell

- (void)setRightViewForCell:(FriendTableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    cell.delegate = self;

    if (indexPath.section == SectionFindFriends) {
        cell.rightView = nil;
        return;
    }

    cell.indexPath = indexPath;

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = kColorPink;
    label.font = [UIFont fontWithName:kCustomFontName size:FontSize()];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];

    label.text = @"remove ";
    [label sizeToFit];

    CGRect bounds = label.bounds;
    bounds.size.width += 30;
    bounds.size.height = cell.contentView.height;
    label.bounds = bounds;

    label.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    cell.rightView = label;
}

- (void)revealTableViewCell:(FriendTableViewCell *)cell didPan:(CGFloat)dx
{
    UILabel *label = (UILabel *)cell.rightView;
    CGFloat percentage = -dx / label.bounds.size.width; // < 0 since pan left only
    CGFloat alpha = MIN(1, MAX(0, percentage));
    [label setAlpha:alpha];

    if (alpha == 1) {
        label.text = cell.indexPath.section == SectionFriendRequests ? @"deny!" : @"remove!";
        label.textColor = [UIColor blackColor];
    } else {
        label.text = cell.indexPath.section == SectionFriendRequests ? @"deny" : @"remove";
        label.textColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    }
}

- (void)revealTableViewCellDidTrigger:(FriendTableViewCell *)cell
{
    switch (cell.indexPath.section) {
        case SectionFriendRequests: {
            PFObject *friendRequest = _friendRequests[cell.indexPath.row];
            [friendRequest deleteEventually];
            [_friendRequests removeObjectAtIndex:cell.indexPath.row];
            break;
        }

        case SectionFindFriends: {
            PFUser *friend = _friends[cell.indexPath.row];
            PFRelation *friends = [[PFUser currentUser] relationForKey:@"friends"];
            [friends removeObject:friend];
            [_friends removeObjectAtIndex:cell.indexPath.row];
            [[PFUser currentUser] saveEventually];
            break;
        }
    }

    [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:cell.indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end

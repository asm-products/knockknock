//
//  FriendRequestViewController.m
//  Knock Knock
//
//  Created by Brian Hammond on 1/29/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import "FriendRequestViewController.h"
#import "FriendTableViewCell.h"

@interface FriendRequestViewController ()

@property (strong, nonatomic) NSArray *users;
@property (strong, nonatomic) NSMutableSet *usersRequested;
@property (strong, nonatomic) NSArray *matches;

@end

@implementation FriendRequestViewController

- (id)initWithUsers:(NSArray *)users accentColor:(UIColor *)color
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.users = users;
        self.accentColor = color;
        self.usersRequested = [NSMutableSet set];
    }
    return self;
}

- (void)updateMatchesForSearchString:(NSString *)searchString
{
    self.matches = [_users bk_select:^BOOL(PFUser *user) {
        return [[[user displayName] lowercaseString] rangeOfString:[searchString lowercaseString]].location != NSNotFound;
    }];
}

#pragma mark - table view

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60 * IdiomScale();
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return tableView == self.tableView ? _users.count : _matches.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"cell";

    FriendTableViewCell *cell = (FriendTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifier];

    if (!cell) {
        cell = [[FriendTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }

    NSArray *friends = (tableView == self.tableView) ? _users : _matches;

    PFUser *friend = friends[indexPath.row];
    NSURL *profilePhotoURL = [NSURL URLWithString:friend[@"profilePhotoURL"]];
    UIImage *placeholderImage = [UIImage imageNamed:@""];

    __weak UITableViewCell *weakCell = cell;

    [cell.imageView sd_setImageWithURL:profilePhotoURL placeholderImage:placeholderImage options:SDWebImageLowPriority completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        [weakCell setNeedsLayout];
    }];

    cell.textLabel.text = [friend displayName];
    cell.selectionStyle = UITableViewCellSelectionStyleGray;

    if ([_usersRequested containsObject:friend]) {
        cell.detailTextLabel.text = @"request pending";
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];

    NSArray *friends = (tableView == self.tableView) ? _users : _matches;
    PFUser *friend = friends[indexPath.row];

    [self didSelectFriend:friend];
}

- (void)didSelectFriend:(PFUser *)friend
{
    if ([_usersRequested containsObject:friend])
        return;

    __weak typeof(self) weakSelf = self;

    [SVProgressHUD showWithStatus:@"Sending request..."];

    PFQuery *query = [PFQuery queryWithClassName:@"FriendRequest"];
    [query whereKey:@"targetUser" equalTo:friend];
    [query whereKey:@"sourceUser" equalTo:[PFUser currentUser]];
    [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if (error) {
            [error displayParseError:@"send friend request"];
            return;
        }

        if (number > 0) {
            [SVProgressHUD showSuccessWithStatus:@"Requested!"];
            [weakSelf.usersRequested addObject:friend];
            [weakSelf.tableView reloadData];
            return;
        }

        PFObject *friendRequest = [PFObject objectWithClassName:@"FriendRequest"];
        friendRequest[@"targetUser"] = friend;
        friendRequest[@"sourceUser"] = [PFUser currentUser];
        [friendRequest saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!succeeded) {
                [error displayParseError:@"send friend request"];
                return;
            }

            [SVProgressHUD showSuccessWithStatus:@"Requested!"];
            [weakSelf.usersRequested addObject:friend];
            [weakSelf.tableView reloadData];
        }];
    }];
}

@end

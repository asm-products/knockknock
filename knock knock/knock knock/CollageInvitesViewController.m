//
//  CollageInvitesViewController.m
//  Knock Knock
//
//  Created by Brian Hammond on 2/6/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import "CollageInvitesViewController.h"
#import "FriendTableViewCell.h"
#import "UserProfileImageListView.h"
#import "FriendFinder.h"
#import "CollageSenderViewController.h"

@interface CollageInvitesViewController () <UserProfileImageListViewDelegate>

@property (nonatomic, assign) NSInteger mode;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, copy) NSString *caption;
@property (nonatomic, strong) NSMutableArray *invitees;

@property (nonatomic, strong) NSArray *friends;
@property (strong, nonatomic) NSArray *friendMatches;
@property (strong, nonatomic) UserProfileImageListView *profileImageListView;
@property (strong, nonatomic) FriendFinder *friendFinder;

@end

@implementation CollageInvitesViewController

- (id)initWithImage:(UIImage *)image
            caption:(NSString *)caption
           invitees:(NSArray *)invitees
               mode:(NSInteger)mode
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.image = image;
        self.caption = caption;
        self.invitees = invitees.count > 0 ? [NSMutableArray arrayWithArray:invitees] : [NSMutableArray array];
        self.mode = mode;

        self.friendFinder = [FriendFinder new];

        switch (mode) {
            case CollageInvitesViewControllerModeFriends:
                self.accentColor = kColorGreen;
                self.title = @"friends";
                break;

            case CollageInvitesViewControllerFollowings:
                self.accentColor = kColorBlue;
                self.title = @"followings";
                break;
        }

        self.profileImageListView = [[UserProfileImageListView alloc] initWithFrame:CGRectZero];
        _profileImageListView.backgroundColor = kColorDarkBrown;
        _profileImageListView.preferredImageDiameter = (60 - 20) * IdiomScale();
        _profileImageListView.delegate = self;

        [_invitees enumerateObjectsUsingBlock:^(PFUser *friend, NSUInteger idx, BOOL *stop) {
            [_profileImageListView addUser:friend];
        }];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _profileImageListView.width = self.view.width;

    [self addForwardButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.navigationController.navigationBarHidden = NO;

    switch (_mode) {
        case CollageInvitesViewControllerModeFriends:
            [self loadFriends];
            break;

        case CollageInvitesViewControllerFollowings:
            [self findAndDisplayTwitterFriends];
            break;
    }
}

- (void)loadFriends
{
    __weak typeof(self) weakSelf = self;

    [_friendFinder loadFriends:^(BOOL succeeded, NSError *error) {
        [SVProgressHUD dismiss];

        if (succeeded) {
            weakSelf.friends = [weakSelf.friendFinder.friends mutableCopy];

            [weakSelf.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        } else {
            weakSelf.friends = nil;
        }
    }];
}

- (void)findAndDisplayTwitterFriends
{
    __weak typeof(self) weakSelf = self;

    [_friendFinder findTwitterFriendsWithTheApp:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            weakSelf.friends = [weakSelf.friendFinder.twitterFriendsWithApp mutableCopy];

            if (weakSelf.friends.count == 0) {
                // It can happen that we find out that the user has no twitter friends here
                // before the navigation controller is done animating in this view...

                [SVProgressHUD showErrorWithStatus:@"No twitter friends here"];

                [weakSelf bk_performBlock:^(id sender) {
                    [weakSelf navigateForwards:nil];
                } afterDelay:1];

                return;
            }

            [weakSelf.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        } else {
            weakSelf.friends = nil;
        }

        [SVProgressHUD dismiss];
    }];
}

- (void)updateMatchesForSearchString:(NSString *)searchString
{
    self.friendMatches = [_friends bk_select:^BOOL(PFUser *friend) {
        return [[[friend displayName] lowercaseString] rangeOfString:[searchString lowercaseString]].location != NSNotFound;
    }];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (tableView == self.tableView) ? _friends.count : _friendMatches.count;
}

- (float)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (tableView == self.tableView) {
        if (_invitees.count == 0)
            return 60 * IdiomScale();

        return [_profileImageListView sizeThatFits:CGSizeMake(self.view.width, 0)].height;
    }

    return 30 * IdiomScale();
}

- (int)allowedInviteCount
{
    return [[PFUser currentUser][@"hasUpgraded"] boolValue] ? 8 : 3;
}

- (UIView *)makeInviteHeaderView
{
    CGFloat height = [self tableView:self.tableView heightForHeaderInSection:0];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, self.view.width - 40, height)];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont fontWithName:kCustomFontName size:FontSize()*0.8];
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = 0.25;
    label.textColor = kColorCream;
    label.text = [NSString stringWithFormat:@"invite up to %d friends", [self allowedInviteCount]];
    [self.view addSubview:label];

    UIView *wrapper = [[UIView alloc] initWithFrame:R(0,0,self.view.width,0)];
    wrapper.backgroundColor = [UIColor clearColor];
    [wrapper addSubview:label];

    UIView *bottomLineView = [[UIView alloc] initWithFrame:R(0, height-2, self.view.width, 2)];
    bottomLineView.backgroundColor = kColorCream;
    [wrapper addSubview:bottomLineView];

    return wrapper;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (tableView == self.tableView) {
        if (_invitees.count == 0)
            return [self makeInviteHeaderView];

        return _profileImageListView;
    }

    return [UIView new];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60 * IdiomScale();
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"cell";

    FriendTableViewCell *cell = (FriendTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifier];

    if (!cell) {
        cell = [[FriendTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }

    __weak UITableViewCell *weakCell = cell;

    NSArray *friends = (tableView == self.tableView) ? _friends : _friendMatches;
    PFUser *friend = friends[indexPath.row];

    NSURL *profilePhotoURL = [NSURL URLWithString:friend[@"profilePhotoURL"]];
    UIImage *placeholderImage = [UIImage imageNamed:@""];
    [cell.imageView sd_setImageWithURL:profilePhotoURL placeholderImage:placeholderImage options:SDWebImageLowPriority completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        [weakCell setNeedsLayout];
    }];

    cell.textLabel.text = [friend displayName];

    if ([self isInvited:friend]) {
        cell.backgroundColor = kColorCream;
        cell.contentView.backgroundColor = kColorCream;
        cell.textLabel.textColor = kColorDarkBrown;
        [cell useCheckForRightImage];
    } else {
        cell.contentView.backgroundColor = kColorDarkBrown;
        cell.textLabel.textColor = kColorCream;
        cell.rightImageView.image = nil;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];

    NSArray *friends = (tableView == self.tableView) ? _friends : _friendMatches;
    PFUser *friend = friends[indexPath.row];

    [self toggleInvited:friend];
    [tableView reloadData];
}

- (BOOL)isInvited:(PFUser *)friend
{
    return [_invitees bk_select:^BOOL(PFUser *user) {
        return [user.objectId isEqualToString:friend.objectId];
    }].count > 0;
}

- (void)toggleInvited:(PFUser *)friend
{
    if ([self isInvited:friend]) {
        self.invitees = [[_invitees bk_select:^BOOL(PFUser *user) {
            return ![user.objectId isEqualToString:friend.objectId];
        }] mutableCopy];

        [_profileImageListView removeUser:friend];
    } else {
        [_invitees addObject:friend];
        [_profileImageListView addUser:friend];
    }

    self.navigationItem.rightBarButtonItem.enabled = (_invitees.count > 0);
}

- (void)didTapUser:(PFUser *)user inProfileImageListView:(UserProfileImageListView *)profileImageListView
{
    [self toggleInvited:user];

    [self.tableView reloadData];
}

-(void)searchDisplayController:(UISearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView
{
    [self.tableView reloadData];
}

- (void)navigateForwards:(id)sender
{
    // Invite Friends --> Invite Twitter Followers (if linked) --> Collage Sender

    if (_mode == CollageInvitesViewControllerModeFriends) {
        if ([PFTwitterUtils isLinkedWithUser:[PFUser currentUser]]) {
            id vc = [[CollageInvitesViewController alloc] initWithImage:_image caption:_caption invitees:_invitees mode:CollageInvitesViewControllerFollowings];
            [self.navigationController pushViewController:vc animated:YES];
            return;
        }
    }

    if (_invitees.count == 0) {
        [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"Oops", nil) message:NSLocalizedString(@"Please select some friends to invite.", nil) cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil handler:^(UIAlertView *alert, NSInteger buttonPressed) {}];

        return;
    }

    id vc = [[CollageSenderViewController alloc] initWithImage:_image caption:_caption invitees:_invitees];
    [self.navigationController pushViewController:vc animated:YES];
}

@end

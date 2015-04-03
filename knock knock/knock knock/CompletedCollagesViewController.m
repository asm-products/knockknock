//
//  CompletedCollagesViewController.m
//  Knock Knock
//
//  Created by Brian Hammond on 2/11/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import "CompletedCollagesViewController.h"
#import "NSDate+TimeAgo.h"
#import "CollageViewController.h"

@interface CompletedCollageTableViewCell : UITableViewCell

@property (strong, nonatomic) UIView *bottomLineView;

@end

@implementation CompletedCollageTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleGray;
        self.textLabel.font = [UIFont fontWithName:kCustomFontName size:FontSize()];
        self.textLabel.textColor = kColorCream;

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = kColorCream;
        label.font = [UIFont fontWithName:kCustomFontName size:FontSize()*0.6];
        self.accessoryView = label;

        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.imageView.clipsToBounds = YES;

        // Fake separator since designs call for THICK, CHUNKY LINES. Wow much style.

        self.bottomLineView = [[UIView alloc] initWithFrame:CGRectZero];
        _bottomLineView.backgroundColor = kColorCream;
        [self addSubview:_bottomLineView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    _bottomLineView.frame = R(0, self.height-2, self.width, 2);

    CGFloat margin = 15 * IdiomScale();
    CGFloat imageSize = self.height - margin * 2;

    self.imageView.frame = R(margin, margin, imageSize, imageSize);

    CGFloat textLeft = margin + imageSize + margin;
    self.textLabel.frame = R(textLeft, 0, self.accessoryView.left - margin - textLeft, self.height);
}

@end

@interface CompletedCollagesViewController ()

@property (strong, nonatomic) NSArray *collagePhotos;  // that the current user authored
@property (strong, nonatomic) NSDate *lastFetchedAt;

@end

@implementation CompletedCollagesViewController

- (id)init
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.accentColor = kColorOrange;
        self.title = @"collages";
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.navigationController.navigationBarHidden = NO;

    [self findCollagePhotos];

    [self reloadPeriodically];
}

- (void)reloadPeriodically
{
    // Just b/c I left this screen open and went to have lunch, returned, and
    // noticed that the timestamps were off.  Don't reload remote data but
    // local table cells so timestamps update.

    __weak typeof(self) weakSelf = self;

    [self bk_performBlock:^(id sender) {
        [weakSelf.tableView reloadData];
        [weakSelf reloadPeriodically];
    } afterDelay:30];
}

- (void)findCollagePhotos
{
    NSDate *now = [NSDate date];
    if ([now timeIntervalSinceDate:_lastFetchedAt] < 15) {
        return;
    }

    self.lastFetchedAt = [NSDate date];


    __weak typeof(self) weakSelf = self;

    [SVProgressHUD showWithStatus:@"Loading..."];

    PFQuery *query = [PFQuery queryWithClassName:@"CollagePhoto"];

    [query whereKey:@"author" equalTo:[PFUser currentUser]];
    [query includeKey:@"collage"];
    [query orderByDescending:@"createdAt"];

    query.limit = 1000;

    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            [SVProgressHUD dismiss];
            [error displayParseError:@"fetch collage photos"];
            return;
        }

        if (objects.count == 0) {
            [SVProgressHUD showErrorWithStatus:@"No collages found!"];
            return;
        }

        [SVProgressHUD dismiss];

        // Make sure we're only show COMPLETED collages.
        // We could combine multiple queries but since the timespan in which a collage
        // is active is only 1 minute, 99.9999% of the collages will be completed here
        // so it's OK to filter here on the client side.

        weakSelf.collagePhotos = [objects bk_select:^BOOL(PFObject *collagePhoto) {
            return collagePhoto[@"collage"][@"completedAt"] != nil;
        }];

        [weakSelf.tableView reloadData];
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _collagePhotos.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 90 * IdiomScale();
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cell";

    CompletedCollageTableViewCell *cell = (CompletedCollageTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    if (cell == nil) {
        cell = [[CompletedCollageTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }

    PFObject *collagePhoto = _collagePhotos[indexPath.row];
    PFObject *collage = collagePhoto[@"collage"];
    
    BOOL isInitiator = [[collage[@"initiator"] objectId] isEqualToString:[PFUser currentUser].objectId];
    cell.textLabel.text = isInitiator ? @"initiator" : @"participant";

    // Show how long ago the collage completed.

    UILabel *accessoryLabel = (UILabel *)cell.accessoryView;
    NSDate *date = collage[@"completedAt"];
    if (!date) date = collage.createdAt;   // only a minute's diff. anyway
    accessoryLabel.text = [date timeAgoSimple];
    [accessoryLabel sizeToFit];

    NSDate *now = [NSDate date];
    double deltaSeconds = fabs([date timeIntervalSinceDate:now]);
    double deltaMinutes = deltaSeconds / 60.0f;
    if (deltaMinutes <= 5) {
        accessoryLabel.width = accessoryLabel.height = roundf([self tableView:tableView heightForRowAtIndexPath:indexPath] / 3.5);
        accessoryLabel.textAlignment = NSTextAlignmentCenter;
        accessoryLabel.layer.cornerRadius = accessoryLabel.width/2;  // make circular.
        accessoryLabel.backgroundColor = kColorCream;
        accessoryLabel.textColor = kColorDarkBrown;
    } else {
        accessoryLabel.textAlignment = NSTextAlignmentLeft;
        accessoryLabel.layer.cornerRadius = 0;
        accessoryLabel.backgroundColor = [UIColor clearColor];
        accessoryLabel.textColor = kColorCream;
    }

    // Show the current user's photo in this collage.
    // Why not the full collage?  Two reasons: 1) the final collage is not stored as a distinct image.
    // Thus, to load the collage you have to load the photos thereof. This is for zooming in the client UI (this app).
    // I'm not loading 4 or 9 photos per table view cell/row.
    // 2) The user will more likely recognize the photo they took.

    PFFile *imageFile = collagePhoto[@"imageFile"];
    UIImage *placeholderImage = [UIImage imageNamed:@""];

    __weak UITableViewCell *weakCell = cell;

    [cell.imageView sd_setImageWithURL:[NSURL URLWithString:imageFile.url] placeholderImage:placeholderImage options:SDWebImageLowPriority completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        [weakCell setNeedsLayout];
    }];

    // Hide bottom line on last row.

    cell.bottomLineView.hidden = (indexPath.row == _collagePhotos.count - 1);

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    PFObject *collagePhoto = _collagePhotos[indexPath.row];
    PFObject *collage = collagePhoto[@"collage"];
    [self.navigationController pushViewController:[[CollageViewController alloc] initWithCollage:collage] animated:YES];
}

- (void)setupSearch
{
    // no search, thanks
}

@end

//
//  UserProfileImageListView.m
//  Knock Knock
//
//  Created by Brian Hammond on 2/7/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import "UserProfileImageListView.h"

@implementation UserProfileImageListView
{
    NSMutableDictionary *_userToImageViewMap;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _userToImageViewMap = [NSMutableDictionary dictionary];
        _preferredImageDiameter = 30 * IdiomScale();
    }
    return self;
}

- (void)addUser:(PFUser *)user
{
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    imageView.clipsToBounds = YES;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.userInteractionEnabled = YES;

    __weak UIImageView *weakImageView = imageView;

    [imageView sd_setImageWithURL:[NSURL URLWithString:user[@"profilePhotoURL"]] placeholderImage:[UIImage imageNamed:@""] options:SDWebImageLowPriority completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        [weakImageView setNeedsLayout];
    }];

    _userToImageViewMap[user[@"fullName"]] = imageView;

    [self addSubview:imageView];

    __weak typeof(self) weakSelf = self;

    UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
        if (state == UIGestureRecognizerStateEnded) {
            [weakSelf.delegate didTapUser:user inProfileImageListView:weakSelf];
        }
    }];

    [imageView addGestureRecognizer:tapGR];
}

- (void)removeUser:(PFUser *)user
{
    id imageView = _userToImageViewMap[user[@"fullName"]];
    [imageView removeFromSuperview];

    [self setNeedsLayout];
}

// Show images in column major order sorted by last name then first name of each user.

- (void)layoutSubviews
{
    [super layoutSubviews];

    NSArray *sortedUserKeys = [[_userToImageViewMap allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2];
    }];

    CGFloat margin = 10;
    __block CGFloat x = margin;
    __block CGFloat y = margin;
    CGFloat w = self.width;
    CGFloat imageSize = _preferredImageDiameter;

    [sortedUserKeys enumerateObjectsUsingBlock:^(id userKey, NSUInteger idx, BOOL *stop) {
        UIImageView *imageView = _userToImageViewMap[userKey];
        imageView.frame = R(x, y, imageSize, imageSize);
        imageView.layer.cornerRadius = imageSize/2;

        x += imageSize + margin;
        if (x + imageSize > w - margin) {
            x = margin;
            y += imageSize + margin;
        }
    }];
}

// Assumes width has been set already.

- (CGSize)sizeThatFits:(CGSize)size
{
    CGFloat margin = 10;
    __block CGFloat x = margin;
    __block CGFloat y = margin;
    CGFloat w = self.width;
    CGFloat imageSize = _preferredImageDiameter;

    [_userToImageViewMap enumerateKeysAndObjectsUsingBlock:^(id key, UIImageView *obj, BOOL *stop) {
        x += imageSize + margin;
        if (x + imageSize > w - margin) {
            x = margin;
            y += imageSize + margin;
        }
    }];

    return CGSizeMake(self.width, y + imageSize + margin);
}

@end

//
//  FriendTableViewCell.m
//  Knock Knock
//
//  Created by Brian Hammond on 1/29/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import "FriendTableViewCell.h"

@interface FriendTableViewCell ()

@property (strong, nonatomic) UIView *bottomLineView;

@end

@implementation FriendTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.textLabel.font = [UIFont fontWithName:kCustomFontName size:FontSize() * 0.8];
        self.detailTextLabel.font = [UIFont fontWithName:kCustomFontName size:FontSize()/2];
        self.selectionStyle = UITableViewCellSelectionStyleGray;
        self.imageView.clipsToBounds = YES;
        self.useCircularImageView = YES;

        self.bottomLineView = [[UIView alloc] initWithFrame:CGRectZero];
        _bottomLineView.backgroundColor = kColorCream;
        [self addSubview:_bottomLineView];

        [self prepareForReuse];
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = kColorDarkBrown;

    self.imageView.image = nil;

    self.textLabel.text = @"";
    self.textLabel.textColor = kColorCream;
    self.textLabel.textAlignment = NSTextAlignmentLeft;

    self.detailTextLabel.text = @"";
    self.detailTextLabel.textColor = kColorCream;
    self.detailTextLabel.textAlignment = NSTextAlignmentLeft;

    [self.rightImageView removeFromSuperview]; 

    self.rightImageView = nil;
    self.indexPath = nil;

    _bottomLineView.hidden = NO;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    _bottomLineView.frame = R(0, 0, self.width, 2);
    _bottomLineView.hidden = _indexPath.row == 0;

    CGFloat cellHeight = self.contentView.height;
    CGFloat cellWidth = self.contentView.width;
    CGFloat margin = 10 * IdiomScale();
    CGFloat imageSize = 40 * IdiomScale();
    CGFloat textLeft = imageSize + margin*2;
    CGFloat textWidth = self.rightImageView ? cellWidth - textLeft - imageSize : cellWidth - textLeft;
    CGFloat rightImageSize = 30 * IdiomScale();

    self.imageView.frame = R(margin, cellHeight/2-imageSize/2, imageSize, imageSize);

    self.rightImageView.frame = R(cellWidth - rightImageSize, cellHeight/2 - rightImageSize/2, rightImageSize, rightImageSize);

    if (self.detailTextLabel.text.length > 0) {
        self.textLabel.frame = R(textLeft, margin, textWidth, cellHeight/2 - 5);
        self.detailTextLabel.frame = R(textLeft, cellHeight/2 + 5, textWidth, cellHeight/4);
        //        self.textLabel.textAlignment = self.detailTextLabel.textAlignment = NSTextAlignmentLeft;
    } else {
        self.textLabel.frame = R(textLeft, cellHeight/2-imageSize/2, textWidth - imageSize, imageSize);
        //        self.textLabel.textAlignment = NSTextAlignmentCenter;

    }

    self.imageView.layer.cornerRadius = _useCircularImageView ? imageSize/2 : 0;
    self.imageView.contentMode = _useCircularImageView ? UIViewContentModeScaleAspectFill : UIViewContentModeScaleAspectFit;
}

- (void)usePlusForRightImage
{
    [self useIconForRightImage:NIKFontAwesomeIconPlusCircle];
}

- (void)useCheckForRightImage
{
    [self useIconForRightImage:NIKFontAwesomeIconCheckCircle];
}

- (void)useIconForRightImage:(NIKFontAwesomeIcon)icon
{
    NIKFontAwesomeIconFactory *factory = [NIKFontAwesomeIconFactory buttonIconFactory];
    factory.size = floor(40 * IdiomScale()); // use even number
    factory.colors = @[ kColorGreen ];
    factory.square = YES;
    UIImageView *iconView = [[UIImageView alloc] initWithImage:[factory createImageForIcon:icon]];
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    [_rightImageView removeFromSuperview];
    self.rightImageView = iconView;
    [self.contentView addSubview:_rightImageView];
}

@end

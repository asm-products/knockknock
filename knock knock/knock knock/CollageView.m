//
//  CollageView.m
//  Knock Knock
//
//  Created by Brian Hammond on 2/11/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import "CollageView.h"
#import "CaptionedImageView.h"

enum
{
    kBaseBackgroundTileTag = 456456,
    kBaseImageViewTag = 123123,
};

@interface CollageView ()

@property (strong, nonatomic) PFObject *collage;
@property (weak, nonatomic) CaptionedImageView *focusedImageView;

@end

@implementation CollageView

- (id)initWithCollage:(PFObject *)collage
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.collage = collage;
        _showUsernames = NO;
        [self addBackgroundTiles];
        [self addImageViews];
    }
    return self;
}

- (NSInteger)collageSize
{
    NSInteger size = [_collage[@"size"] integerValue];
    NSAssert(size > 0, @"invalid collage size");
    return size;
}

// Colored background views that are used to make the holes
// where the photo of an invitee that failed to join would normally be rendered.

- (void)addBackgroundTiles
{
    NSArray *backgroundColors = _collage[@"backgroundColors"];
    NSArray *photoIndexes = _collage[@"photoIndexes"];
    NSInteger collageSize = [self collageSize];

    NSAssert(backgroundColors.count == collageSize * collageSize, @"invalid backgroundColors");
    NSAssert(photoIndexes.count == collageSize * collageSize, @"invalid photoIndexes");

    for (int i = 0; i < collageSize * collageSize; ++i) {
        NSInteger index = [photoIndexes[i] integerValue];
        NSAssert(index >= 0 && index < collageSize * collageSize, @"invalid photoIndexes");
        UIView *tileView = [UIView new];
        NSString *colorName = backgroundColors[index];
        tileView.backgroundColor = [self colorFromSymbolicName:colorName];
        tileView.tag = kBaseBackgroundTileTag + i;
        [self addSubview:tileView];
    }
}

- (void)addImageViews
{
    NSInteger collageSize = [self collageSize];

    for (int i = 0; i < collageSize * collageSize; ++i) {
        CaptionedImageView *imageView = [[CaptionedImageView alloc] initWithImage:nil caption:nil];
        imageView.editable = NO;
        imageView.tag = kBaseImageViewTag + i;
        [self addSubview:imageView];
    }
}

- (UIColor *)colorFromSymbolicName:(NSString *)name
{
    static dispatch_once_t onceToken;
    static NSDictionary *dict;
    dispatch_once(&onceToken, ^{
        dict = @{ @"pink":kColorPink, @"yellow":kColorYellow, @"blue":kColorBlue, @"darkBlue":kColorDarkBlue, @"green":kColorGreen, @"cream":kColorCream, @"darkBrown":kColorDarkBrown, @"gray":kColorGray, @"orange":kColorOrange };
    });

    UIColor *color = dict[name];
    NSAssert(color, @"unknown symbolic color name");
    return color;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    NSInteger collageSize = [self collageSize];

    CGFloat tileSize = roundf(self.width / collageSize);

    for (int i = 0; i < collageSize * collageSize; ++i) {
        NSInteger x = i % collageSize;
        NSInteger y = i / collageSize;

        CGRect frame = R(x * tileSize, y * tileSize, tileSize, tileSize);

        UIView *backgroundColorTileView = [self viewWithTag:kBaseBackgroundTileTag + i];
        backgroundColorTileView.frame = frame;

        UIView *imageView = [self viewWithTag:kBaseImageViewTag + i];
        if (imageView != _focusedImageView) {
            imageView.frame = frame;
        }
    }
}

- (void)setShowUsernames:(BOOL)yesNo
{
    _showUsernames = yesNo;

    NSInteger collageSize = [self collageSize];

    for (int i = 0; i < collageSize * collageSize; ++i) {
        CaptionedImageView *imageView = (CaptionedImageView *)[self viewWithTag:kBaseImageViewTag + i];

        if (imageView.captionLabel.text.length == 0) {
            imageView.captionLabel.hidden = YES;
        } else {
            imageView.captionLabel.hidden = !yesNo;
        }
    }
}

// Collages are assigned a shuffled array of cell/tile indexes.
// Collage photos are sorted by creation date (oldest first).
// A collage photo is assigned a cell/tile in the view equal to its
// index in the shuffled array of cell/tile indexes.
// This way, layout is deterministic for all participants (recall that rendering
// of collages happens here, in this view, on the client) and still "random".

- (UIFont *)zoomedInFont
{
    NSInteger collageSize = [self collageSize];
    CGFloat tileSize = self.width / collageSize;
    return [UIFont fontWithName:kCustomFontName size:tileSize / 5.0];
}

- (UIFont *)zoomedOutFont
{
    NSInteger collageSize = [self collageSize];
    CGFloat tileSize = self.width / collageSize;
    return [UIFont fontWithName:kCustomFontName size:tileSize / 10.0];
}

- (void)setPhotos:(NSArray *)collagePhotos;
{
    NSInteger collageSize = [self collageSize];

    NSParameterAssert(collagePhotos.count > 0);
    NSParameterAssert(collagePhotos.count <= collageSize * collageSize);

    NSArray *photoIndexes = _collage[@"photoIndexes"];

    CGFloat tileSize = self.width / collageSize;

    __weak typeof(self) weakSelf = self;

    NSMutableDictionary *hiddenImages = [[[NSUserDefaults standardUserDefaults] objectForKey:@"hiddenImages"] mutableCopy];
    if (!hiddenImages) {
        hiddenImages = [NSMutableDictionary dictionary];
    }

    [collagePhotos enumerateObjectsUsingBlock:^(PFObject *collagePhoto, NSUInteger idx, BOOL *stop) {
        NSInteger tileIndex = [photoIndexes[idx] integerValue];

        PFFile *imageFile = collagePhoto[@"imageFile"];
        CaptionedImageView *imageView = (CaptionedImageView *)[self viewWithTag:kBaseImageViewTag + tileIndex];

        [weakSelf setImageForImageView:imageView file:imageFile hiddenImages:hiddenImages];

        PFUser *photographer = collagePhoto[@"author"];
        imageView.caption = [photographer displayName];
        imageView.captionLabel.hidden = !_showUsernames;
        imageView.captionLabel.font = [self zoomedOutFont];
        imageView.captionLabel.shadowOffset = CGSizeMake(0, -0.25);

        // Tap to toggle focus (zoom) on each collage photo

        [imageView addGestureRecognizer:[[UITapGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
            if (imageView.width == tileSize && !hiddenImages[imageFile.url]) {
                [weakSelf focusImageView:imageView];
            } else {
                [weakSelf defocusImageView:imageView tileIndex:tileIndex animated:YES];
            }
        }]];

        // Long press to hide each collage photo

        [imageView addGestureRecognizer:[[UILongPressGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
            if (state == UIGestureRecognizerStateBegan) {
                if (hiddenImages[imageFile.url]) {
                    [hiddenImages removeObjectForKey:imageFile.url];
                } else {
                    hiddenImages[imageFile.url] = @YES;
                    [weakSelf defocusImageView:imageView tileIndex:tileIndex animated:NO];
                }

                [weakSelf setImageForImageView:imageView file:imageFile hiddenImages:hiddenImages];

                [[NSUserDefaults standardUserDefaults] setObject:hiddenImages forKey:@"hiddenImages"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }]];
    }];
}

- (void)focusImageView:(CaptionedImageView *)imageView
{
    // zoom in

    self.focusedImageView = imageView;
    [self bringSubviewToFront:imageView];

    imageView.captionLabel.alpha = 0;
    [UIView animateWithDuration:0.4 animations:^{
        imageView.frame = self.bounds;
    } completion:^(BOOL finished) {
        imageView.captionLabel.font = [self zoomedInFont];
        [UIView animateWithDuration:0.4 animations:^{
            imageView.captionLabel.alpha = 1;
            imageView.captionLabel.shadowOffset = CGSizeMake(0, -1);
        }];
    }];

}

- (void)defocusImageView:(CaptionedImageView *)imageView tileIndex:(int)tileIndex animated:(BOOL)animated
{
    // zoom out

    NSInteger collageSize = [self collageSize];
    CGFloat tileSize = self.width / collageSize;

    self.focusedImageView = nil;

    imageView.captionLabel.alpha = 0;

    NSTimeInterval duration = animated ? 0.4 : 0;
    [UIView animateWithDuration:duration animations:^{
        NSInteger x = tileIndex % collageSize;
        NSInteger y = tileIndex / collageSize;

        CGRect frame = R(x * tileSize, y * tileSize, tileSize, tileSize);
        imageView.frame = frame;
    } completion:^(BOOL finished) {
        imageView.captionLabel.font = [self zoomedOutFont];
        [UIView animateWithDuration:duration animations:^{
            imageView.captionLabel.alpha = 1;
            imageView.captionLabel.shadowOffset = CGSizeMake(0, -0.25);
        }];
    }];
}

- (void)setImageForImageView:(CaptionedImageView *)imageView file:(PFFile *)imageFile hiddenImages:(NSDictionary *)hiddenImages
{
    if (hiddenImages[imageFile.url]) {
        NIKFontAwesomeIconFactory *factory = [NIKFontAwesomeIconFactory buttonIconFactory];
        factory.size = (int)roundf(imageView.width / 4.0) & ~1;  // use even number
        factory.colors = @[ [[UIColor blackColor] colorWithAlphaComponent:0.5] ];
        imageView.image = [factory createImageForIcon:NIKFontAwesomeIconEyeSlash];
        imageView.contentMode = UIViewContentModeCenter;
        imageView.captionLabel.alpha = 0;
    } else {
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.captionLabel.alpha = 1;
        [imageView sd_setImageWithURL:[NSURL URLWithString:imageFile.url] placeholderImage:nil options:SDWebImageLowPriority completed:nil];
    }
}

@end

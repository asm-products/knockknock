//
//  CaptionedImageView.m
//  Knock Knock
//
//  Created by Brian Hammond on 2/6/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import "CaptionedImageView.h"

@interface CaptionedImageView () <UIKeyInput>

@property (nonatomic, strong, readwrite) UILabel *captionLabel;
@property (nonatomic, strong) UISwipeGestureRecognizer *swipeDownGR;
@property (nonatomic, strong) UISwipeGestureRecognizer *swipeUpGR;
@property (nonatomic, strong) UITapGestureRecognizer *tapGR;

@end

@implementation CaptionedImageView
{
    NSMutableString *_caption;
}

@synthesize caption=_caption;

- (id)initWithImage:(UIImage *)image
{
    return [self initWithImage:image caption:nil];
}

- (id)initWithImage:(UIImage *)image caption:(NSString *)caption
{
    self = [super initWithImage:image];
    if (self) {
        _caption = caption ? [caption mutableCopy] : [NSMutableString string];

        [self addGestureRecognizers];

        self.captionLabel = ({
            UIFont *font = [UIFont fontWithName:kCustomFontName size:FontSize() * 2];
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.font = font;
            label.textColor = [UIColor whiteColor];
            label.backgroundColor = [UIColor clearColor];
            label.opaque = NO;
            label.textAlignment = NSTextAlignmentCenter;
            label.text = caption ? caption : @"";
            label.lineBreakMode = NSLineBreakByWordWrapping;
            label.numberOfLines = 0;
            label.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
            label.alpha = caption ? 1 : 0;  // fades in once.
            label;
        });
        
        [self addSubview:_captionLabel];

        self.maxCharacterLength = 200;

        self.userInteractionEnabled = YES;

        _editable = YES;

        [self registerForKeyboardNotifications];
    }

    return self;
}

- (void)setCaption:(NSString *)theCaption
{
    NSString *theText = (theCaption.length > _maxCharacterLength) ? [theCaption substringToIndex:_maxCharacterLength] : theCaption;

    _caption = [theText mutableCopy];
    _captionLabel.text = theText;
    _captionLabel.alpha = 1;
}

- (void)setEditable:(BOOL)theEditable
{
    _editable = theEditable;
    if (!_editable) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [self removeGestureRecognizers];
    } else {
        [self registerForKeyboardNotifications];
        [self addGestureRecognizers];
    }
}

- (void)addGestureRecognizers
{
    self.swipeDownGR = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeDown:)];
    _swipeDownGR.direction = UISwipeGestureRecognizerDirectionDown;
    [self addGestureRecognizer:_swipeDownGR];

    self.swipeUpGR = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeUp:)];
    _swipeUpGR.direction = UISwipeGestureRecognizerDirectionUp;
    [self addGestureRecognizer:_swipeUpGR];

    self.tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
    [self addGestureRecognizer:_tapGR];
}

- (void)removeGestureRecognizers
{
    [self removeGestureRecognizer:_swipeDownGR];
    [self removeGestureRecognizer:_swipeUpGR];
    [self removeGestureRecognizer:_tapGR];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    _captionLabel.frame = self.bounds;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Keyboard

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification*)aNotification
{
    NSDictionary *info = [aNotification userInfo];
    CGFloat duration = [info[UIKeyboardAnimationDurationUserInfoKey] floatValue];

    [UIView animateWithDuration:duration animations:^{
        _captionLabel.alpha = 1;
    }];

    if (![_captionLabel.text hasSuffix:@"|"]) {
        _captionLabel.text = [_captionLabel.text stringByAppendingString:@"|"];
    }
}

- (void)keyboardWillHide:(NSNotification*)aNotification
{
    if ([_captionLabel.text hasSuffix:@"|"]) {
        _captionLabel.text = [_captionLabel.text substringToIndex:_captionLabel.text.length - 1];
    }
}

#pragma mark - Gesture Recognizers

- (void)didSwipeDown:(UISwipeGestureRecognizer *)gr
{
    [self resignFirstResponder];
}

- (void)didSwipeUp:(UISwipeGestureRecognizer *)gr
{
    [self becomeFirstResponder];
}

- (void)didTap:(UITapGestureRecognizer *)gr
{
    [self becomeFirstResponder];
}

#pragma mark - UIKeyInput

- (void)insertText:(NSString *)text
{
    // Do something with the typed character

    if ([text characterAtIndex:0] == '\r' || [text characterAtIndex:0] == '\n') {
        [self resignFirstResponder];
        return;
    }

    [_caption appendString:text];
    NSString *theText = (_caption.length > _maxCharacterLength) ? [_caption substringToIndex:_maxCharacterLength] : _caption;
    _captionLabel.text = [theText stringByAppendingString:@"|"];
}

- (void)deleteBackward
{
    // Handle the backwards delete key

    if (_caption.length > 0) {
        [_caption deleteCharactersInRange:NSMakeRange(_caption.length - 1, 1)];
        _captionLabel.text = [_caption stringByAppendingString:@"|"];
    }
}

- (BOOL)hasText
{
    // Return whether there's any text present

    return YES;
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

@end
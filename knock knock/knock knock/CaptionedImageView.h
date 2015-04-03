//
//  CaptionedImageView.h
//  Knock Knock
//
//  Created by Brian Hammond on 2/6/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import <UIKit/UIKit.h>

// An image view that can accept keyboard input directly to add a caption atop the image.
// Listen for UIKeyboardWillHideNotification and check the 'caption' property to get the caption edited.

@interface CaptionedImageView : UIImageView

- (id)initWithImage:(UIImage *)image caption:(NSString *)caption;

@property (nonatomic, strong) NSString *caption;
@property (nonatomic, strong, readonly) UILabel *captionLabel;
@property (nonatomic, assign) NSInteger maxCharacterLength;
@property (nonatomic, assign) BOOL editable;
@end

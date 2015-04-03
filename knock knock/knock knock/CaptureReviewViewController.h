//
//  CaptureReviewViewController.h
//  Knock Knock
//
//  Created by Brian Hammond on 2/6/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import "BaseViewController.h"
#import "BHCountdown.h"

@interface CaptureReviewViewController : BaseViewController

- (id)initWithImage:(UIImage *)capturedImage;

// Useful when you want to programmatically capture a photo, review it and auto-accept it.

- (void)sendPhoto;

@property (nonatomic, strong) PFObject *collage;
@property (nonatomic, strong) BHCountdown *countdown;

@end

//
//  CaptureViewController.h
//  Knock Knock
//
//  Created by Brian Hammond on 1/28/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import "BaseViewController.h"
#import "BHCountdown.h"

@interface CaptureViewController : BaseViewController

@property (strong, nonatomic) PFObject *collage;
@property (strong, nonatomic) BHCountdown *countdown;

@end

//
//  CollageView.h
//  Knock Knock
//
//  Created by Brian Hammond on 2/11/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CollageView : UIView

- (id)initWithCollage:(PFObject *)collage;

@property (nonatomic, assign) BOOL showUsernames;

// CollagePhoto PFObjects in order created.

- (void)setPhotos:(NSArray *)collagePhotos;

@end

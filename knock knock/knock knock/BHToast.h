//
//  BHToast.h
//  Visuality360
//
//  Created by Brian Hammond on 11/6/13.
//  Copyright (c) 2013 Global Apparel Network. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, BHToastType)
{
    BHToastTypePlain,
    BHToastTypeActivity,
    BHToastTypeSuccess,
    BHToastTypeError
};

typedef void (^BHToastTapBlock)();

@interface BHToast : UIWindow

+ (instancetype)sharedToast;

// For now, set message before changing toastType.

@property (copy, nonatomic) NSString *message;
@property (assign, nonatomic) BHToastType toastType;
@property (assign, nonatomic) float progress;
@property (nonatomic, copy) BHToastTapBlock tapBlock;

@end

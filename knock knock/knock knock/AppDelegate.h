//
//  AppDelegate.h
//  Knock Knock
//
//  Created by Brian Hammond on 1/14/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MainViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UINavigationController *navController;
@property (strong, nonatomic) MainViewController *mainVC;

@end

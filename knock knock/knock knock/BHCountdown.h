//
//  BHCountdown.h
//  Knock Knock
//
//  Created by Brian Hammond on 2/8/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import <Foundation/Foundation.h>

// Simple countdown timer with seconds granularity. Use KVO to observe changes.

@interface BHCountdown : NSObject

+ (id)countdownWithSeconds:(NSInteger)seconds;

@property (assign, nonatomic, readonly) NSInteger secondsRemaining;
@property (assign, nonatomic, readonly) BOOL completed;

@end

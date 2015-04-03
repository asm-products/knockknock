//
//  BHCountdown.m
//  Knock Knock
//
//  Created by Brian Hammond on 2/8/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import "BHCountdown.h"

@interface BHCountdown ()

@property (assign, nonatomic, readwrite) NSInteger secondsRemaining;
@property (assign, nonatomic, readwrite) BOOL completed;

@end

@implementation BHCountdown

+ (id)countdownWithSeconds:(NSInteger)seconds
{
    BHCountdown *countdown = [[BHCountdown alloc] init];
    countdown.secondsRemaining = seconds;
    [countdown letOneSecondElapse];
    return countdown;
}

- (void)letOneSecondElapse
{
    __weak typeof(self) weakSelf = self;

    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        weakSelf.secondsRemaining = MAX(0, weakSelf.secondsRemaining - 1);
        if (weakSelf.secondsRemaining > 0) {
            [weakSelf letOneSecondElapse];
        } else {
            weakSelf.completed = YES;
        }
    });
}

@end


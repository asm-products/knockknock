//
//  LQAudioManager.h
//  letterquest
//
//  Created by Brian Hammond on 8/4/12.
//  Copyright (c) 2012 Fictorial LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

enum
{
    kEffectKnock,
    kEffectCount
};

@interface LQAudioManager : NSObject

+ (LQAudioManager *)sharedManager;
- (void)playEffect:(int)effectId;

@property (nonatomic, assign) BOOL soundEnabled;

@end

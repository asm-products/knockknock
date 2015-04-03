//
//  LQAudioManager.m
//  letterquest
//
//  Created by Brian Hammond on 8/4/12.
//  Copyright (c) 2012 Fictorial LLC. All rights reserved.
//


#import <AudioToolbox/AudioServices.h>
#import "LQAudioManager.h"

static NSString * const kDefaultsKeyMusicDisabled = @"LQMusicDisabled";
static NSString * const kDefaultsKeySoundDisabled = @"LQSoundDisabled";

@implementation LQAudioManager
{
    SystemSoundID _soundIDs[kEffectCount];
}

+ (LQAudioManager *)sharedManager
{
    static dispatch_once_t once;
    static id sharedInstance;

    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });

    return sharedInstance;
}

- (id)init
{
    self = [super init];

    if (self) {
        NSArray *sounds = @[ @"knock.caf" ];

        for (int i = 0; i < kEffectCount; ++i) {
            NSString *soundPath = [[NSBundle mainBundle] pathForResource:[sounds objectAtIndex:i] ofType:nil];
            CFURLRef soundURL = (__bridge CFURLRef)[NSURL fileURLWithPath:soundPath];
            AudioServicesCreateSystemSoundID(soundURL, &_soundIDs[i]);
        }

        self.soundEnabled = ![[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsKeySoundDisabled];
    }

    return self;
}

- (void)playEffect:(int)effectId
{
    NSParameterAssert(effectId >= 0 && effectId < kEffectCount);

    if (!_soundEnabled)
        return;

    AudioServicesPlaySystemSound(_soundIDs[effectId]);
}

- (void)setSoundEnabled:(BOOL)isSoundEnabled
{
    _soundEnabled = isSoundEnabled;

    [[NSUserDefaults standardUserDefaults] setBool:!isSoundEnabled forKey:kDefaultsKeySoundDisabled];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    DDLogInfo(@"sounds are %@", _soundEnabled ? @"ON" : @"OFF");
}

@end

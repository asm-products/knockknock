//
//  CollageFinalizer.m
//  Knock Knock
//
//  Created by Brian Hammond on 2/10/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import "CollageFinalizer.h"

static NSString * const kSaveKey = @"collagesToBeFinalized";

@implementation CollageFinalizer
{
    NSMutableDictionary *_collageIDsToBeFinalized;   // object id => date created
}

+ (instancetype)sharedFinalizer
{
    static dispatch_once_t onceToken;
    static CollageFinalizer *sharedInstance;
    dispatch_once(&onceToken, ^{
        sharedInstance = [CollageFinalizer new];
    });
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        _collageIDsToBeFinalized = [[[NSUserDefaults standardUserDefaults] objectForKey:kSaveKey] mutableCopy];
        if (!_collageIDsToBeFinalized) {
            _collageIDsToBeFinalized = [NSMutableDictionary dictionary];
        }
        DDLogWarn(@"%d collages to be finalized soon", _collageIDsToBeFinalized.count);
        [_collageIDsToBeFinalized enumerateKeysAndObjectsUsingBlock:^(NSString *collageObjectID, NSDate *dateCreated, BOOL *stop) {
            [self finalizeLater:collageObjectID dateCreated:dateCreated];
        }];
    }
    return self;
}

- (void)finalizeLater:(NSString *)collageObjectID
{
    [self finalizeLater:collageObjectID dateCreated:[NSDate date]];
}

- (void)finalizeLater:(NSString *)collageObjectID dateCreated:(NSDate *)dateCreated
{
    NSTimeInterval timeSinceCreated = [[NSDate date] timeIntervalSinceDate:dateCreated];
    NSTimeInterval timeToWait = kCollageFinalizedDuration - timeSinceCreated;
    if (timeToWait > 0) {
        __weak typeof(self) weakSelf = self;
        [self bk_performBlock:^(id sender) {
            [weakSelf finalizeNow:collageObjectID];
        } afterDelay:timeToWait];
    } else {
        [self finalizeNow:collageObjectID];
    }
}

- (void)finalizeNow:(NSString *)collageObjectID
{
    [PFCloud callFunctionInBackground:@"finalizeCollage" withParameters:@{ @"collageID": collageObjectID } block:^(NSNumber *participantCount, NSError *error) {
        if (error) {
            DDLogError(@"Failed to finalize collage: %@", [error localizedDescription]);
        } else {
            DDLogInfo(@"Collage %@ has been finalized!", collageObjectID);

            if ([participantCount integerValue] == 1) {
                // This is an unanswered knock; only the initiator was involved.

                dispatch_async(dispatch_get_main_queue(), ^{
                    [UIAlertView bk_showAlertViewWithTitle:@"knockknock" message:@"Sorry, no participants responded!" cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
                });
            }

            [_collageIDsToBeFinalized removeObjectForKey:collageObjectID];

            [[NSUserDefaults standardUserDefaults] setObject:_collageIDsToBeFinalized forKey:kSaveKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }];
}

@end

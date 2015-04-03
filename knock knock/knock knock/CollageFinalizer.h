//
//  CollageFinalizer.h
//  Knock Knock
//
//  Created by Brian Hammond on 2/10/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import <Foundation/Foundation.h>

// These things only last a minute and there's no Parse bg
// job that can be used to run every second to check on to-be-finalized collages
// since that would eat up quota. So we have the initiator do it.
// We add collage object IDs that the local user initiated here and have this finalizer-manager
// finalize those collages a minute later.
// If the app goes bye-bye before a collage can be finalized, this finalizer-manager
// will finalize it once the user returns.

@interface CollageFinalizer : NSObject

+ (instancetype)sharedFinalizer;
- (void)finalizeLater:(NSString *)collageObjectID dateCreated:(NSDate *)dateCreated;
- (void)finalizeLater:(NSString *)collageObjectID;

@end

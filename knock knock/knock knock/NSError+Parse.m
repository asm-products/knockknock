//
//  NSError+Parse.m
//  Balloon
//
//  Created by Brian Hammond on 6/25/14.
//  Copyright (c) 2014 J32 Productions LLC. All rights reserved.
//

#import "NSError+Parse.h"

@implementation NSError (Parse)

- (NSString *)codeToMessage
{
    NSInteger code = self.code;

    if (code == kPFErrorInternalServer)
        return @"Internal server error. No information available.";
    if (code == kPFErrorConnectionFailed)
        return @"Server connection failed.";
    if (code == kPFErrorObjectNotFound)
        return @"Object doesn't exist, or has an incorrect password.";
    if (code == kPFErrorInvalidQuery)
        return @"You tried to find values matching a datatype that doesn't support exact database matching, like an array or a dictionary.";
    if (code == kPFErrorInvalidClassName)
        return @"Missing or invalid classname. Classnames are case-sensitive. They must start with a letter, and a-zA-Z0-9_ are the only valid characters.";
    if (code == kPFErrorMissingObjectId)
        return @"Missing object id.";
    if (code == kPFErrorInvalidKeyName)
        return @"Invalid key name. Keys are case-sensitive. They must start with a letter, and a-zA-Z0-9_ are the only valid characters.";
    if (code == kPFErrorInvalidPointer)
        return @"Malformed pointer. Pointers must be arrays of a classname and an object id.";
    if (code == kPFErrorInvalidJSON)
        return @"Malformed json object. A json dictionary is expected.";
    if (code == kPFErrorCommandUnavailable)
        return @"Tried to access a feature only available internally.";
    if (code == kPFErrorIncorrectType)
        return @"Field set to incorrect type.";
    if (code == kPFErrorInvalidChannelName)
        return @"Invalid channel name. A channel name is either an empty string (the broadcast channel) or contains only a-zA-Z0-9_ characters and starts with a letter.";
    if (code == kPFErrorInvalidDeviceToken)
        return @"Invalid device token.";
    if (code == kPFErrorPushMisconfigured)
        return @"Push is misconfigured. See details to find out how.";
    if (code == kPFErrorObjectTooLarge)
        return @"The object is too large.";
    if (code == kPFErrorOperationForbidden)
        return @"That operation isn't allowed for clients.";
    if (code == kPFErrorCacheMiss)
        return @"The results were not found in the cache.";
    if (code == kPFErrorInvalidNestedKey)
        return @"Keys in NSDictionary values may not include '$' or '.'.";
    if (code == kPFErrorInvalidFileName)
        return @"Invalid file name. A file name contains only a-zA-Z0-9_. characters and is between 1 and 36 characters.";
    if (code == kPFErrorInvalidACL)
        return @"Invalid ACL. An ACL with an invalid format was saved. This should not happen if you use PFACL.";
    if (code == kPFErrorTimeout)
        return @"The request timed out on the server. Typically this indicates the request is too expensive.";
    if (code == kPFErrorInvalidEmailAddress)
        return @"The email address was invalid.";
    if (code == kPFErrorDuplicateValue)
        return @"A unique field was given a value that is already taken.";
    if (code == kPFErrorInvalidRoleName)
        return @"Role's name is invalid.";
    if (code == kPFErrorExceededQuota)
        return @"Exceeded an application quota.  Upgrade to resolve.";
    if (code == kPFScriptError)
        return [self cloudCodeErrorText];
    if (code == kPFValidationError)
        return @"Cloud Code validation failed.";
    if (code == kPFErrorReceiptMissing)
        return @"Product purchase receipt is missing";
    if (code == kPFErrorInvalidPurchaseReceipt)
        return @"Product purchase receipt is invalid";
    if (code == kPFErrorPaymentDisabled)
        return @"Payment is disabled on this device";
    if (code == kPFErrorInvalidProductIdentifier)
        return @"The product identifier is invalid";
    if (code == kPFErrorProductNotFoundInAppStore)
        return @"The product is not found in the App Store";
    if (code == kPFErrorInvalidServerResponse)
        return @"The Apple server response is not valid";
    if (code == kPFErrorProductDownloadFileSystemFailure)
        return @"Product fails to download due to file system error";
    if (code == kPFErrorInvalidImageData)
        return @"Fail to convert data to image.";
    if (code == kPFErrorUnsavedFile)
        return @"Unsaved file.";
    if (code == kPFErrorFileDeleteFailure)
        return @"Fail to delete file.";
    if (code == kPFErrorUsernameMissing)
        return @"Username is missing or empty";
    if (code == kPFErrorUserPasswordMissing)
        return @"Password is missing or empty";
    if (code == kPFErrorUsernameTaken)
        return @"Mobile number is already in use";
    if (code == kPFErrorUserEmailTaken)
        return @"Email has already been taken";
    if (code == kPFErrorUserEmailMissing)
        return @"The email is missing, and must be specified";
    if (code == kPFErrorUserWithEmailNotFound)
        return @"A user with the specified email was not found";
    if (code == kPFErrorUserCannotBeAlteredWithoutSession)
        return @"The user cannot be altered by a client without the session.";
    if (code == kPFErrorUserCanOnlyBeCreatedThroughSignUp)
        return @"Users can only be created through sign up";
    if (code == kPFErrorFacebookAccountAlreadyLinked)
        return @"An existing Facebook account already linked to another user.";
    if (code == kPFErrorAccountAlreadyLinked)
        return @"An existing account already linked to another user.";
    if (code == kPFErrorUserIdMismatch)
        return @"User ID mismatch";
    if (code == kPFErrorFacebookIdMissing)
        return @"Facebook id missing from request";
    if (code == kPFErrorLinkedIdMissing)
        return @"Linked id missing from request";
    if (code == kPFErrorFacebookInvalidSession)
        return @"Invalid Facebook session";
    if (code == kPFErrorInvalidLinkedSession)
        return @"Invalid linked session";

    return nil;
}

- (NSString *)cloudCodeErrorText
{
    if (self.userInfo[@"error"]) {
        NSString *error = self.userInfo[@"error"];

#if DEBUG
        return error;
#else
        if ([error rangeOfString:@"Error"].location != NSNotFound) {
            return @"Internal server error";
        }
#endif

        return nil;
    }

    return @"Cloud Code script had an error.";
}

- (void)displayParseError:(NSString *)context
{
    NSString *reason = [self codeToMessage];

    NSString *errorMessage;
    if (context) {
        errorMessage = [NSString stringWithFormat:@"%@:\n\n%@", context, reason ? reason : [self localizedDescription]];
    } else {
        errorMessage = reason ? reason : [self localizedDescription];
    }

    DDLogError(@"ERROR: %@ %@", errorMessage, self.userInfo[@"error"]);

    dispatch_async(dispatch_get_main_queue(), ^{
        [UIAlertView bk_showAlertViewWithTitle:@"Error" message:errorMessage cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
    });
}

@end

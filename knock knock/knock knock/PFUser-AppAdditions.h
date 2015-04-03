@interface PFUser (AppAdditions)

- (NSString *)pushChannelName;   // u objectId
- (void)subscribeToMyChannel;
- (void)unsubscribeFromMyChannel;

- (void)refresh;

- (NSString *)displayName;

+ (void)loginWithFacebookBlock:(PFBooleanResultBlock)block;
- (void)linkWithFacebookBlock:(PFBooleanResultBlock)block;

+ (void)loginWithTwitterBlock:(PFBooleanResultBlock)block;
- (void)linkWithTwitterBlock:(PFBooleanResultBlock)block;

- (NSString *)twitterScreenName;
- (void)makeTwitterAPICall:(NSString *)url block:(PFIdResultBlock)block;

@end
#import "UIFont+StyleSupport.h"

@implementation UIFont (StyleSupport)

+ (UIFont *)headlineFont
{
  if ([UIFont respondsToSelector:@selector(preferredFontForTextStyle:)])
    return [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];

  return [UIFont boldSystemFontOfSize:18];
}

+ (UIFont *)bodyFont
{
  if ([UIFont respondsToSelector:@selector(preferredFontForTextStyle:)])
    return [UIFont preferredFontForTextStyle:UIFontTextStyleBody];

  return [UIFont systemFontOfSize:17];
}

+ (UIFont *)captionFont
{
  if ([UIFont respondsToSelector:@selector(preferredFontForTextStyle:)])
    return [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];

  return [UIFont systemFontOfSize:12];
}

@end

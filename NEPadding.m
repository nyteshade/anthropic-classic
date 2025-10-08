#import "NEPadding.h"

NEPadding NEMakePadding(CGFloat t, CGFloat r, CGFloat b, CGFloat l) 
{
  return (NEPadding) { t, r, b, l };
}

NEPadding NEMakeEqualPadding(CGFloat vertical, CGFloat horizontal) 
{
  return (NEPadding) { vertical, horizontal, vertical, horizontal };
}

NEPadding NEMakeUniformPadding(CGFloat amount) 
{
  return (NEPadding) { amount, amount, amount, amount };
}

BOOL NEIsEmptyPadding(NEPadding padding)
{
  return (
    padding.top == 0 &&
    padding.right == 0 &&
    padding.bottom == 0 &&
    padding.left == 0
  );
}

const NEPadding NEZeroPadding = { 0 };

@implementation NSValue (NEPadding)
+ (NSValue*)valueWithPadding:(NEPadding)padding 
{
  NSRect _padding = NSMakeRect(padding.top, padding.right, padding.bottom, padding.left);
  return [self valueWithRect:_padding];
}

- (NEPadding)paddingValue 
{
  NSRect r = [self rectValue];
  
  return (NEPadding) { r.origin.x, r.origin.y, r.size.width, r.size.height };
}
@end

#import "Hig.h"
#import "AnthropicClassic.h"

@implementation Hig

+ (CGFloat)wide                   { return 24; }
+ (CGFloat)comfort                { return 16; }
+ (CGFloat)narrow                 { return 8; }
+ (CGFloat)tight                  { return 4; }

+ (CGFloat)wide:(CGFloat)scale    { return [self wide] * scale; }
+ (CGFloat)comfort:(CGFloat)scale { return [self comfort] * scale; }
+ (CGFloat)narrow:(CGFloat)scale  { return [self narrow] * scale; }
+ (CGFloat)tight:(CGFloat)scale   { return [self tight] * scale; }

+ (CGFloat)fontMin                { return 10; }
+ (CGFloat)fontDef                { return 13; }

+ (CGSize)controlSizeMin          { return (CGSize){ 20, 20 }; }
+ (CGSize)controlSizeDef          { return (CGSize){ 28, 28 }; }
@end

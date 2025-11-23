#import <Foundation/Foundation.h>

@interface Hig: NSObject

+ (CGFloat)wide;
+ (CGFloat)comfort;
+ (CGFloat)narrow;
+ (CGFloat)tight;

+ (CGFloat)wide:(CGFloat)scale;
+ (CGFloat)comfort:(CGFloat)scale;
+ (CGFloat)narrow:(CGFloat)scale;
+ (CGFloat)tight:(CGFloat)scale;

+ (CGFloat)fontMin;
+ (CGFloat)fontDef;

+ (CGSize)controlSizeMin;
+ (CGSize)controlSizeDef;

@end

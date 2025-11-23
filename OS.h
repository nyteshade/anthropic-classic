#ifndef NE_OS_H
#define NE_OS_H

#import <Cocoa/Cocoa.h>

@interface OS: NSObject

+ (BOOL)isTiger;
+ (BOOL)isLeopard;
+ (BOOL)isPowerPC;
+ (BOOL)isIntel;

@end

#endif

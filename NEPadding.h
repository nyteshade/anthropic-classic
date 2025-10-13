//
//  NEPadding.h
//  anthropic-classic
//
//  Created by Brielle Harrison on 10/3/25.
//  Copyright 2025 Nyteshade Enterprises. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TigerCompat.h"

typedef struct NEPadding {
  CGFloat top;
  CGFloat right;
  CGFloat bottom;
  CGFloat left;
} NEPadding;

extern const NEPadding NEZeroPadding;

NEPadding NEMakePadding(CGFloat t, CGFloat r, CGFloat b, CGFloat l);
NEPadding NEMakeEqualPadding(CGFloat vertical, CGFloat horizontal);
NEPadding NEMakeUniformPadding(CGFloat amount);

BOOL NEIsEmptyPadding(NEPadding);

@interface NSValue (NEPadding)
+ (NSValue*)valueWithPadding:(NEPadding)padding;

- (NEPadding)paddingValue;
@end

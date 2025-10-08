//
//  NSView+Essentials.h
//  anthropic-classic
//
//  Created by Brielle Harrison on 10/3/25.
//  Copyright 2025 Nyteshade Enterprises. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NEPadding.h"

@interface NSView (Essentials)
// MARK: - PaddedBounds
- (NSRect)paddedBounds;
- (BOOL)areBoundsPadded;
- (void)setBoundsPadded:(BOOL)spoofBounds;

// MARK: - Padding
- (void)setPadding:(NEPadding)padding;
- (void)setPaddingTop:(CGFloat)t 
                right:(CGFloat)r
               bottom:(CGFloat)b
                 left:(CGFloat)l;
- (void)setVerticalPadding:(CGFloat)vertical;
- (void)setVerticalPadding:(CGFloat)vertical 
     withHorizontalPadding:(CGFloat)horizontal;
- (NEPadding)padding;

// MARK: - Background
- (void)setBackgroundColor:(NSColor *)color;
- (NSColor *)backgroundColor;

// MARK: - Border
- (void)setBorderColor:(NSColor *)color;
- (NSColor *)borderColor;
- (void)setBorderWidth:(float)width;
- (float)borderWidth;
@end

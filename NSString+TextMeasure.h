//
//  NSString+TextMeasure.h
//  anthropic-classic
//
//  Created by Brielle Harrison on 10/4/25.
//  Copyright 2025 Nyteshade Enterprises. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSString (TextMeasure)

/**
 Returns the size required to draw the string on a single line with the given
 font. No wrapping is performed.

 @param font The NSFont to measure with. Must be non-nil.
 @return NSSize where width/height are ceiled to whole pixels for crisp layout.
 */
- (NSSize)singleLineSizeWithFont:(NSFont *)font;

/**
 Returns the size required to draw the string wrapped to a maximum width using
 the given font. This uses the Cocoa text system (NSTextStorage/NSLayoutManager/
 NSTextContainer) for accurate metrics on all OS X versions including 10.4.

 @param font The NSFont to measure with. Must be non-nil.
 @param maxWidth The maximum width before wrapping occurs. Use a large value
                (e.g., FLT_MAX) to effectively disable wrapping.
 @return NSSize where width/height are ceiled to whole pixels.
 */
- (NSSize)wrappedSizeWithFont:(NSFont *)font
                        maxWidth:(CGFloat)maxWidth;

@end


/**
 Attributed-string variants that respect any attributes already present
 (font, paragraph style, kerning, ligatures, etc.).
 */
@interface NSAttributedString (TextMeasure)

/**
 Single-line measurement for attributed strings (no wrapping).
 If multiple fonts exist, their metrics are honored.

 @return NSSize with ceiled width/height.
 */
- (NSSize)singleLineSize;

/**
 Wrapped measurement for attributed strings.

 @param maxWidth The maximum width before wrapping occurs.
 @return NSSize with ceiled width/height.
 */
- (NSSize)wrappedSizeWithMaxWidth:(CGFloat)maxWidth;

@end

#import "NSString+Sizing.h"

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@implementation NSString(Sizing)

/**
 * Calculates the height of text with word wrapping for a given maximum width.
 *
 * This method measures text using the specified font and wraps it at word boundaries
 * to fit within the given pixel width. It returns detailed information about the
 * wrapped text including total height, number of lines, and the wrapped text itself.
 *
 * @param text The text string to measure and wrap. If nil or empty, returns zero height.
 * @param maxWidth Maximum width in pixels that the text should occupy. Text will wrap
 *                 to multiple lines if it exceeds this width.
 * @param font The NSFont to use for text measurement. This determines both the character
 *             dimensions and the default line height.
 * @param lineHeightMultiplier A multiplier applied to the font's default line height
 *                             to determine spacing between lines. Common values are
 *                             1.0 (single-spaced) to 2.0 (double-spaced). A value of
 *                             1.2 provides comfortable reading spacing.
 *
 * @return NSDictionary containing the following keys:
 *         - @"height" (NSNumber - float): Total height in pixels needed to display all lines
 *         - @"lines" (NSNumber - int): Number of lines after wrapping
 *         - @"wrappedLines" (NSArray): Array of NSString objects, each representing one line
 *         - @"lineHeight" (NSNumber - float): Calculated line height in pixels
 *
 * @note This method uses NSString's sizeWithAttributes: for text measurement, which
 *       provides pixel-accurate dimensions for the specified font.
 * @note Word wrapping occurs at space boundaries. Words longer than maxWidth will
 *       occupy their own line and may extend beyond the specified width.
 *
 * @since Mac OS X 10.4 (Tiger)
 *
 * Example usage:
 * @code
 * NSFont *myFont = [NSFont fontWithName:@"Lucida Grande" size:13.0];
 * NSDictionary *result = [self calculateTextHeight:@"This is a long text string that needs wrapping"
 *                                    maxWidthPixels:200.0
 *                                              font:myFont
 *                                 lineHeightMultiplier:1.2];
 * 
 * float totalHeight = [[result objectForKey:@"height"] floatValue];
 * NSArray *lines = [result objectForKey:@"wrappedLines"];
 * @endcode
 */
- (NSDictionary *)calculateTextHeight:(NSString *)text 
                       maxWidthPixels:(float)maxWidth 
                                 font:(NSFont *)font 
                 lineHeightMultiplier:(float)lineHeightMultiplier {
  
  if (!text || [text length] == 0) {
    return [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithFloat:0], @"height",
        [NSNumber numberWithInt:0], @"lines",
        [NSArray array], @"wrappedLines",
        nil];
  }
  
  // Set up attributes for text measurement
  NSDictionary *attributes = [NSDictionary dictionaryWithObject:font 
                              forKey:NSFontAttributeName];
  
  // Get line height from layout manager
  NSLayoutManager *layoutManager = [[[NSLayoutManager alloc] init] autorelease];
  float singleLineHeight = [layoutManager defaultLineHeightForFont:font];
  float lineHeight = singleLineHeight * lineHeightMultiplier;
  
  // Word wrapping algorithm
  NSArray *words = [text componentsSeparatedByString:@" "];
  NSMutableArray *lines = [NSMutableArray array];
  NSMutableArray *currentLine = [NSMutableArray array];
  
  NSEnumerator *wordEnumerator = [words objectEnumerator];
  NSString *word;
  
  while ((word = [wordEnumerator nextObject])) {
    NSString *testLine;
    if ([currentLine count] > 0) {
      testLine = [[currentLine arrayByAddingObject:word] componentsJoinedByString:@" "];
    } else {
      testLine = word;
    }
    
    NSSize testSize = [testLine sizeWithAttributes:attributes];
    
    if (testSize.width <= maxWidth) {
      [currentLine addObject:word];
    } else {
      if ([currentLine count] > 0) {
        [lines addObject:[currentLine componentsJoinedByString:@" "]];
        [currentLine removeAllObjects];
        [currentLine addObject:word];
      } else {
        // Single word exceeds max width
        [lines addObject:word];
      }
    }
  }
  
  if ([currentLine count] > 0) {
    [lines addObject:[currentLine componentsJoinedByString:@" "]];
  }
  
  // Calculate total height
  float totalHeight = 0;
  if ([lines count] > 0) {
    // First line uses actual text height, subsequent lines add lineHeight
    NSString *firstLine = [lines objectAtIndex:0];
    NSSize firstLineSize = [firstLine sizeWithAttributes:attributes];
    totalHeight = firstLineSize.height + ([lines count] - 1) * lineHeight;
  }
  
  return [NSDictionary dictionaryWithObjectsAndKeys:
      [NSNumber numberWithFloat:totalHeight], @"height",
      [NSNumber numberWithInt:[lines count]], @"lines",
      lines, @"wrappedLines",
      [NSNumber numberWithFloat:lineHeight], @"lineHeight",
      nil];
}

@end
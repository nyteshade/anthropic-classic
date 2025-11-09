#import "NSString+TextMeasure.h"
#import <float.h> // FLT_MAX on Tiger

// MARK: - Internals

static inline NSSize CeilSize(NSSize s)
{
  s.width  = ceilf(s.width);
  s.height = ceilf(s.height);
  return s;
}

/**
 Core Tiger-safe measurer that drives the Cocoa text system.
 This is used by both NSString and NSAttributedString helpers.

 @param attributedText An attributed string to measure.
 @param containerSize  The text container size (width limits wrapping; height
                       can be very large like FLT_MAX).
 @param singleLine     If YES, disables wrapping by giving a very large width.
 @return Used rect size, ceiled.
 */
static NSSize MeasureAttributedString(NSAttributedString *attributedText,
                                         NSSize containerSize,
                                         BOOL singleLine)
{
  NSTextStorage *storage;
  NSLayoutManager *layout;
  NSTextContainer *container;
  NSRect used;

  if (!attributedText)
  {
    return NSMakeSize(0, 0);
  }

  // Storage
  storage = [[NSTextStorage alloc] initWithAttributedString:attributedText];

  // Layout manager
  layout = [[NSLayoutManager alloc] init];

  // Container
  if (singleLine)
  {
    // Give the container a "huge" width to avoid wrapping entirely.
    containerSize.width = FLT_MAX;
  }
  if (containerSize.height <= 0)
  {
    containerSize.height = FLT_MAX;
  }

  container = [[NSTextContainer alloc] initWithSize:containerSize];

  // Remove default left/right padding so measured width matches what you draw
  // with -drawInRect: or Core Text equivalents.
  [container setLineFragmentPadding:0.0f];

  // Wire them up (order matters)
  [layout addTextContainer:container];
  [storage addLayoutManager:layout];

  // Force layout and get used rect
  (void)[layout glyphRangeForTextContainer:container];
  used = [layout usedRectForTextContainer:container];

  // Clean up (Tiger ARC is not available; keep it manual if you're on 10.4)
  [container release];
  [layout release];
  [storage release];

  return CeilSize(used.size);
}

// MARK: - NSString

@implementation NSString (TextMeasure)

- (NSSize)singleLineSizeWithFont:(NSFont *)font
{
  NSDictionary *attrs;
  NSAttributedString *attr;

  if (!font || [self length] == 0)
  {
    return NSMakeSize(0, 0);
  }

  attrs = [NSDictionary dictionaryWithObject:font
                                      forKey:NSFontAttributeName];
  attr = [[[NSAttributedString alloc] initWithString:self attributes:attrs] autorelease];

  return MeasureAttributedString(attr, NSMakeSize(FLT_MAX, FLT_MAX), YES);
}

- (NSSize)wrappedSizeWithFont:(NSFont *)font
                        maxWidth:(CGFloat)maxWidth
{
  NSDictionary *attrs;
  NSAttributedString *attr;

  if (!font || [self length] == 0 || maxWidth <= 0)
  {
    return NSMakeSize(0, 0);
  }

  attrs = [NSDictionary dictionaryWithObject:font
                                      forKey:NSFontAttributeName];
  attr = [[[NSAttributedString alloc] initWithString:self attributes:attrs] autorelease];

  return MeasureAttributedString(attr, NSMakeSize(maxWidth, FLT_MAX), NO);
}

@end

// MARK: - NSAttributedString

@implementation NSAttributedString (TextMeasure)

- (NSSize)singleLineSize
{
  if ([self length] == 0)
  {
    return NSMakeSize(0, 0);
  }
  return MeasureAttributedString(self, NSMakeSize(FLT_MAX, FLT_MAX), YES);
}


- (NSSize)wrappedSizeWithMaxWidth:(CGFloat)maxWidth
{
  if ([self length] == 0 || maxWidth <= 0)
  {
    return NSMakeSize(0, 0);
  }
  return MeasureAttributedString(self, NSMakeSize(maxWidth, FLT_MAX), NO);
}

@end

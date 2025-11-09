//
//  NESizingHelpers.m
//  Tiger-safe sizing and layout helpers for AppKit controls.
//

#import "NESizingHelpers.h"
#import "TigerCompat.h"
#import <float.h> // FLT_MAX

// Tiger compatibility: NSHeight, NSMinY, NSWidth macros
#ifndef NSHeight
#define NSHeight(rect) ((rect).size.height)
#endif

#ifndef NSWidth
#define NSWidth(rect) ((rect).size.width)
#endif

#ifndef NSMinY
#define NSMinY(rect) ((rect).origin.y)
#endif

// Tiger compatibility: NSZeroRect constant
#ifndef NSZeroRect
static const NSRect kNSZeroRect = {{0, 0}, {0, 0}};
#define NSZeroRect kNSZeroRect
#endif

// Tiger compatibility: NSMiniControlSize
#ifndef NSMiniControlSize
#define NSMiniControlSize NSSmallControlSize
#endif

// Tiger compatibility: systemFontSizeForControlSize
#if MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_5
static CGFloat SystemFontSizeForControlSize(NSControlSize controlSize)
{
  switch (controlSize)
  {
    case NSSmallControlSize:
      return 11.0;
    case NSRegularControlSize:
    default:
      return 13.0;
  }
}
#else
#define SystemFontSizeForControlSize(cs) [NSFont systemFontSizeForControlSize:cs]
#endif

// MARK: - Internal utilities

static inline CGFloat NECeil(CGFloat v)
{
  return ceilf((float)v);
}

static inline NSSize NECeilSize(NSSize s)
{
  s.width  = NECeil(s.width);
  s.height = NECeil(s.height);
  return s;
}

// MARK: - Button sizing

CGFloat NSButtonMinimumWidthForControlSize(NSControlSize size)
{
  switch (size)
  {
    case NSMiniControlSize:
      return 50.0f;
    case NSSmallControlSize:
      return 64.0f;
    case NSRegularControlSize:
    default:
      return 72.0f;
  }
}

void NSButtonSizeToFitWithMinimum(NSButton *button)
{
  CGFloat fsize;
  NSFont *font;
  NSRect frame;
  NSSize size;
  CGFloat minW;
  NSControlSize cs;

  if (!button)
  {
    return;
  }

  // Ensure font matches control size before measuring
  cs = [button controlSize];
  fsize = SystemFontSizeForControlSize(cs);
  font = [NSFont systemFontOfSize:fsize];
  [button setFont:font];

  // Natural size for current title/image/bezel
  [button sizeToFit];

  // Clamp width to a sensible minimum
  frame = [button frame];
  size = frame.size;
  minW = NSButtonMinimumWidthForControlSize(cs);
  if (size.width < minW)
  {
    size.width = minW;
  }

  frame.size = NECeilSize(size);
  [button setFrame:frame];
}

// MARK: - Baseline alignment

CGFloat BaselineOffsetForView(NSView *view, NSFont *font)
{
  NSControl *ctrl;
  NSCell *cell;
  NSRect bounds;
  NSRect titleRect;

  if (!view || !font)
  {
    return 0.0f;
  }

  if ([view isKindOfClass:[NSControl class]])
  {
    ctrl = (NSControl *)view;
    cell = [ctrl cell];
    if (cell)
    {
      bounds = [view bounds];
      // titleRectForBounds: exists for common text cells on Tiger
      titleRect = [cell titleRectForBounds:bounds];
      return NSMinY(titleRect) + NECeil([font ascender]);
    }
  }

  // Fallback: approximate with font ascender
  return NECeil([font ascender]);
}

void AlignBaselines(NSView *leftView, NSView *rightView)
{
  NSFont *lf;
  NSFont *rf;
  CGFloat lb;
  CGFloat rb;
  NSRect lfF;
  NSRect rfF;
  CGFloat delta;

  if (!leftView || !rightView)
  {
    return;
  }

  lf = nil;
  rf = nil;

  if ([leftView isKindOfClass:[NSControl class]])
  {
    lf = [(NSControl *)leftView font];
  }
  if ([rightView isKindOfClass:[NSControl class]])
  {
    rf = [(NSControl *)rightView font];
  }

  lb = BaselineOffsetForView(leftView, lf);
  rb = BaselineOffsetForView(rightView, rf);

  lfF = [leftView frame];
  rfF = [rightView frame];

  // Shift rightView by the baseline delta
  delta = (NSMinY(lfF) + lb) - (NSMinY(rfF) + rb);
  rfF.origin.y += delta;
  [rightView setFrame:rfF];
}

// MARK: - Form-row layout

void LayoutFormRow(NSView *container,
                   NSView *label,
                   NSView *field,
                   NSButton *button,
                   CGFloat containerWidth)
{
  CGFloat margin;
  CGFloat hGap;
  CGFloat bGap;
  CGFloat minFieldWidth;
  NSRect lF;
  NSRect fF;
  NSRect bF;
  CGFloat x;
  CGFloat fieldRight;
  NSRect cb;
  CGFloat rowHeight;
  CGFloat baseY;

  if (!container)
  {
    return;
  }

  margin = 20.0f;         // outer content margin
  hGap = 8.0f;            // gap between label and field
  bGap = 12.0f;           // gap between field and trailing button
  minFieldWidth = 80.0f;

  // Initialize frames to zero
  // Note: Can't use ternary operator with structs on Tiger's gcc-4.0
  lF = NSZeroRect;
  fF = NSZeroRect;
  bF = NSZeroRect;
  
  if (label)
  {
    lF = [label frame];
  }
  if (field)
  {
    fF = [field frame];
  }
  if (button)
  {
    bF = [button frame];
  }

  // 1) Natural sizes
  if (label && [label isKindOfClass:[NSControl class]])
  {
    [(NSControl *)label sizeToFit];
    lF = [label frame];
  }
  if (field && [field isKindOfClass:[NSControl class]])
  {
    [(NSControl *)field sizeToFit];
    fF = [field frame];
  }
  if (button)
  {
    NSButtonSizeToFitWithMinimum(button);
    bF = [button frame];
  }

  // 2) Horizontal positions
  x = margin;

  if (label)
  {
    lF.origin.x = x;
    x += lF.size.width + hGap;
  }

  if (button)
  {
    bF.origin.x = containerWidth - margin - bF.size.width;
  }

  if (field)
  {
    fieldRight = button ? (bF.origin.x - bGap) : (containerWidth - margin);
    fF.origin.x = x;
    fF.size.width = fieldRight - x;
    if (fF.size.width < minFieldWidth)
    {
      fF.size.width = minFieldWidth;
    }
  }

  // 3) Vertical alignment (center within container's bounds height)
  cb = [container bounds];
  rowHeight = 0.0f;
  if (label)
  {
    rowHeight = MAX(rowHeight, lF.size.height);
  }
  if (field)
  {
    rowHeight = MAX(rowHeight, fF.size.height);
  }
  if (button)
  {
    rowHeight = MAX(rowHeight, bF.size.height);
  }
  baseY = NECeil((NSHeight(cb) - rowHeight) / 2.0f);

  if (label)
  {
    lF.origin.y = baseY + floorf((rowHeight - lF.size.height) / 2.0f);
  }
  if (field)
  {
    fF.origin.y = baseY + floorf((rowHeight - fF.size.height) / 2.0f);
  }
  if (button)
  {
    bF.origin.y = baseY + floorf((rowHeight - bF.size.height) / 2.0f);
  }

  // 4) Commit frames
  if (label)
  {
    [label setFrame:lF];
  }
  if (field)
  {
    [field setFrame:fF];
  }
  if (button)
  {
    [button setFrame:bF];
  }
}

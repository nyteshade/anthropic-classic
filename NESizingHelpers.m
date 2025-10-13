//
//  NESizingHelpers.m
//  Tiger-safe sizing and layout helpers for AppKit controls.
//

#import "NESizingHelpers.h"
#import <float.h> // FLT_MAX

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
  switch (size) {
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
  if (!button) {
    return;
  }

  // Ensure font matches control size before measuring
  NSControlSize cs = [button controlSize];
  CGFloat fsize = [NSFont systemFontSizeForControlSize:cs];
  NSFont *font = [NSFont systemFontOfSize:fsize];
  [button setFont:font];

  // Natural size for current title/image/bezel
  [button sizeToFit];

  // Clamp width to a sensible minimum
  NSRect frame = [button frame];
  NSSize size = frame.size;
  CGFloat minW = NSButtonMinimumWidthForControlSize(cs);
  if (size.width < minW) {
    size.width = minW;
  }

  frame.size = NECeilSize(size);
  [button setFrame:frame];
}

// MARK: - Baseline alignment

CGFloat BaselineOffsetForView(NSView *view, NSFont *font)
{
  if (!view || !font) {
    return 0.0f;
  }

  if ([view isKindOfClass:[NSControl class]]) {
    NSControl *ctrl = (NSControl *)view;
    NSCell *cell = [ctrl cell];
    if (cell) {
      NSRect bounds = [view bounds];
      // titleRectForBounds: exists for common text cells on Tiger
      NSRect titleRect = [cell titleRectForBounds:bounds];
      return NSMinY(titleRect) + NECeil([font ascender]);
    }
  }

  // Fallback: approximate with font ascender
  return NECeil([font ascender]);
}

void AlignBaselines(NSView *leftView, NSView *rightView)
{
  if (!leftView || !rightView) {
    return;
  }
  NSFont *lf = nil;
  NSFont *rf = nil;

  if ([leftView isKindOfClass:[NSControl class]]) {
    lf = [(NSControl *)leftView font];
  }
  if ([rightView isKindOfClass:[NSControl class]]) {
    rf = [(NSControl *)rightView font];
  }

  CGFloat lb = BaselineOffsetForView(leftView, lf);
  CGFloat rb = BaselineOffsetForView(rightView, rf);

  NSRect lfF = [leftView frame];
  NSRect rfF = [rightView frame];

  // Shift rightView by the baseline delta
  CGFloat delta = (NSMinY(lfF) + lb) - (NSMinY(rfF) + rb);
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
  if (!container) {
    return;
  }

  const CGFloat margin = 20.0f;  // outer content margin
  const CGFloat hGap   = 8.0f;   // gap between label and field
  const CGFloat bGap   = 12.0f;  // gap between field and trailing button
  const CGFloat minFieldWidth = 80.0f;

  // 1) Natural sizes
  if (label && [label isKindOfClass:[NSControl class]]) {
    [(NSControl *)label sizeToFit];
  }
  if (field && [field isKindOfClass:[NSControl class]]) {
    [(NSControl *)field sizeToFit];
  }
  if (button) {
    NSButtonSizeToFitWithMinimum(button);
  }

  NSRect lF = label ? [label frame] : NSZeroRect;
  NSRect fF = field ? [field frame] : NSZeroRect;
  NSRect bF = button ? [button frame] : NSZeroRect;

  // 2) Horizontal positions
  CGFloat x = margin;

  if (label) {
    lF.origin.x = x;
    x += lF.size.width + hGap;
  }

  if (button) {
    bF.origin.x = containerWidth - margin - bF.size.width;
  }

  if (field) {
    CGFloat fieldRight = button ? (bF.origin.x - bGap) : (containerWidth - margin);
    fF.origin.x = x;
    fF.size.width = fieldRight - x;
    if (fF.size.width < minFieldWidth) {
      fF.size.width = minFieldWidth;
    }
  }

  // 3) Vertical alignment (center within container's bounds height)
  NSRect cb = [container bounds];
  CGFloat rowHeight = 0.0f;
  if (label) {
    rowHeight = MAX(rowHeight, lF.size.height);
  }
  if (field) {
    rowHeight = MAX(rowHeight, fF.size.height);
  }
  if (button) {
    rowHeight = MAX(rowHeight, bF.size.height);
  }
  CGFloat baseY = NECeil((NSHeight(cb) - rowHeight) / 2.0f);

  if (label) {
    lF.origin.y = baseY + floorf((rowHeight - lF.size.height) / 2.0f);
  }
  if (field) {
    fF.origin.y = baseY + floorf((rowHeight - fF.size.height) / 2.0f);
  }
  if (button) {
    bF.origin.y = baseY + floorf((rowHeight - bF.size.height) / 2.0f);
  }

  // 4) Commit frames
  if (label)  { [label setFrame:lF]; }
  if (field)  { [field setFrame:fF]; }
  if (button) { [button setFrame:bF]; }
}


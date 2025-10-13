//
//  NSView+Essentials.m
//  anthropic-classic
//
//  Created by Brielle Harrison on 10/3/25.
//  Copyright 2025 Nyteshade Enterprises. All rights reserved.
//

#import "NSView+Essentials.h"
#import "NSObject+Associations.h"
#import "NEPadding.h"

#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_4
#import <objc/objc-runtime.h>
#import <objc/objc-class.h>
#else
#import <objc/runtime.h>
#endif

NSString* NSRectToString(NSRect rect)
{
  NSMutableArray* parts = [[[NSMutableArray alloc] initWithCapacity: 8] autorelease];
  
  [parts addObject:@"Rect { "];
  [parts addObject:[NSString stringWithFormat:@"x = %f, ", rect.origin.x]];
  [parts addObject:[NSString stringWithFormat:@"y = %f, ", rect.origin.y]];
  [parts addObject:[NSString stringWithFormat:@"width = %f, ", rect.size.width]];
  [parts addObject:[NSString stringWithFormat:@"height = %f }", rect.size.height]];
  
  return [parts componentsJoinedByString:@""];  
}

NSString* NEPaddingToString(NEPadding padding)
{
  NSMutableArray* parts = [[[NSMutableArray alloc] initWithCapacity: 8] autorelease];
  
  [parts addObject:@"Padding { "];
  [parts addObject:[NSString stringWithFormat:@"top = %f, ", padding.top]];
  [parts addObject:[NSString stringWithFormat:@"right = %f, ", padding.right]];
  [parts addObject:[NSString stringWithFormat:@"bottom = %f, ", padding.bottom]];
  [parts addObject:[NSString stringWithFormat:@"left = %f }", padding.left]];
  
  return [parts componentsJoinedByString:@""];  
}

@implementation NSView (Essentials)

// MARK: - PaddedBounds
- (NSRect)paddedBounds
{
  NEPadding padding = [self padding];
  NSRect bounds = [self bounds];
  
  NSRect contentRect = NSMakeRect(
    bounds.origin.x + padding.left,
    bounds.origin.y + padding.bottom,
    bounds.size.width - padding.left - padding.right,
    bounds.size.height - padding.top - padding.bottom
  );
  
  return contentRect;
}

- (BOOL)areBoundsPadded
{
  NSNumber *paddedBounds = [self associatedValueForKey:@"padded-bounds"];
  
  if (paddedBounds)
    return [paddedBounds boolValue];
    
  return NO;
}

- (void)setBoundsPadded:(BOOL)spoofBounds
{
  [self setAssociatedValue:[NSNumber numberWithBool:spoofBounds] 
                    forKey:@"padded-bounds"];
}

- (void)setPadding:(NEPadding)padding 
{
  [self setAssociatedValue:[NSValue valueWithPadding:padding] 
                    forKey:@"padding"];
  [self setNeedsDisplay:YES];               
}

- (void)setPaddingTop:(CGFloat)t 
                right:(CGFloat)r
               bottom:(CGFloat)b
                 left:(CGFloat)l 
{
  NEPadding padding = NEMakePadding(t, r, b, l);
  
  [self setPadding:padding];
}

- (void)setVerticalPadding:(CGFloat)vertical
{
  NEPadding padding = NEMakeEqualPadding(vertical, 0);
  
  [self setPadding:padding];
}

- (void)setVerticalPadding:(CGFloat)vertical 
     withHorizontalPadding:(CGFloat)horizontal
{
  NEPadding padding = NEMakeEqualPadding(vertical, horizontal);
  
  [self setPadding:padding];
}

- (NEPadding)padding {
  NSValue *paddingValue = [self associatedValueForKey:@"padding"];
  
  if (!paddingValue)
    return NEZeroPadding;
    
  return [paddingValue paddingValue];
}

- (void)setBackgroundColor:(NSColor *)color {
	[self setAssociatedValue:color 
										forKey:@"background-color"];
	[self setNeedsDisplay:YES];
}

- (NSColor *)backgroundColor {
	NSColor *associatedColor = [self associatedValueForKey:@"background-color"];
	
	if (!associatedColor)
	{
    return [NSColor controlColor];
	}
	
  return associatedColor;
}

- (void)setBorderColor:(NSColor *)color {
	[self setAssociatedValue:color 
										forKey:@"border-color"];
	[self setNeedsDisplay:YES];
}

- (NSColor *)borderColor {
	NSColor *borderColor = [self associatedValueForKey:@"border-color"];

  return borderColor ? borderColor : [NSColor blackColor];
}

- (void)setBorderWidth:(float)width {
	[self setAssociatedValue:[NSNumber numberWithFloat:width] 
										forKey:@"border-width"];
	[self setNeedsDisplay:YES];
}

- (float)borderWidth {
	NSNumber *width = [self associatedValueForKey:@"border-width"];
	return width ? [width floatValue] : 0.0;
}

// Swizzle drawRect: to draw our essentials
+ (void)load {		
	Method original = class_getInstanceMethod(self, @selector(drawRect:));
	Method swizzled = class_getInstanceMethod(self, @selector(drawRectEssentials:));

#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_4
	IMP originalIMP = original->method_imp;
	IMP swizzledIMP = swizzled->method_imp;
	
	original->method_imp = swizzledIMP;
	swizzled->method_imp = originalIMP;
#else
	method_exchangeImplementations(original, swizzled);
#endif
}

- (NSRect)paddableBounds 
{
  NSLog(@"\npaddableBounds:areBoundsPadded = %@", [self areBoundsPadded] ? @"YES" : @"NO");
  //NSRect b = [self areBoundsPadded] ? [self paddedBounds] : [self paddableBounds];
  NSLog(@"paddableBounds:paddedBounds = %@", NSRectToString([self paddedBounds]));
  NSLog(@"paddableBounds:bounds = %@", NSRectToString([self bounds]));  
  
  if ([self areBoundsPadded])
    return [self paddedBounds];
    
  return [self paddableBounds];
}

- (void)drawRectEssentials:(NSRect)dirtyRect {
  NSGraphicsContext *context = [NSGraphicsContext currentContext];
  [context saveGraphicsState];
  
  NSColor *backgroundColor = [self backgroundColor];
  NSColor *borderColor = [self borderColor];
  CGFloat borderWidth = [self borderWidth];
    
  // First, clear the entire dirty rect to transparent
  [[NSColor clearColor] setFill];
  NSRectFillUsingOperation(dirtyRect, NSCompositeCopy);
      
  // Get actual bounds and draw border
  NSRect actualBounds = [self bounds];

  if (borderWidth > 0 && borderColor) {
      [borderColor setStroke];
      [NSBezierPath setDefaultLineWidth:borderWidth];
      NSRect borderRect = NSInsetRect(actualBounds, borderWidth/2.0, borderWidth/2.0);
      NSLog(@"borderRect - %@", NSRectToString(borderRect));
      [NSBezierPath strokeRect:borderRect];
  }
  
  // Get padded bounds for content drawing
  NSRect paddedBounds = [self paddedBounds]; 
  
  // Only proceed with content drawing if padded bounds are valid
  if (paddedBounds.size.width > 0 && paddedBounds.size.height > 0) {
      // Calculate intersection of dirtyRect with padded bounds
      NSRect contentDirtyRect = NSIntersectionRect(dirtyRect, paddedBounds);
      
      if (!NSIsEmptyRect(contentDirtyRect)) {
          // Set up clipping to padded bounds
          [NSBezierPath clipRect:paddedBounds];
          
          // Draw background color within padded bounds
          if (backgroundColor) {
            [backgroundColor setFill];
            NSRectFill(contentDirtyRect);
          }
          
          // Call the original drawRect - it will now see padded bounds
          [self drawRectEssentials:contentDirtyRect];
      }
  }
  else 
  {
    NSRect unpaddedBounds = NSIntersectionRect(dirtyRect, actualBounds);
    
    // Draw background color within padded bounds
    if (backgroundColor) {
      [backgroundColor setFill];
      NSRectFill(unpaddedBounds);
    }

    // Call the original drawRect - it will now see padded bounds
    [self drawRectEssentials:unpaddedBounds];    
  }
  
  // Restore original padding state
  //[self setBoundsPadded:NO];
  [context restoreGraphicsState];
}

@end

//
//  NEDrawer.h
//  anthropic-classic
//
//  Created by Brielle Harrison on 10/12/25.
//

#import <Cocoa/Cocoa.h>

// Tiger-compatible edge constants
typedef enum {
  NERectEdgeLeft = 0,
  NERectEdgeRight = 1,
  NERectEdgeTop = 2,
  NERectEdgeBottom = 3
} NERectEdge;

// Tiger-compatible state constants
typedef enum {
  NEDrawerStateClosing = 0,
  NEDrawerStateClosed = 1,
  NEDrawerStateOpening = 2,
  NEDrawerStateOpen = 3
} NEDrawerState;

/**
 * Non-deprecated Enhanced Drawer - A modern replacement for NSDrawer.
 * Provides full theming control while maintaining NSDrawer API compatibility.
 * Tiger-compatible and not deprecated.
 */
@interface NEDrawer : NSObject {
  // Core properties
  NSPanel *_drawerWindow;
  NSView *_contentView;
  NSWindow *_parentWindow;
  NSSize _contentSize;
  NSSize _minContentSize;
  NSSize _maxContentSize;
  NERectEdge _preferredEdge;
  NEDrawerState _state;
  float _leadingOffset;
  float _trailingOffset;
  
  // Animation
  NSTimer *_animationTimer;
  NSRect _targetFrame;
  NSRect _startFrame;
  NSTimeInterval _animationStartTime;
  float _animationDuration;
  
  // Appearance
  BOOL _isDarkMode;
  NSColor *_backgroundColor;
  
  // Delegate
  id _delegate;
  
  // Resizing support
  BOOL _isResizing;
  NSPoint _resizeStartPoint;
  NSSize _resizeStartSize;
  NSTrackingRectTag _trackingRect;  
}

/**
 * Convenience initializer that defaults to right edge.
 * Matches NSDrawer's default behavior.
 */
- (id)init;

// NSDrawer-compatible API (using NERectEdge instead of NSRectEdge)
- (id)initWithContentSize:(NSSize)contentSize preferredEdge:(NERectEdge)preferredEdge;
- (void)setContentView:(NSView *)contentView;
- (NSView *)contentView;
- (void)setContentSize:(NSSize)contentSize;
- (NSSize)contentSize;
- (void)setMinContentSize:(NSSize)minContentSize;
- (NSSize)minContentSize;
- (void)setMaxContentSize:(NSSize)maxContentSize;
- (NSSize)maxContentSize;
- (void)setPreferredEdge:(NERectEdge)preferredEdge;
- (NERectEdge)preferredEdge;
- (void)setParentWindow:(NSWindow *)parentWindow;
- (NSWindow *)parentWindow;
- (void)setDelegate:(id)delegate;
- (id)delegate;
- (void)setLeadingOffset:(float)offset;
- (float)leadingOffset;
- (void)setTrailingOffset:(float)offset;
- (float)trailingOffset;

// State control
- (void)open;
- (void)openOnEdge:(NERectEdge)edge;
- (void)close;
- (void)toggle;
- (NEDrawerState)state;

// Theming
- (void)setBackgroundColor:(NSColor *)color;
- (NSColor *)backgroundColor;
- (void)updateAppearanceForDarkMode:(BOOL)isDarkMode;

@end

// NSDrawer-compatible delegate protocol
@interface NSObject (NEDrawerDelegate)
- (BOOL)drawerShouldOpen:(NEDrawer *)drawer;
- (BOOL)drawerShouldClose:(NEDrawer *)drawer;
- (void)drawerWillOpen:(NSNotification *)notification;
- (void)drawerDidOpen:(NSNotification *)notification;
- (void)drawerWillClose:(NSNotification *)notification;
- (void)drawerDidClose:(NSNotification *)notification;
- (NSSize)drawerWillResizeContents:(NEDrawer *)drawer toSize:(NSSize)contentSize;
@end

// Compatibility macros for easy migration from NSDrawer
// If NSDrawer uses different edge constants on Tiger, map them here
#ifdef NSMinXEdge
  #define NEDrawerConvertEdge(edge) \
    ((edge) == NSMinXEdge ? NERectEdgeLeft : \
     (edge) == NSMaxXEdge ? NERectEdgeRight : \
     (edge) == NSMaxYEdge ? NERectEdgeTop : \
     NERectEdgeBottom)
#endif

// For even easier migration, you can define these if needed:
#ifndef NSMinXEdge
  #define NSMinXEdge NERectEdgeLeft
  #define NSMaxXEdge NERectEdgeRight  
  #define NSMaxYEdge NERectEdgeTop
  #define NSMinYEdge NERectEdgeBottom
#endif

/**
 * Custom content view for NEDrawer that draws rounded corners
 * to match the parent window's appearance.
 */
@interface NEDrawerContentView : NSView {
  NEDrawer *_drawer;  // Weak reference
  NSColor *_backgroundColor;
  
  // Resize support
  NSTrackingRectTag _edgeTrackingRect;
  BOOL _isResizing;
  BOOL _mouseInResizeArea;
  NSPoint _resizeStartPoint;
  NSSize _resizeStartSize;
}

- (void)setDrawer:(NEDrawer *)drawer;
- (void)setBackgroundColor:(NSColor *)color;
- (void)setupResizeTracking;
- (void)removeResizeTracking;

@end

//
//  NEDrawer.h
//  anthropic-classic
//
//  Created by Brielle Harrison on 10/12/25.
//


#import "NEDrawer.h"
#import "ThemeColors.h"

@interface NEDrawer (Private)
- (void)setupDrawerWindow;
- (void)attachToParentWindow;
- (void)detachFromParentWindow;
- (void)animateToFrame:(NSRect)targetFrame;
- (void)animationStep:(NSTimer *)timer;
- (NSRect)openFrameForEdge:(NERectEdge)edge;
- (NSRect)closedFrameForEdge:(NERectEdge)edge;
- (void)postNotification:(NSString *)notificationName;
- (BOOL)isDarkMode;
@end

@implementation NEDrawer

/**
 * Convenience initializer that defaults to right edge.
 * Matches NSDrawer's default behavior.
 */
- (id)init {
  // Default to 250x400 on right edge, matching NSDrawer defaults
  return [self initWithContentSize:NSMakeSize(250, 400) 
                      preferredEdge:NERectEdgeRight];
}

/**
 * Initializes the drawer with a content size and preferred edge.
 * Maintains NSDrawer compatibility.
 *
 * @param contentSize The size of the drawer's content area
 * @param preferredEdge The edge where the drawer should appear
 * @return An initialized NEDrawer instance
 */
- (id)initWithContentSize:(NSSize)contentSize preferredEdge:(NERectEdge)preferredEdge {
  self = [super init];
  
  if (self) {
    _contentSize = contentSize;
    _minContentSize = NSMakeSize(100, 100);
    _maxContentSize = NSMakeSize(10000, 10000);
    _leadingOffset = 0;
    _trailingOffset = 0;
    _preferredEdge = preferredEdge;
    _state = NEDrawerStateClosed;
    _animationDuration = 0.25;
    _isDarkMode = [self isDarkMode];
    
    [self setupDrawerWindow];
  }
  
  return self;
}

/**
 * Creates and configures the drawer window with rounded corners.
 * Matches the parent window's corner style.
 */
- (void)setupDrawerWindow {
  NSRect contentRect = NSMakeRect(0, 0, _contentSize.width, _contentSize.height);
  
  // Tiger-compatible window style mask
  unsigned int styleMask = NSBorderlessWindowMask;
  
  // Create a borderless panel for the drawer
  _drawerWindow = [[NSPanel alloc] initWithContentRect:contentRect
                                              styleMask:styleMask
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
  
  // Configure the window - all these methods exist in Tiger
  [_drawerWindow setFloatingPanel:NO];
  [_drawerWindow setHidesOnDeactivate:NO];
  [_drawerWindow setReleasedWhenClosed:NO];
  [_drawerWindow setOpaque:NO];
  
  // Tiger-compatible shadow setting
  if ([_drawerWindow respondsToSelector:@selector(setHasShadow:)]) {
    [_drawerWindow setHasShadow:YES];
  }
  
  [_drawerWindow setLevel:NSNormalWindowLevel];
  
  // Set initial background color
  _backgroundColor = [ThemeColors windowBackgroundColorForDarkMode:_isDarkMode];
  [_drawerWindow setBackgroundColor:[NSColor clearColor]];
  
  // Create a custom container view
  NEDrawerContentView *containerView = [[NEDrawerContentView alloc] initWithFrame:contentRect];
  [containerView setDrawer:self];
  [containerView setBackgroundColor:_backgroundColor];
  
  [_drawerWindow setContentView:containerView];
  [containerView release];
}

/**
 * Calculates the open frame for the drawer.
 * Properly accounts for window chrome and rounded corners.
 *
 * @param edge The edge the drawer is on
 * @return The frame for the open drawer
 */
- (NSRect)openFrameForEdge:(NERectEdge)edge {
  NSRect parentFrame = [_parentWindow frame];
  NSRect parentContentRect = [[_parentWindow contentView] frame];
  NSRect drawerFrame = NSZeroRect;
  
  // Calculate the titlebar height
  float titlebarHeight = parentFrame.size.height - parentContentRect.size.height;
  
  // NSDrawer typically has these offsets:
  // - Top: starts just below the titlebar (about 22 pixels down on standard windows)
  // - Bottom: stops about 20 pixels from the bottom of the window
  float topOffset = titlebarHeight + 1.0;  // Just below titlebar
  float bottomOffset = 20.0;  // Significant bottom offset to match NSDrawer
  
  // Account for rounded corners on horizontal edges
  float cornerRadius = 6.0;
  
  // Overlap to slide under the parent window
  float overlap = 2.0;
  
  switch (edge) {
    case NERectEdgeLeft:
      drawerFrame = NSMakeRect(parentFrame.origin.x - _contentSize.width + overlap,
                               parentFrame.origin.y + bottomOffset + _leadingOffset,
                               _contentSize.width,
                               parentFrame.size.height - topOffset - bottomOffset - _leadingOffset - _trailingOffset);
      break;
      
    case NERectEdgeRight:
      drawerFrame = NSMakeRect(NSMaxX(parentFrame) - overlap,
                               parentFrame.origin.y + bottomOffset + _leadingOffset,
                               _contentSize.width,
                               parentFrame.size.height - topOffset - bottomOffset - _leadingOffset - _trailingOffset);
      break;
      
    case NERectEdgeTop:
      drawerFrame = NSMakeRect(parentFrame.origin.x + cornerRadius + _leadingOffset,
                               NSMaxY(parentFrame) - topOffset - overlap,
                               parentFrame.size.width - (cornerRadius * 2) - _leadingOffset - _trailingOffset,
                               _contentSize.height);
      break;
      
    case NERectEdgeBottom:
      drawerFrame = NSMakeRect(parentFrame.origin.x + cornerRadius + _leadingOffset,
                               parentFrame.origin.y - _contentSize.height + bottomOffset + overlap,
                               parentFrame.size.width - (cornerRadius * 2) - _leadingOffset - _trailingOffset,
                               _contentSize.height);
      break;
      
    default:
      // Default to right edge
      drawerFrame = NSMakeRect(NSMaxX(parentFrame) - overlap,
                               parentFrame.origin.y + bottomOffset,
                               _contentSize.width,
                               parentFrame.size.height - topOffset - bottomOffset);
      break;
  }
  
  return drawerFrame;
}

/**
 * Calculates the closed frame for the drawer.
 * Uses NERectEdge for Tiger compatibility.
 *
 * @param edge The edge the drawer is on  
 * @return The frame for the closed drawer
 */
- (NSRect)closedFrameForEdge:(NERectEdge)edge {
  NSRect openFrame = [self openFrameForEdge:edge];
  NSRect closedFrame = openFrame;
  
  // Collapse to zero width/height depending on edge
  switch (edge) {
    case NERectEdgeLeft:
      closedFrame.origin.x = openFrame.origin.x + openFrame.size.width;
      closedFrame.size.width = 0;
      break;
      
    case NERectEdgeRight:
      closedFrame.size.width = 0;
      break;
      
    case NERectEdgeTop:
      closedFrame.size.height = 0;
      break;
      
    case NERectEdgeBottom:
      closedFrame.origin.y = openFrame.origin.y + openFrame.size.height;
      closedFrame.size.height = 0;
      break;
      
    default:
      closedFrame.size.width = 0;
      break;
  }
  
  return closedFrame;
}

/**
 * Sets the content view of the drawer.
 *
 * @param contentView The view to display in the drawer
 */
- (void)setContentView:(NSView *)contentView {
  if (_contentView == contentView)
    return;
  
  if (_contentView)
    [_contentView removeFromSuperview];
  
  _contentView = contentView;
  
  if (_contentView) {
    NSView *containerView = [_drawerWindow contentView];
    [containerView addSubview:_contentView];
    
    // Make content view fill the container
    NSRect bounds = [containerView bounds];
    [_contentView setFrame:bounds];
    [_contentView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
  }
}

/**
 * Returns the content view.
 */
- (NSView *)contentView {
  return _contentView;
}

/**
 * Returns the content size.
 */
- (NSSize)contentSize {
  return _contentSize;
}

/**
 * Sets the preferred edge for the drawer.
 *
 * @param preferredEdge The edge where the drawer should appear
 */
- (void)setPreferredEdge:(NERectEdge)preferredEdge {
  _preferredEdge = preferredEdge;
}

/**
 * Returns the preferred edge.
 */
- (NERectEdge)preferredEdge {
  return _preferredEdge;
}

/**
 * Sets the parent window for the drawer.
 *
 * @param parentWindow The window the drawer should attach to
 */
- (void)setParentWindow:(NSWindow *)parentWindow {
  if (_parentWindow == parentWindow)
    return;
  
  if (_parentWindow)
    [self detachFromParentWindow];
  
  _parentWindow = parentWindow;
  
  if (_parentWindow)
    [self attachToParentWindow];
}

/**
 * Returns the parent window.
 */
- (NSWindow *)parentWindow {
  return _parentWindow;
}

/**
 * Sets the delegate.
 *
 * @param delegate The delegate object
 */
- (void)setDelegate:(id)delegate {
  _delegate = delegate;
}

/**
 * Returns the delegate.
 */
- (id)delegate {
  return _delegate;
}

/**
 * Opens the drawer on the preferred edge.
 */
- (void)open {
  [self openOnEdge:_preferredEdge];
}

/**
 * Opens the drawer on the specified edge.
 *
 * @param edge The edge to open the drawer on
 */
- (void)openOnEdge:(NERectEdge)edge {
  if (_state == NEDrawerStateOpen || _state == NEDrawerStateOpening)
    return;
  
  if (!_parentWindow)
    return;
  
  // Check delegate
  if (_delegate && [_delegate respondsToSelector:@selector(drawerShouldOpen:)]) {
    if (![_delegate drawerShouldOpen:self])
      return;
  }
  
  _preferredEdge = edge;
  _state = NEDrawerStateOpening;
  
  [self postNotification:@"NEDrawerWillOpenNotification"];
  
  // Position drawer at closed position first
  NSRect closedFrame = [self closedFrameForEdge:edge];
  [_drawerWindow setFrame:closedFrame display:NO];
  
  // CRITICAL: Order the drawer window BEHIND the parent window
  // This makes it appear to slide out from underneath
  [_drawerWindow orderWindow:NSWindowBelow relativeTo:[_parentWindow windowNumber]];
  
  // Make it a child window so it moves with parent
  // But use NSWindowBelow to keep it behind
  [_parentWindow addChildWindow:_drawerWindow ordered:NSWindowBelow];
  
  // Animate to open position
  NSRect openFrame = [self openFrameForEdge:edge];
  [self animateToFrame:openFrame];
}

/**
 * Closes the drawer.
 */
- (void)close {
  if (_state == NEDrawerStateClosed || _state == NEDrawerStateClosing)
    return;
  
  // Check delegate
  if (_delegate && [_delegate respondsToSelector:@selector(drawerShouldClose:)]) {
    if (![_delegate drawerShouldClose:self])
      return;
  }
  
  _state = NEDrawerStateClosing;
  
  [self postNotification:@"NEDrawerWillCloseNotification"];
  
  // Animate to closed position
  NSRect closedFrame = [self closedFrameForEdge:_preferredEdge];
  [self animateToFrame:closedFrame];
}

/**
 * Toggles the drawer open/closed.
 */
- (void)toggle {
  if (_state == NEDrawerStateOpen || _state == NEDrawerStateOpening)
    [self close];
  
  else
    [self open];
}

/**
 * Returns the current state of the drawer.
 */
- (NEDrawerState)state {
  return _state;
}

/**
 * Sets the background color of the drawer.
 *
 * @param color The background color
 */
- (void)setBackgroundColor:(NSColor *)color {
  [_backgroundColor release];
  _backgroundColor = [color retain];
  
  // Update the custom content view's background
  NEDrawerContentView *containerView = (NEDrawerContentView *)[_drawerWindow contentView];
  
  if ([containerView isKindOfClass:[NEDrawerContentView class]]) {
    [containerView setBackgroundColor:_backgroundColor];
  }
  
  [[_drawerWindow contentView] setNeedsDisplay:YES];
}

/**
 * Returns the background color.
 */
- (NSColor *)backgroundColor {
  return _backgroundColor;
}

/**
 * Updates the drawer appearance for dark/light mode.
 *
 * @param isDarkMode Whether to use dark mode
 */
- (void)updateAppearanceForDarkMode:(BOOL)isDarkMode {
  _isDarkMode = isDarkMode;
  
  NSColor *newColor = [ThemeColors windowBackgroundColorForDarkMode:isDarkMode];
  [self setBackgroundColor:newColor];
  
  // Only update shadow if the method exists (Tiger-compatible)
  if ([_drawerWindow respondsToSelector:@selector(setHasShadow:)]) {
    // Darker backgrounds need less shadow for visibility
    [_drawerWindow setHasShadow:YES];
  }
  
  // Force redraw
  [[_drawerWindow contentView] setNeedsDisplay:YES];
  
  if (_contentView)
    [_contentView setNeedsDisplay:YES];
}

#pragma mark - Private Methods

/**
 * Attaches the drawer to its parent window.
 */
- (void)attachToParentWindow {
  // Listen for parent window frame changes
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(parentWindowDidMove:)
                                               name:NSWindowDidMoveNotification
                                             object:_parentWindow];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(parentWindowDidResize:)
                                               name:NSWindowDidResizeNotification
                                             object:_parentWindow];
}

/**
 * Detaches the drawer from its parent window.
 */
- (void)detachFromParentWindow {
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:NSWindowDidMoveNotification
                                                object:_parentWindow];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:NSWindowDidResizeNotification
                                                object:_parentWindow];
  
  [_parentWindow removeChildWindow:_drawerWindow];
}

/**
 * Handles parent window movement.
 */
- (void)parentWindowDidMove:(NSNotification *)notification {
  if (_state == NEDrawerStateOpen) {
    // Reposition drawer to stay attached
    NSRect frame = [self openFrameForEdge:_preferredEdge];
    [_drawerWindow setFrame:frame display:YES];
  }
}

/**
 * Handles parent window resizing.
 */
- (void)parentWindowDidResize:(NSNotification *)notification {
  if (_state == NEDrawerStateOpen) {
    // Reposition drawer to stay attached
    NSRect frame = [self openFrameForEdge:_preferredEdge];
    [_drawerWindow setFrame:frame display:YES];
  }
}

/**
 * Animates the drawer to a target frame.
 *
 * @param targetFrame The frame to animate to
 */
- (void)animateToFrame:(NSRect)targetFrame {
  _targetFrame = targetFrame;
  _startFrame = [_drawerWindow frame];
  _animationStartTime = [NSDate timeIntervalSinceReferenceDate];
  
  // Stop any existing animation
  if (_animationTimer) {
    [_animationTimer invalidate];
    [_animationTimer release];
  }
  
  // Start animation timer
  _animationTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0/60.0  // 60 FPS
                                                       target:self
                                                     selector:@selector(animationStep:)
                                                     userInfo:nil
                                                      repeats:YES] retain];
}

/**
 * Performs one step of the animation.
 *
 * @param timer The animation timer
 */
- (void)animationStep:(NSTimer *)timer {
  NSTimeInterval elapsed = [NSDate timeIntervalSinceReferenceDate] - _animationStartTime;
  float progress = elapsed / _animationDuration;
  
  if (progress >= 1.0) {
    // Animation complete
    [_drawerWindow setFrame:_targetFrame display:YES];
    
    [_animationTimer invalidate];
    [_animationTimer release];
    _animationTimer = nil;
    
    // Update state and post notification
    if (_state == NEDrawerStateOpening) {
      _state = NEDrawerStateOpen;
      [self setupResizeTracking];  // ADD THIS LINE
      [self postNotification:@"NEDrawerDidOpenNotification"];
    }
    
    else if (_state == NEDrawerStateClosing) {
      _state = NEDrawerStateClosed;
      [self removeResizeTracking];  // ADD THIS LINE
      [self postNotification:@"NEDrawerDidCloseNotification"];
      
      // Hide the drawer window
      [_parentWindow removeChildWindow:_drawerWindow];
      [_drawerWindow orderOut:nil];
    }
  }
  
  else {
    // Ease-in-out interpolation
    progress = 0.5 * (1.0 - cos(progress * M_PI));
    
    NSRect currentFrame;
    currentFrame.origin.x = _startFrame.origin.x + 
                            (_targetFrame.origin.x - _startFrame.origin.x) * progress;
    currentFrame.origin.y = _startFrame.origin.y + 
                            (_targetFrame.origin.y - _startFrame.origin.y) * progress;
    currentFrame.size.width = _startFrame.size.width + 
                              (_targetFrame.size.width - _startFrame.size.width) * progress;
    currentFrame.size.height = _startFrame.size.height + 
                               (_targetFrame.size.height - _startFrame.size.height) * progress;
    
    [_drawerWindow setFrame:currentFrame display:YES];
  }
}

/**
 * Posts a notification for drawer events.
 *
 * @param notificationName The name of the notification
 */
- (void)postNotification:(NSString *)notificationName {
  [[NSNotificationCenter defaultCenter] postNotificationName:notificationName
                                                       object:self];
  
  // Also call delegate methods if implemented
  if (_delegate) {
    if ([notificationName isEqualToString:@"NEDrawerWillOpenNotification"] &&
        [_delegate respondsToSelector:@selector(drawerWillOpen:)]) {
      NSNotification *note = [NSNotification notificationWithName:notificationName object:self];
      [_delegate drawerWillOpen:note];
    }
    
    else if ([notificationName isEqualToString:@"NEDrawerDidOpenNotification"] &&
             [_delegate respondsToSelector:@selector(drawerDidOpen:)]) {
      NSNotification *note = [NSNotification notificationWithName:notificationName object:self];
      [_delegate drawerDidOpen:note];
    }
    
    else if ([notificationName isEqualToString:@"NEDrawerWillCloseNotification"] &&
             [_delegate respondsToSelector:@selector(drawerWillClose:)]) {
      NSNotification *note = [NSNotification notificationWithName:notificationName object:self];
      [_delegate drawerWillClose:note];
    }
    
    else if ([notificationName isEqualToString:@"NEDrawerDidCloseNotification"] &&
             [_delegate respondsToSelector:@selector(drawerDidClose:)]) {
      NSNotification *note = [NSNotification notificationWithName:notificationName object:self];
      [_delegate drawerDidClose:note];
    }
  }
}

/**
 * Detects if the system is in dark mode.
 *
 * @return YES if dark mode, NO otherwise
 */
- (BOOL)isDarkMode {
  // Check for effectiveAppearance (macOS 10.14+)
  if ([NSApp respondsToSelector:@selector(effectiveAppearance)]) {
    id appearance = [NSApp performSelector:@selector(effectiveAppearance)];
    
    if (appearance && [appearance respondsToSelector:@selector(name)]) {
      NSString *appearanceName = [appearance performSelector:@selector(name)];
      
      if (appearanceName && [appearanceName rangeOfString:@"Dark"].location != NSNotFound)
        return YES;
    }
  }
  
  // Check user defaults
  NSString *interfaceStyle = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
  
  if (interfaceStyle && [interfaceStyle isEqualToString:@"Dark"])
    return YES;
  
  return NO;
}

/**
 * Clean up.
 */
- (void)dealloc {
  [self detachFromParentWindow];
  
  if (_animationTimer) {
    [_animationTimer invalidate];
    [_animationTimer release];
  }
  
  [_drawerWindow release];
  [_backgroundColor release];
  
  [super dealloc];
}

// MARK: - Content Sizing Additions

// Add these methods to NEDrawer.m:

/**
 * Sets the minimum content size for the drawer.
 *
 * @param minContentSize The minimum size
 */
- (void)setMinContentSize:(NSSize)minContentSize {
  _minContentSize = minContentSize;
  
  // Constrain current size if needed
  if (_contentSize.width < _minContentSize.width)
    _contentSize.width = _minContentSize.width;
  
  if (_contentSize.height < _minContentSize.height)
    _contentSize.height = _minContentSize.height;
  
  if (_state == NEDrawerStateOpen)
    [self setContentSize:_contentSize];
}

/**
 * Returns the minimum content size.
 */
- (NSSize)minContentSize {
  return _minContentSize;
}

/**
 * Sets the maximum content size for the drawer.
 *
 * @param maxContentSize The maximum size
 */
- (void)setMaxContentSize:(NSSize)maxContentSize {
  _maxContentSize = maxContentSize;
  
  // Constrain current size if needed
  if (_contentSize.width > _maxContentSize.width)
    _contentSize.width = _maxContentSize.width;
  
  if (_contentSize.height > _maxContentSize.height)
    _contentSize.height = _maxContentSize.height;
  
  if (_state == NEDrawerStateOpen)
    [self setContentSize:_contentSize];
}

/**
 * Returns the maximum content size.
 */
- (NSSize)maxContentSize {
  return _maxContentSize;
}

/**
 * Sets the leading offset for the drawer.
 * This controls the gap at the leading edge.
 *
 * @param offset The leading offset
 */
- (void)setLeadingOffset:(float)offset {
  _leadingOffset = offset;
  
  if (_state == NEDrawerStateOpen) {
    NSRect frame = [self openFrameForEdge:_preferredEdge];
    [_drawerWindow setFrame:frame display:YES];
  }
}

/**
 * Returns the leading offset.
 */
- (float)leadingOffset {
  return _leadingOffset;
}

/**
 * Sets the trailing offset for the drawer.
 * This controls the gap at the trailing edge.
 *
 * @param offset The trailing offset
 */
- (void)setTrailingOffset:(float)offset {
  _trailingOffset = offset;
  
  if (_state == NEDrawerStateOpen) {
    NSRect frame = [self openFrameForEdge:_preferredEdge];
    [_drawerWindow setFrame:frame display:YES];
  }
}

/**
 * Returns the trailing offset.
 */
- (float)trailingOffset {
  return _trailingOffset;
}

/**
 * Sets the content size of the drawer.
 * Updates both the drawer window and the content view.
 *
 * @param contentSize The new size for the drawer
 */
- (void)setContentSize:(NSSize)contentSize {
  // Constrain to min/max
  if (contentSize.width < _minContentSize.width)
    contentSize.width = _minContentSize.width;
  
  if (contentSize.width > _maxContentSize.width)
    contentSize.width = _maxContentSize.width;
  
  if (contentSize.height < _minContentSize.height)
    contentSize.height = _minContentSize.height;
  
  if (contentSize.height > _maxContentSize.height)
    contentSize.height = _maxContentSize.height;
  
  // Check delegate for size constraint
  if (_delegate && [_delegate respondsToSelector:@selector(drawerWillResizeContents:toSize:)]) {
    contentSize = [_delegate drawerWillResizeContents:self toSize:contentSize];
  }
  
  _contentSize = contentSize;
  
  if (_state == NEDrawerStateOpen) {
    // Update the drawer window frame immediately
    NSRect newFrame = [self openFrameForEdge:_preferredEdge];
    [_drawerWindow setFrame:newFrame display:YES];
    
    // Update content view frame if needed
    if (_contentView) {
      NSView *containerView = [_drawerWindow contentView];
      NSRect bounds = [containerView bounds];
      [_contentView setFrame:bounds];
    }
  }
}

// MARK: - NEDrawer Resizing

/**
 * Sets up tracking for resize cursor and drag handling.
 * Called when drawer opens.
 */
- (void)setupResizeTracking {
  NEDrawerContentView *contentView = (NEDrawerContentView *)[_drawerWindow contentView];
  
  if ([contentView respondsToSelector:@selector(setupResizeTracking)]) {
    [contentView setupResizeTracking];
  }
}

/**
 * Removes resize tracking.
 * Called when drawer closes.
 */
- (void)removeResizeTracking {
  NEDrawerContentView *contentView = (NEDrawerContentView *)[_drawerWindow contentView];
  
  if ([contentView respondsToSelector:@selector(removeResizeTracking)]) {
    [contentView removeResizeTracking];
  }
}

@end

@implementation NEDrawerContentView

- (id)initWithFrame:(NSRect)frame {
  self = [super initWithFrame:frame];
  
  if (self) {
    _backgroundColor = [[NSColor windowBackgroundColor] retain];
    _isResizing = NO;
    _mouseInResizeArea = NO;
    _edgeTrackingRect = 0;
  }
  
  return self;
}

- (void)setDrawer:(NEDrawer *)drawer {
  _drawer = drawer;  // Don't retain to avoid cycle
}

- (void)setBackgroundColor:(NSColor *)color {
  [_backgroundColor release];
  _backgroundColor = [color retain];
  [self setNeedsDisplay:YES];
}

/**
 * Returns the resize area rect based on drawer edge.
 */
- (NSRect)resizeAreaRect {
  NSRect bounds = [self bounds];
  NERectEdge edge = [_drawer preferredEdge];
  NSRect resizeRect = NSZeroRect;
  float resizeThickness = 6.0;  // Pixels for resize handle area
  
  switch (edge) {
    case NERectEdgeLeft:
      // Resize handle on the left edge
      resizeRect = NSMakeRect(0, 0, resizeThickness, bounds.size.height);
      break;
      
    case NERectEdgeRight:
      // Resize handle on the right edge
      resizeRect = NSMakeRect(bounds.size.width - resizeThickness, 0, 
                              resizeThickness, bounds.size.height);
      break;
      
    case NERectEdgeTop:
      // Resize handle on the top edge
      resizeRect = NSMakeRect(0, bounds.size.height - resizeThickness,
                              bounds.size.width, resizeThickness);
      break;
      
    case NERectEdgeBottom:
      // Resize handle on the bottom edge
      resizeRect = NSMakeRect(0, 0, bounds.size.width, resizeThickness);
      break;
  }
  
  return resizeRect;
}

/**
 * Sets up tracking rect for resize cursor.
 */
- (void)setupResizeTracking {
  if (_edgeTrackingRect) {
    [self removeTrackingRect:_edgeTrackingRect];
  }
  
  _edgeTrackingRect = [self addTrackingRect:[self resizeAreaRect]
                                       owner:self
                                    userData:NULL
                                assumeInside:NO];
}

/**
 * Removes tracking rect.
 */
- (void)removeResizeTracking {
  if (_edgeTrackingRect) {
    [self removeTrackingRect:_edgeTrackingRect];
    _edgeTrackingRect = 0;
  }
}

/**
 * Override hitTest to capture mouse events in the resize area.
 * This ensures resize works even with a content view on top.
 */
- (NSView *)hitTest:(NSPoint)point {
  // Convert point to our coordinate system
  NSPoint localPoint = [self convertPoint:point fromView:[self superview]];
  
  // If the point is in our resize area, handle it ourselves
  if (NSPointInRect(localPoint, [self resizeAreaRect])) {
    return self;  // We handle resize events
  }
  
  // Otherwise, let normal hit testing occur (content view gets events)
  return [super hitTest:point];
}

/**
 * Called when mouse enters the resize area.
 */
- (void)mouseEntered:(NSEvent *)event {
  _mouseInResizeArea = YES;
  
  // Set appropriate resize cursor based on edge
  NERectEdge edge = [_drawer preferredEdge];
  
  if (edge == NERectEdgeLeft || edge == NERectEdgeRight) {
    [[NSCursor resizeLeftRightCursor] set];
  }
  else {
    [[NSCursor resizeUpDownCursor] set];
  }
}

/**
 * Called when mouse exits the resize area.
 */
- (void)mouseExited:(NSEvent *)event {
  _mouseInResizeArea = NO;
  
  if (!_isResizing) {
    [[NSCursor arrowCursor] set];
  }
}

/**
 * Handles mouse down for resize dragging.
 */
- (void)mouseDown:(NSEvent *)event {
  NSPoint localPoint = [self convertPoint:[event locationInWindow] fromView:nil];
  
  if (NSPointInRect(localPoint, [self resizeAreaRect])) {
    _isResizing = YES;
    _resizeStartPoint = [event locationInWindow];
    _resizeStartSize = [_drawer contentSize];
    
    // Set cursor if not already set
    NERectEdge edge = [_drawer preferredEdge];
    
    if (edge == NERectEdgeLeft || edge == NERectEdgeRight) {
      [[NSCursor resizeLeftRightCursor] set];
    }
    else {
      [[NSCursor resizeUpDownCursor] set];
    }
  }
  else {
    // Pass to super for content view events
    [super mouseDown:event];
  }
}

/**
 * Handles mouse dragging for resize.
 */
- (void)mouseDragged:(NSEvent *)event {
  if (!_isResizing) {
    [super mouseDragged:event];
    return;
  }
  
  NSPoint currentPoint = [event locationInWindow];
  float deltaX = currentPoint.x - _resizeStartPoint.x;
  float deltaY = currentPoint.y - _resizeStartPoint.y;
  
  NERectEdge edge = [_drawer preferredEdge];
  NSSize newSize = _resizeStartSize;
  
  switch (edge) {
    case NERectEdgeLeft:
      // Dragging left edge - invert delta
      newSize.width = _resizeStartSize.width - deltaX;
      break;
      
    case NERectEdgeRight:
      // Dragging right edge
      newSize.width = _resizeStartSize.width + deltaX;
      break;
      
    case NERectEdgeTop:
      // Dragging top edge
      newSize.height = _resizeStartSize.height + deltaY;
      break;
      
    case NERectEdgeBottom:
      // Dragging bottom edge - invert delta
      newSize.height = _resizeStartSize.height - deltaY;
      break;
  }
  
  // Apply constraints
  NSSize minSize = [_drawer minContentSize];
  NSSize maxSize = [_drawer maxContentSize];
  
  if (newSize.width < minSize.width)
    newSize.width = minSize.width;
  
  if (newSize.width > maxSize.width)
    newSize.width = maxSize.width;
  
  if (newSize.height < minSize.height)
    newSize.height = minSize.height;
  
  if (newSize.height > maxSize.height)
    newSize.height = maxSize.height;
  
  // Update drawer size
  [_drawer setContentSize:newSize];
  
  // Re-setup tracking rect since bounds changed
  [self setupResizeTracking];
}

/**
 * Handles mouse up to end resize.
 */
- (void)mouseUp:(NSEvent *)event {
  if (_isResizing) {
    _isResizing = NO;
    
    // Restore normal cursor
    [[NSCursor arrowCursor] set];
  }
  else {
    [super mouseUp:event];
  }
}

/**
 * Allows the view to become first responder for mouse events.
 */
- (BOOL)acceptsFirstResponder {
  return YES;
}

- (void)drawRect:(NSRect)dirtyRect {
  // Get the edge the drawer is on
  NERectEdge edge = [_drawer preferredEdge];
  NSRect bounds = [self bounds];
  
  // Create a bezier path with rounded corners on the appropriate side
  NSBezierPath *path;
  float cornerRadius = 6.0;
  
  // Inset slightly on the connecting edge to go "under" the parent window
  float inset = 2.0;
  
  if (edge == NERectEdgeLeft) {
    // Round the left corners, inset right edge
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(NSMaxX(bounds) + inset, 0)];
    [path lineToPoint:NSMakePoint(cornerRadius, 0)];
    [path appendBezierPathWithArcFromPoint:NSMakePoint(0, 0)
                                   toPoint:NSMakePoint(0, cornerRadius)
                                    radius:cornerRadius];
    [path lineToPoint:NSMakePoint(0, NSMaxY(bounds) - cornerRadius)];
    [path appendBezierPathWithArcFromPoint:NSMakePoint(0, NSMaxY(bounds))
                                   toPoint:NSMakePoint(cornerRadius, NSMaxY(bounds))
                                    radius:cornerRadius];
    [path lineToPoint:NSMakePoint(NSMaxX(bounds) + inset, NSMaxY(bounds))];
    [path closePath];
  }
  
  else if (edge == NERectEdgeRight) {
    // Round the right corners, inset left edge
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(-inset, 0)];
    [path lineToPoint:NSMakePoint(NSMaxX(bounds) - cornerRadius, 0)];
    [path appendBezierPathWithArcFromPoint:NSMakePoint(NSMaxX(bounds), 0)
                                   toPoint:NSMakePoint(NSMaxX(bounds), cornerRadius)
                                    radius:cornerRadius];
    [path lineToPoint:NSMakePoint(NSMaxX(bounds), NSMaxY(bounds) - cornerRadius)];
    [path appendBezierPathWithArcFromPoint:NSMakePoint(NSMaxX(bounds), NSMaxY(bounds))
                                   toPoint:NSMakePoint(NSMaxX(bounds) - cornerRadius, NSMaxY(bounds))
                                    radius:cornerRadius];
    [path lineToPoint:NSMakePoint(-inset, NSMaxY(bounds))];
    [path closePath];
  }
  
  else if (edge == NERectEdgeTop) {
    // Inset bottom edge
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(0, -inset)];
    [path lineToPoint:NSMakePoint(NSMaxX(bounds), -inset)];
    [path lineToPoint:NSMakePoint(NSMaxX(bounds), NSMaxY(bounds))];
    [path lineToPoint:NSMakePoint(0, NSMaxY(bounds))];
    [path closePath];
  }
  
  else {
    // Bottom - inset top edge
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(0, 0)];
    [path lineToPoint:NSMakePoint(NSMaxX(bounds), 0)];
    [path lineToPoint:NSMakePoint(NSMaxX(bounds), NSMaxY(bounds) + inset)];
    [path lineToPoint:NSMakePoint(0, NSMaxY(bounds) + inset)];
    [path closePath];
  }
  
  // Tiger-compatible graphics context save
  [NSGraphicsContext saveGraphicsState];
  
  // Clip to the path
  [path addClip];
  
  // Fill with background color
  [_backgroundColor set];
  NSRectFill(bounds);
  
  // Restore graphics state
  [NSGraphicsContext restoreGraphicsState];
  
  // Draw resize handle indicator (subtle lines at the edge)
  if ([_drawer state] == NEDrawerStateOpen) {
    [[NSColor colorWithCalibratedWhite:0.5 alpha:0.3] set];
    
    NSBezierPath *handlePath = [NSBezierPath bezierPath];
    [handlePath setLineWidth:1.0];
    
    // Draw 3 small lines as resize indicator
    float handleLength = 20.0;
    float centerY = bounds.size.height / 2.0;
    float centerX = bounds.size.width / 2.0;
    
    if (edge == NERectEdgeLeft) {
      // Vertical lines on left edge
      int i;
      for (i = -1; i <= 1; i++) {
        float y = centerY + (i * 8);
        [handlePath moveToPoint:NSMakePoint(2, y - handleLength/2)];
        [handlePath lineToPoint:NSMakePoint(2, y + handleLength/2)];
      }
    }
    else if (edge == NERectEdgeRight) {
      // Vertical lines on right edge
      int i;
      for (i = -1; i <= 1; i++) {
        float y = centerY + (i * 8);
        [handlePath moveToPoint:NSMakePoint(bounds.size.width - 3, y - handleLength/2)];
        [handlePath lineToPoint:NSMakePoint(bounds.size.width - 3, y + handleLength/2)];
      }
    }
    else if (edge == NERectEdgeTop || edge == NERectEdgeBottom) {
      // Horizontal lines
      float yPos = (edge == NERectEdgeTop) ? bounds.size.height - 3 : 2;
      
      int i;
      for (i = -1; i <= 1; i++) {
        float x = centerX + (i * 8);
        [handlePath moveToPoint:NSMakePoint(x - handleLength/2, yPos)];
        [handlePath lineToPoint:NSMakePoint(x + handleLength/2, yPos)];
      }
    }
    
    [handlePath stroke];
  }
  
  // Draw subtle inner shadow
  if (edge == NERectEdgeRight || edge == NERectEdgeLeft) {
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.1] set];
    
    NSBezierPath *shadowLine = [NSBezierPath bezierPath];
    [shadowLine setLineWidth:0.5];
    
    if (edge == NERectEdgeLeft) {
      [shadowLine moveToPoint:NSMakePoint(1, cornerRadius)];
      [shadowLine lineToPoint:NSMakePoint(1, NSMaxY(bounds) - cornerRadius)];
    }
    else {
      [shadowLine moveToPoint:NSMakePoint(NSMaxX(bounds) - 1, cornerRadius)];
      [shadowLine lineToPoint:NSMakePoint(NSMaxX(bounds) - 1, NSMaxY(bounds) - cornerRadius)];
    }
    
    [shadowLine stroke];
  }
}

- (BOOL)isOpaque {
  return NO;
}

- (void)dealloc {
  [self removeResizeTracking];
  [_backgroundColor release];
  [super dealloc];
}

@end

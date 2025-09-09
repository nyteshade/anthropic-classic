//
//  ThemedView.m
//  ClaudeChat
//
//  Custom view that respects dark/light mode themes
//

#import "ThemedView.h"
#import "ThemeColors.h"

@implementation ThemedView

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        isDarkMode = NO;
    }
    return self;
}

- (void)setDarkMode:(BOOL)dark {
    isDarkMode = dark;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    // Fill with appropriate background color
    NSColor *backgroundColor = [ThemeColors windowBackgroundColorForDarkMode:isDarkMode];
    [backgroundColor set];
    NSRectFill(dirtyRect);
    
    [super drawRect:dirtyRect];
}

- (BOOL)isOpaque {
    return YES;
}

@end
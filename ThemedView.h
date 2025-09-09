//
//  ThemedView.h
//  ClaudeChat
//
//  Custom view that respects dark/light mode themes
//

#import <Cocoa/Cocoa.h>

@interface ThemedView : NSView {
    BOOL isDarkMode;
}

- (void)setDarkMode:(BOOL)dark;

@end
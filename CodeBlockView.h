//
//  CodeBlockView.h
//  ClaudeChat
//
//  A custom view for code blocks with copy functionality
//

#import <Cocoa/Cocoa.h>

@interface CodeBlockView : NSView {
    NSTextView *codeTextView;
    NSButton *copyButton;
    NSString *codeContent;
    NSTrackingRectTag trackingRect;
    BOOL mouseInside;
}

- (id)initWithFrame:(NSRect)frame codeContent:(NSString *)code font:(NSFont *)font color:(NSColor *)color;
- (void)updateTrackingRect;
- (NSString *)codeContent;

@end
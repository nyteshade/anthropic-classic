//
//  CodeBlockView.m
//  ClaudeChat
//
//  A custom view for code blocks with copy functionality
//

#import "CodeBlockView.h"

@implementation CodeBlockView

- (id)initWithFrame:(NSRect)frame codeContent:(NSString *)code font:(NSFont *)font color:(NSColor *)color {
    self = [super initWithFrame:frame];
    if (self) {
        codeContent = [code retain];
        mouseInside = NO;
        
        // Create text view for code
        NSRect textFrame = NSMakeRect(0, 0, frame.size.width - 60, frame.size.height);
        codeTextView = [[NSTextView alloc] initWithFrame:textFrame];
        [codeTextView setEditable:NO];
        [codeTextView setSelectable:YES];
        [codeTextView setDrawsBackground:NO];
        [codeTextView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        
        // Set the code content with formatting
        NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:code];
        [attrStr addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, [code length])];
        [attrStr addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, [code length])];
        [[codeTextView textStorage] setAttributedString:attrStr];
        [attrStr release];
        
        [self addSubview:codeTextView];
        
        // Create copy button (initially hidden)
        NSRect buttonFrame = NSMakeRect(frame.size.width - 55, 2, 50, 20);
        copyButton = [[NSButton alloc] initWithFrame:buttonFrame];
        [copyButton setTitle:@"Copy"];
        [copyButton setBezelStyle:NSRoundRectBezelStyle];
        [copyButton setFont:[NSFont systemFontOfSize:10]];
        [copyButton setTarget:self];
        [copyButton setAction:@selector(copyCode:)];
        [copyButton setAutoresizingMask:NSViewMinXMargin];
        [copyButton setHidden:YES];
        [self addSubview:copyButton];
        
        // Set up tracking rect for mouse hover
        [self updateTrackingRect];
    }
    return self;
}

- (void)dealloc {
    [self removeTrackingRect:trackingRect];
    [codeContent release];
    [codeTextView release];
    [copyButton release];
    [super dealloc];
}

- (void)updateTrackingRect {
    if (trackingRect) {
        [self removeTrackingRect:trackingRect];
    }
    trackingRect = [self addTrackingRect:[self bounds] owner:self userData:nil assumeInside:NO];
}

- (void)setFrame:(NSRect)frame {
    [super setFrame:frame];
    [self updateTrackingRect];
}

- (void)setBounds:(NSRect)bounds {
    [super setBounds:bounds];
    [self updateTrackingRect];
}

- (void)mouseEntered:(NSEvent *)event {
    mouseInside = YES;
    [copyButton setHidden:NO];
}

- (void)mouseExited:(NSEvent *)event {
    mouseInside = NO;
    [copyButton setHidden:YES];
}

- (void)copyCode:(id)sender {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    [pasteboard setString:codeContent forType:NSStringPboardType];
    
    // Provide visual feedback
    NSString *originalTitle = [copyButton title];
    [copyButton setTitle:@"Copied!"];
    [copyButton setEnabled:NO];
    
    // Reset button after delay (Tiger-compatible way)
    [self performSelector:@selector(resetCopyButton:) withObject:originalTitle afterDelay:1.0];
}

- (void)resetCopyButton:(NSString *)originalTitle {
    [copyButton setTitle:originalTitle];
    [copyButton setEnabled:YES];
}

- (NSString *)codeContent {
    return codeContent;
}

- (BOOL)isFlipped {
    return YES;
}

@end
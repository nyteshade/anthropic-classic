//
//  ChatWindowController.m
//  ClaudeChat
//

#import "ChatWindowController.h"
#import "ClaudeAPIManager.h"
#import "AppDelegate.h"
#import "ThemeColors.h"
#import "ConversationManager.h"

@implementation ChatWindowController

- (id)init {
    self = [super init];
    if (self) {
        [self createWindow];
        apiManager = [[ClaudeAPIManager alloc] init];
        [apiManager setDelegate:self];
        chatHistory = [[NSMutableAttributedString alloc] init];
    }
    return self;
}

- (void)dealloc {
    [apiManager release];
    [chatHistory release];
    [super dealloc];
}

- (void)createWindow {
    // Create window - Tiger compatible with better default size
    NSRect frame = NSMakeRect(100, 100, 900, 700);
    NSUInteger styleMask = NSTitledWindowMask | NSClosableWindowMask | 
                           NSMiniaturizableWindowMask | NSResizableWindowMask;
    
    NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
                                         styleMask:styleMask
                                         backing:NSBackingStoreBuffered
                                         defer:NO];
    [window setTitle:@"Claude Chat"];
    [self updateWindowTitle];
    [window setMinSize:NSMakeSize(500, 400)];
    
    NSView *contentView = [window contentView];
    
    // Apple HIG: Proper margins and spacing
    float margin = 20.0;           // Window margin
    float controlBarHeight = 44.0; // Height for control bar (matches toolbar height)
    float buttonHeight = 25.0;     // Small button height per HIG
    float fieldHeight = 22.0;      // Standard text field height
    float spacing = 8.0;           // Space between inline elements
    float sectionSpacing = 10.0;   // Space between sections
    
    // Create control bar at top for conversation controls
    NSRect controlBarFrame = NSMakeRect(0, 
                                        frame.size.height - controlBarHeight,
                                        frame.size.width,
                                        controlBarHeight);
    NSView *controlBar = [[[NSView alloc] initWithFrame:controlBarFrame] autorelease];
    [controlBar setAutoresizingMask:NSViewWidthSizable | NSViewMinYMargin];
    [contentView addSubview:controlBar];
    
    // Toggle drawer button - using semantic sizing
    float controlButtonWidth = 110.0;
    float controlX = margin;
    NSRect toggleFrame = NSMakeRect(controlX, 
                                    (controlBarHeight - buttonHeight) / 2.0,
                                    controlButtonWidth,
                                    buttonHeight);
    NSButton *toggleButton = [[[NSButton alloc] initWithFrame:toggleFrame] autorelease];
    [toggleButton setTitle:@"Conversations"];
    [toggleButton setBezelStyle:NSTexturedRoundedBezelStyle];
    [toggleButton setTarget:self];
    [toggleButton setAction:@selector(toggleDrawer:)];
    [toggleButton setFont:[NSFont systemFontOfSize:11.0]]; // Small control font
    [controlBar addSubview:toggleButton];
    
    // New conversation button
    controlX += controlButtonWidth + spacing;
    NSRect newConvFrame = NSMakeRect(controlX,
                                     (controlBarHeight - buttonHeight) / 2.0,
                                     80.0,
                                     buttonHeight);
    NSButton *newConvButton = [[[NSButton alloc] initWithFrame:newConvFrame] autorelease];
    [newConvButton setTitle:@"New Chat"];
    [newConvButton setBezelStyle:NSTexturedRoundedBezelStyle];
    [newConvButton setTarget:self];
    [newConvButton setAction:@selector(newConversation:)];
    [newConvButton setFont:[NSFont systemFontOfSize:11.0]];
    [controlBar addSubview:newConvButton];
    
    // Clear button (right aligned)
    NSRect clearFrame = NSMakeRect(frame.size.width - margin - 70.0,
                                   (controlBarHeight - buttonHeight) / 2.0,
                                   70.0,
                                   buttonHeight);
    NSButton *clearButton = [[[NSButton alloc] initWithFrame:clearFrame] autorelease];
    [clearButton setTitle:@"Clear"];
    [clearButton setBezelStyle:NSTexturedRoundedBezelStyle];
    [clearButton setTarget:self];
    [clearButton setAction:@selector(clearCurrentChat:)];
    [clearButton setFont:[NSFont systemFontOfSize:11.0]];
    [clearButton setAutoresizingMask:NSViewMinXMargin];
    [controlBar addSubview:clearButton];
    
    // Input area height
    float inputAreaHeight = 32.0;
    
    // Create chat text view with scroll view - adjusted for control bar
    NSRect scrollFrame = NSMakeRect(margin, 
                                    margin + inputAreaHeight + sectionSpacing, 
                                    frame.size.width - (margin * 2), 
                                    frame.size.height - controlBarHeight - (margin * 2) - inputAreaHeight - (sectionSpacing * 2));
    scrollView = [[NSScrollView alloc] initWithFrame:scrollFrame];
    [scrollView setHasVerticalScroller:YES];
    [scrollView setHasHorizontalScroller:NO];
    [scrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [scrollView setBorderType:NSBezelBorder];
    
    NSRect textFrame = [[scrollView contentView] frame];
    chatTextView = [[NSTextView alloc] initWithFrame:textFrame];
    [chatTextView setEditable:NO];
    [chatTextView setRichText:YES];
    [chatTextView setImportsGraphics:NO];
    [chatTextView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [[chatTextView textContainer] setContainerSize:NSMakeSize(textFrame.size.width, FLT_MAX)];
    [[chatTextView textContainer] setWidthTracksTextView:YES];
    
    // Add padding inside text view
    [[chatTextView textContainer] setLineFragmentPadding:10.0];
    [chatTextView setTextContainerInset:NSMakeSize(8.0, 8.0)];
    
    [scrollView setDocumentView:chatTextView];
    [contentView addSubview:scrollView];
    
    // Create send button with proper HIG sizing
    float sendButtonWidth = 70.0;  // Narrower, more proportional
    float sendButtonHeight = 28.0; // Standard push button height
    NSRect buttonFrame = NSMakeRect(frame.size.width - margin - sendButtonWidth, 
                                    margin + (inputAreaHeight - sendButtonHeight) / 2.0, 
                                    sendButtonWidth, 
                                    sendButtonHeight);
    sendButton = [[NSButton alloc] initWithFrame:buttonFrame];
    [sendButton setTitle:@"Send"];
    [sendButton setBezelStyle:NSRoundedBezelStyle];
    [sendButton setTarget:self];
    [sendButton setAction:@selector(sendMessage:)];
    [sendButton setAutoresizingMask:NSViewMinXMargin];
    [contentView addSubview:sendButton];
    
    // Create message input field with proper spacing
    NSRect messageFrame = NSMakeRect(margin, 
                                     margin + (inputAreaHeight - fieldHeight) / 2.0,  // Center vertically
                                     frame.size.width - (margin * 2) - sendButtonWidth - spacing, 
                                     fieldHeight);
    messageField = [[NSTextField alloc] initWithFrame:messageFrame];
    [messageField setAutoresizingMask:NSViewWidthSizable];
    [messageField setTarget:self];
    [messageField setAction:@selector(sendMessage:)];
    [messageField setFont:[NSFont systemFontOfSize:13.0]];  // Message font
    [[messageField cell] setPlaceholderString:@"Type a message..."];
    [[messageField cell] setFocusRingType:NSFocusRingTypeDefault];
    [contentView addSubview:messageField];
    
    // Create progress indicator - better positioned
    NSRect progressFrame = NSMakeRect(frame.size.width - margin - sendButtonWidth - spacing - 20, 
                                      margin + (inputAreaHeight - 16) / 2.0,  // Center with input area
                                      16, 
                                      16);
    progressIndicator = [[NSProgressIndicator alloc] initWithFrame:progressFrame];
    [progressIndicator setStyle:NSProgressIndicatorSpinningStyle];
    [progressIndicator setDisplayedWhenStopped:NO];
    [progressIndicator setAutoresizingMask:NSViewMinXMargin];
    [progressIndicator setControlSize:NSSmallControlSize];
    [contentView addSubview:progressIndicator];
    
    [self setWindow:window];
    
    // Create conversation drawer
    [self createConversationDrawer];
    
    // Apply initial theme
    [self updateTheme];
    
    [window makeFirstResponder:messageField];
}

// Toolbar removed - controls integrated into window UI

- (void)createConversationDrawer {
    NSWindow *window = [self window];
    
    // Create drawer
    conversationDrawer = [[NSDrawer alloc] initWithContentSize:NSMakeSize(250, 400) 
                                                  preferredEdge:NSMinXEdge];
    [conversationDrawer setParentWindow:window];
    [conversationDrawer setMinContentSize:NSMakeSize(200, 300)];
    [conversationDrawer setMaxContentSize:NSMakeSize(400, 10000)];
    
    // Create drawer content view
    NSView *drawerContent = [[[NSView alloc] initWithFrame:NSMakeRect(0, 0, 250, 400)] autorelease];
    
    // Add title label with semantic font
    NSTextField *titleLabel = [[[NSTextField alloc] initWithFrame:NSMakeRect(10, 370, 230, 20)] autorelease];
    [titleLabel setStringValue:@"Conversations"];
    [titleLabel setEditable:NO];
    [titleLabel setBordered:NO];
    [titleLabel setDrawsBackground:NO];
    [titleLabel setFont:[NSFont boldSystemFontOfSize:[NSFont systemFontSize] + 1.0]];  // Semantic size
    [drawerContent addSubview:titleLabel];
    
    // Create table view for conversations
    NSScrollView *tableScroll = [[[NSScrollView alloc] initWithFrame:NSMakeRect(10, 40, 230, 320)] autorelease];
    [tableScroll setHasVerticalScroller:YES];
    [tableScroll setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    
    conversationTable = [[[NSTableView alloc] initWithFrame:[[tableScroll contentView] frame]] autorelease];
    [conversationTable setDataSource:self];
    [conversationTable setDelegate:self];
    [conversationTable setUsesAlternatingRowBackgroundColors:YES];
    
    NSTableColumn *column = [[[NSTableColumn alloc] initWithIdentifier:@"title"] autorelease];
    [[column headerCell] setStringValue:@"Title"];
    [column setWidth:210];
    [conversationTable addTableColumn:column];
    
    [tableScroll setDocumentView:conversationTable];
    [drawerContent addSubview:tableScroll];
    
    // Add buttons
    NSButton *newButton = [[[NSButton alloc] initWithFrame:NSMakeRect(10, 10, 110, 25)] autorelease];
    [newButton setTitle:@"New Chat"];
    [newButton setBezelStyle:NSRoundedBezelStyle];
    [newButton setTarget:self];
    [newButton setAction:@selector(newConversation:)];
    [newButton setFont:[NSFont systemFontOfSize:12]];
    [drawerContent addSubview:newButton];
    
    NSButton *deleteButton = [[[NSButton alloc] initWithFrame:NSMakeRect(125, 10, 110, 25)] autorelease];
    [deleteButton setTitle:@"Delete"];
    [deleteButton setBezelStyle:NSRoundedBezelStyle];
    [deleteButton setTarget:self];
    [deleteButton setAction:@selector(deleteConversation:)];
    [deleteButton setFont:[NSFont systemFontOfSize:12]];
    [drawerContent addSubview:deleteButton];
    
    [conversationDrawer setContentView:drawerContent];
    
    // Open drawer by default
    [conversationDrawer open];
}

- (void)sendMessage:(id)sender {
    NSString *message = [messageField stringValue];
    if ([message length] == 0) return;
    
    // Add to current conversation
    Conversation *current = [[ConversationManager sharedManager] currentConversation];
    if (current) {
        NSDictionary *userMsg = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"user", @"role",
                                  message, @"content",
                                  nil];
        [current addMessage:userMsg];
        [[ConversationManager sharedManager] saveCurrentConversation];
    }
    
    // Add user message to chat
    [self appendMessage:message fromUser:YES];
    [messageField setStringValue:@""];
    
    // Update table to show new summary
    [conversationTable reloadData];
    
    // Disable controls and show progress
    [messageField setEnabled:NO];
    [sendButton setEnabled:NO];
    [progressIndicator startAnimation:self];
    
    // Get API key
    AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    NSString *apiKey = [appDelegate apiKey];
    
    if (!apiKey || [apiKey length] == 0) {
        [self appendMessage:@"Error: No API key configured. Please set your API key in preferences." fromUser:NO];
        [self resetControls];
        return;
    }
    
    // Send to API using delegate pattern
    [apiManager sendMessage:message withAPIKey:apiKey];
}

- (void)resetControls {
    [messageField setEnabled:YES];
    [sendButton setEnabled:YES];
    [progressIndicator stopAnimation:self];
    [[self window] makeFirstResponder:messageField];
}

- (void)appendMessage:(NSString *)message fromUser:(BOOL)isUser {
    // Create attributed string for the message
    NSMutableAttributedString *messageAttr = [[NSMutableAttributedString alloc] init];
    
    // Get current settings
    AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    BOOL isDark = [appDelegate isDarkMode];
    int fontAdjust = [appDelegate fontSizeAdjustment];
    
    // Semantic font sizes with adjustment
    float systemFontSize = [NSFont systemFontSize];  // 13.0 on most systems
    float labelFontSize = systemFontSize + 1.0 + fontAdjust;  // Label font (14.0 base)
    float messageFontSize = systemFontSize + fontAdjust;      // Message font (13.0 base)
    
    // Theme-aware colors using Apple semantic colors
    NSColor *senderColor;
    if (isUser) {
        senderColor = [ThemeColors systemBlueForDarkMode:isDark];
    } else {
        senderColor = [ThemeColors systemPurpleForDarkMode:isDark];
    }
    
    // Add sender label
    NSString *sender = isUser ? @"You: " : @"Claude: ";
    NSDictionary *senderAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSFont boldSystemFontOfSize:labelFontSize], NSFontAttributeName,
                                  senderColor, NSForegroundColorAttributeName,
                                  nil];
    NSAttributedString *senderStr = [[NSAttributedString alloc] initWithString:sender 
                                                                     attributes:senderAttrs];
    [messageAttr appendAttributedString:senderStr];
    [senderStr release];
    
    // Parse markdown and add formatted message
    NSAttributedString *messageStr = [self parseMarkdown:message isUser:isUser];
    [messageAttr appendAttributedString:messageStr];
    
    // Add proper spacing between messages
    NSMutableParagraphStyle *paraStyle = [[NSMutableParagraphStyle alloc] init];
    [paraStyle setParagraphSpacing:12.0];
    
    NSDictionary *newlineAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                   paraStyle, NSParagraphStyleAttributeName,
                                   nil];
    NSAttributedString *newline = [[NSAttributedString alloc] initWithString:@"\n" 
                                                                   attributes:newlineAttrs];
    [messageAttr appendAttributedString:newline];
    [paraStyle release];
    [newline release];
    
    // Append to chat history
    [[chatTextView textStorage] appendAttributedString:messageAttr];
    [messageAttr release];
    
    // Scroll to bottom
    [chatTextView scrollRangeToVisible:NSMakeRange([[chatTextView string] length], 0)];
}

- (void)clearConversation {
    // Clear the chat text view
    [[chatTextView textStorage] deleteCharactersInRange:NSMakeRange(0, [[chatTextView string] length])];
    
    // Clear the API manager's conversation history
    [apiManager release];
    apiManager = [[ClaudeAPIManager alloc] init];
    [apiManager setDelegate:self];
    
    // Reset the message field
    [messageField setStringValue:@""];
    [[self window] makeFirstResponder:messageField];
}

- (void)updateWindowTitle {
    AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    NSString *model = [appDelegate selectedModel];
    
    // Extract model name for display
    NSString *modelDisplay = @"";
    if ([model rangeOfString:@"opus-4-1"].location != NSNotFound) {
        modelDisplay = @"Opus 4.1";
    } else if ([model rangeOfString:@"opus-4"].location != NSNotFound) {
        modelDisplay = @"Opus 4";
    } else if ([model rangeOfString:@"sonnet-4"].location != NSNotFound) {
        modelDisplay = @"Sonnet 4";
    } else if ([model rangeOfString:@"3-7-sonnet"].location != NSNotFound) {
        modelDisplay = @"Sonnet 3.7";
    } else if ([model rangeOfString:@"haiku"].location != NSNotFound) {
        modelDisplay = @"Haiku 3";
    }
    
    if ([modelDisplay length] > 0) {
        [[self window] setTitle:[NSString stringWithFormat:@"Claude Chat - %@", modelDisplay]];
    } else {
        [[self window] setTitle:@"Claude Chat"];
    }
}

#pragma mark - ClaudeAPIManagerDelegate

- (void)apiManager:(ClaudeAPIManager *)manager didReceiveResponse:(NSString *)response {
    // Add to current conversation
    Conversation *current = [[ConversationManager sharedManager] currentConversation];
    if (current) {
        NSDictionary *assistantMsg = [NSDictionary dictionaryWithObjectsAndKeys:
                                      @"assistant", @"role",
                                      response, @"content",
                                      nil];
        [current addMessage:assistantMsg];
        [[ConversationManager sharedManager] saveCurrentConversation];
    }
    
    [self appendMessage:response fromUser:NO];
    [self resetControls];
    
    // Update table to show updated conversation
    [conversationTable reloadData];
}

- (void)apiManager:(ClaudeAPIManager *)manager didFailWithError:(NSError *)error {
    NSString *errorMessage = error ? [error localizedDescription] : @"Unknown error occurred";
    [self appendMessage:[NSString stringWithFormat:@"Error: %@", errorMessage] fromUser:NO];
    [self resetControls];
}

- (void)updateTheme {
    AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    BOOL isDark = [appDelegate isDarkMode];
    
    // Update text view background using semantic colors
    [chatTextView setBackgroundColor:[ThemeColors textBackgroundColorForDarkMode:isDark]];
    [scrollView setBackgroundColor:[ThemeColors windowBackgroundColorForDarkMode:isDark]];
    
    // Update window background
    [[self window] setBackgroundColor:[ThemeColors windowBackgroundColorForDarkMode:isDark]];
    
    // Update drawer if exists
    if (conversationDrawer) {
        [[conversationDrawer contentView] setNeedsDisplay:YES];
        [conversationTable reloadData];
    }
    
    // Refresh existing text colors
    [self refreshChatColors];
}

- (void)updateFontSize {
    // Refresh the chat with new font sizes
    [self refreshChatColors];
}

- (void)refreshChatColors {
    // This would ideally re-render all messages with new colors/fonts
    // For simplicity, new messages will use the new settings
    [chatTextView setNeedsDisplay:YES];
}

- (NSAttributedString *)parseMarkdown:(NSString *)text isUser:(BOOL)isUser {
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] init];
    
    AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    BOOL isDark = [appDelegate isDarkMode];
    int fontAdjust = [appDelegate fontSizeAdjustment];
    
    float baseFontSize = [NSFont systemFontSize] + fontAdjust;  // Semantic base size
    NSColor *textColor = [ThemeColors labelColorForDarkMode:isDark];
    NSColor *codeColor = [ThemeColors codeColorForDarkMode:isDark];
    
    // Basic markdown parsing
    NSArray *lines = [text componentsSeparatedByString:@"\n"];
    int i;
    for (i = 0; i < [lines count]; i++) {
        NSString *line = [lines objectAtIndex:i];
        NSMutableAttributedString *lineAttr = [[NSMutableAttributedString alloc] init];
        
        // Check for headers (# ## ###)
        if ([line hasPrefix:@"### "]) {
            NSString *header = [line substringFromIndex:4];
            NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSFont boldSystemFontOfSize:baseFontSize + 1], NSFontAttributeName,
                                   textColor, NSForegroundColorAttributeName,
                                   nil];
            [lineAttr appendAttributedString:[[[NSAttributedString alloc] initWithString:header attributes:attrs] autorelease]];
        }
        else if ([line hasPrefix:@"## "]) {
            NSString *header = [line substringFromIndex:3];
            NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSFont boldSystemFontOfSize:baseFontSize + 2], NSFontAttributeName,
                                   textColor, NSForegroundColorAttributeName,
                                   nil];
            [lineAttr appendAttributedString:[[[NSAttributedString alloc] initWithString:header attributes:attrs] autorelease]];
        }
        else if ([line hasPrefix:@"# "]) {
            NSString *header = [line substringFromIndex:2];
            NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSFont boldSystemFontOfSize:baseFontSize + 3], NSFontAttributeName,
                                   textColor, NSForegroundColorAttributeName,
                                   nil];
            [lineAttr appendAttributedString:[[[NSAttributedString alloc] initWithString:header attributes:attrs] autorelease]];
        }
        // Check for bullet points
        else if ([line hasPrefix:@"- "] || [line hasPrefix:@"* "]) {
            NSString *bullet = @"• ";
            NSString *content = [line substringFromIndex:2];
            NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSFont systemFontOfSize:baseFontSize], NSFontAttributeName,
                                   textColor, NSForegroundColorAttributeName,
                                   nil];
            [lineAttr appendAttributedString:[[[NSAttributedString alloc] initWithString:bullet attributes:attrs] autorelease]];
            [lineAttr appendAttributedString:[[[NSAttributedString alloc] initWithString:content attributes:attrs] autorelease]];
        }
        // Check for code blocks (simple backtick detection)
        else if ([line hasPrefix:@"`"] && [line hasSuffix:@"`"] && [line length] > 2) {
            NSString *code = [line substringWithRange:NSMakeRange(1, [line length] - 2)];
            NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSFont userFixedPitchFontOfSize:baseFontSize], NSFontAttributeName,
                                   codeColor, NSForegroundColorAttributeName,
                                   nil];
            [lineAttr appendAttributedString:[[[NSAttributedString alloc] initWithString:code attributes:attrs] autorelease]];
        }
        // Regular text with inline formatting
        else {
            [self parseInlineMarkdown:line into:lineAttr baseFontSize:baseFontSize textColor:textColor codeColor:codeColor];
        }
        
        [result appendAttributedString:lineAttr];
        [lineAttr release];
        
        if (i < [lines count] - 1) {
            [result appendAttributedString:[[[NSAttributedString alloc] initWithString:@"\n"] autorelease]];
        }
    }
    
    return [result autorelease];
}

- (void)parseInlineMarkdown:(NSString *)text 
                        into:(NSMutableAttributedString *)result 
                baseFontSize:(float)baseFontSize 
                   textColor:(NSColor *)textColor 
                   codeColor:(NSColor *)codeColor {
    
    // Simple inline parsing for **bold** and *italic* and `code`
    NSMutableString *remaining = [NSMutableString stringWithString:text];
    
    while ([remaining length] > 0) {
        // Check for bold
        NSRange boldRange = [remaining rangeOfString:@"**"];
        NSRange italicRange = [remaining rangeOfString:@"*"];
        NSRange codeRange = [remaining rangeOfString:@"`"];
        
        // Find the earliest marker
        NSUInteger minLocation = [remaining length];
        NSString *markerType = nil;
        
        if (boldRange.location != NSNotFound && boldRange.location < minLocation) {
            minLocation = boldRange.location;
            markerType = @"bold";
        }
        if (codeRange.location != NSNotFound && codeRange.location < minLocation) {
            minLocation = codeRange.location;
            markerType = @"code";
        }
        if (italicRange.location != NSNotFound && italicRange.location < minLocation && 
            (boldRange.location == NSNotFound || italicRange.location != boldRange.location)) {
            minLocation = italicRange.location;
            markerType = @"italic";
        }
        
        if (markerType == nil) {
            // No more formatting, add the rest as plain text
            NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSFont systemFontOfSize:baseFontSize], NSFontAttributeName,
                                   textColor, NSForegroundColorAttributeName,
                                   nil];
            [result appendAttributedString:[[[NSAttributedString alloc] initWithString:remaining attributes:attrs] autorelease]];
            break;
        }
        
        // Add text before the marker
        if (minLocation > 0) {
            NSString *before = [remaining substringToIndex:minLocation];
            NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSFont systemFontOfSize:baseFontSize], NSFontAttributeName,
                                   textColor, NSForegroundColorAttributeName,
                                   nil];
            [result appendAttributedString:[[[NSAttributedString alloc] initWithString:before attributes:attrs] autorelease]];
        }
        
        // Process the formatted text
        if ([markerType isEqualToString:@"bold"]) {
            [remaining deleteCharactersInRange:NSMakeRange(0, minLocation + 2)];
            NSRange endRange = [remaining rangeOfString:@"**"];
            if (endRange.location != NSNotFound) {
                NSString *boldText = [remaining substringToIndex:endRange.location];
                NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                       [NSFont boldSystemFontOfSize:baseFontSize], NSFontAttributeName,
                                       textColor, NSForegroundColorAttributeName,
                                       nil];
                [result appendAttributedString:[[[NSAttributedString alloc] initWithString:boldText attributes:attrs] autorelease]];
                [remaining deleteCharactersInRange:NSMakeRange(0, endRange.location + 2)];
            } else {
                // No closing marker, treat as literal
                [result appendAttributedString:[[[NSAttributedString alloc] initWithString:@"**"] autorelease]];
            }
        }
        else if ([markerType isEqualToString:@"italic"]) {
            [remaining deleteCharactersInRange:NSMakeRange(0, minLocation + 1)];
            NSRange endRange = [remaining rangeOfString:@"*"];
            if (endRange.location != NSNotFound) {
                NSString *italicText = [remaining substringToIndex:endRange.location];
                // Use oblique trait for italic on Tiger
                NSFont *italicFont = [[NSFontManager sharedFontManager] 
                                      convertFont:[NSFont systemFontOfSize:baseFontSize]
                                      toHaveTrait:NSItalicFontMask];
                NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                       italicFont, NSFontAttributeName,
                                       textColor, NSForegroundColorAttributeName,
                                       nil];
                [result appendAttributedString:[[[NSAttributedString alloc] initWithString:italicText attributes:attrs] autorelease]];
                [remaining deleteCharactersInRange:NSMakeRange(0, endRange.location + 1)];
            } else {
                // No closing marker, treat as literal
                [result appendAttributedString:[[[NSAttributedString alloc] initWithString:@"*"] autorelease]];
            }
        }
        else if ([markerType isEqualToString:@"code"]) {
            [remaining deleteCharactersInRange:NSMakeRange(0, minLocation + 1)];
            NSRange endRange = [remaining rangeOfString:@"`"];
            if (endRange.location != NSNotFound) {
                NSString *codeText = [remaining substringToIndex:endRange.location];
                NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                       [NSFont userFixedPitchFontOfSize:baseFontSize], NSFontAttributeName,
                                       codeColor, NSForegroundColorAttributeName,
                                       nil];
                [result appendAttributedString:[[[NSAttributedString alloc] initWithString:codeText attributes:attrs] autorelease]];
                [remaining deleteCharactersInRange:NSMakeRange(0, endRange.location + 1)];
            } else {
                // No closing marker, treat as literal
                [result appendAttributedString:[[[NSAttributedString alloc] initWithString:@"`"] autorelease]];
            }
        }
    }
}

#pragma mark - Control Actions

- (void)toggleDrawer:(id)sender {
    if ([conversationDrawer state] == NSDrawerOpenState || 
        [conversationDrawer state] == NSDrawerOpeningState) {
        [conversationDrawer close];
    } else {
        [conversationDrawer open];
    }
}

- (void)newConversation:(id)sender {
    [[ConversationManager sharedManager] createNewConversation];
    [self clearConversation];
    [conversationTable reloadData];
}

- (void)deleteConversation:(id)sender {
    int selectedRow = [conversationTable selectedRow];
    if (selectedRow >= 0) {
        NSArray *conversations = [[ConversationManager sharedManager] allConversations];
        if (selectedRow < [conversations count]) {
            Conversation *conv = [conversations objectAtIndex:selectedRow];
            [[ConversationManager sharedManager] deleteConversation:conv];
            [conversationTable reloadData];
            [self loadCurrentConversation];
        }
    }
}

- (void)clearCurrentChat:(id)sender {
    // Clear the current conversation's messages
    Conversation *current = [[ConversationManager sharedManager] currentConversation];
    if (current) {
        [current.messages removeAllObjects];
        [[ConversationManager sharedManager] saveCurrentConversation];
    }
    
    // Clear the display
    [self clearConversation];
    
    // Update table
    [conversationTable reloadData];
}

- (void)loadCurrentConversation {
    Conversation *current = [[ConversationManager sharedManager] currentConversation];
    if (current) {
        // Clear and reload messages
        [[chatTextView textStorage] deleteCharactersInRange:NSMakeRange(0, [[chatTextView string] length])];
        
        // Reset API manager with new conversation
        [apiManager release];
        apiManager = [[ClaudeAPIManager alloc] init];
        [apiManager setDelegate:self];
        
        // Reload messages from conversation
        int i;
        for (i = 0; i < [current.messages count]; i++) {
            NSDictionary *msg = [current.messages objectAtIndex:i];
            NSString *role = [msg objectForKey:@"role"];
            NSString *content = [msg objectForKey:@"content"];
            
            if ([role isEqualToString:@"user"]) {
                [self appendMessage:content fromUser:YES];
                // Add to API manager's history
                [apiManager addToHistory:content isUser:YES];
            } else if ([role isEqualToString:@"assistant"]) {
                [self appendMessage:content fromUser:NO];
                // Add to API manager's history  
                [apiManager addToHistory:content isUser:NO];
            }
        }
        
        // Update window title with conversation info
        [self updateWindowTitle];
    }
}

#pragma mark - NSTableView DataSource & Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [[[ConversationManager sharedManager] allConversations] count];
}

- (id)tableView:(NSTableView *)tableView 
    objectValueForTableColumn:(NSTableColumn *)tableColumn 
                          row:(NSInteger)row {
    NSArray *conversations = [[ConversationManager sharedManager] allConversations];
    if (row < [conversations count]) {
        Conversation *conv = [conversations objectAtIndex:row];
        return [conv summary];
    }
    return @"";
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    int selectedRow = [conversationTable selectedRow];
    if (selectedRow >= 0) {
        NSArray *conversations = [[ConversationManager sharedManager] allConversations];
        if (selectedRow < [conversations count]) {
            Conversation *conv = [conversations objectAtIndex:selectedRow];
            [[ConversationManager sharedManager] selectConversation:conv];
            [self loadCurrentConversation];
        }
    }
}

@end
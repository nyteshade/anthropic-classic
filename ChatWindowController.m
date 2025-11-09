//
//  ChatWindowController.m
//  ClaudeChat
//

#import "ChatWindowController.h"
#import "ClaudeAPIManager.h"
#import "AppDelegate.h"
#import "ThemeColors.h"
#import "ConversationManager.h"
#import "ThemedView.h"
#import "NESizingHelpers.h"
#import "SAFEArc.h"

#import "NSView+Essentials.h"
#import "NSString+TextMeasure.h"

@implementation ChatWindowController

- (id)init {
  self = [super init];
  if (self) {
    [self createWindow];
    apiManager = [[ClaudeAPIManager alloc] init];
    [apiManager setDelegate:self];
    chatHistory = [[NSMutableAttributedString alloc] init];
    codeBlockButtons = [[NSMutableArray alloc] init];
    codeBlockRanges = [[NSMutableArray alloc] init];
    
    // Listen for font preference changes
    [[NSNotificationCenter defaultCenter] addObserver:self
                         selector:@selector(fontPreferencesChanged:)
                           name:@"FontPreferencesChanged"
                           object:nil];
  }
  return self;
}

- (void)showWindow:(id)sender {
  NSWindow *window;

  window = [self window];
  if (!window) {
    NSLog(@"ERROR: ChatWindowController showWindow called but window is nil!");
    return;
  }

  NSLog(@"ChatWindowController showWindow: centering and showing window");
  [window center];
  [window makeKeyAndOrderFront:sender];
  NSLog(@"ChatWindowController showWindow: window should be visible now");
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self removeAllCodeBlockButtons];
  SAFE_ARC_RELEASE(codeBlockButtons);
  SAFE_ARC_RELEASE(codeBlockRanges);
  SAFE_ARC_RELEASE(apiManager);
  SAFE_ARC_RELEASE(chatHistory);
  SAFE_ARC_RELEASE(messageScrollView);
  SAFE_ARC_SUPER_DEALLOC;
}

- (float) calculateButtonWidth:(NSString*)title 
						  font:(NSFont*)font {
  // Create attributes dictionary
  NSDictionary *attributes = [NSDictionary dictionaryWithObject:font 
														   forKey:NSFontAttributeName];
  
  // Calculate text size
  NSSize textSize = [title sizeWithAttributes:attributes];
  
  // Add horizontal padding for NSRoundedBezelStyle
  // Apple uses approximately 14 pixels on each side for standard Aqua buttons
  float width = ceil(textSize.width) + 32.0;
  
  // Ensure minimum width per HIG
  if (width < 32.0) {
    width = 32.0;
  }
  
  return width;
}

- (void)createWindow {
  SAFE_ARC_AUTORELEASE_POOL_PUSH();
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
  float margin = 20.0;       // Window margin
  float controlBarHeight = 44.0; // Height for control bar (matches toolbar height)
  float buttonHeight = 25.0;   // Small button height per HIG
  float fieldHeight = 22.0;    // Standard text field height
  float spacing = 8.0;       // Space between inline elements
  float sectionSpacing = 10.0;   // Space between sections
  
  // Create control bar at top for conversation controls
  NSRect controlBarFrame = NSMakeRect(0, 
                    frame.size.height - controlBarHeight,
                    frame.size.width,
                    controlBarHeight);
  NSView *controlBar = [[[NSView alloc] initWithFrame:controlBarFrame] autorelease];
  [controlBar setAutoresizingMask:NSViewWidthSizable | NSViewMinYMargin];
	[controlBar setBorderColor:[NSColor blackColor]];
	[controlBar setBorderWidth:2.0];
  [contentView addSubview:controlBar];  
  
  // Toggle drawer button - using semantic sizing
  float controlButtonWidth = 110.0;
  float controlX = margin;
  NSRect toggleFrame = NSMakeRect(controlX, 
                  (controlBarHeight - buttonHeight) / 2.0,
                  [self calculateButtonWidth:@"Conversations" 
														  font:[NSFont systemFontOfSize:11.0]],
                  buttonHeight);
		
  NSButton *toggleButton = [[[NSButton alloc] initWithFrame:toggleFrame] autorelease];
  [toggleButton setTitle:@"Conversations"];
  [toggleButton setBezelStyle:NSRoundedBezelStyle];  // Proper Aqua style
  [[toggleButton cell] setAlignment:NSCenterTextAlignment];  // Center text
  [toggleButton setTarget:self];
  [toggleButton setAction:@selector(toggleDrawer:)];
  [toggleButton setFont:[NSFont systemFontOfSize:11.0]]; // Small control font
  NSButtonSizeToFitWithMinimum(toggleButton);
  
  [controlBar addSubview:toggleButton];
  
  // New conversation button
  controlX += controlButtonWidth + spacing;
  NSRect newConvFrame = NSMakeRect(controlX,
                   (controlBarHeight - buttonHeight) / 2.0,
                   [self calculateButtonWidth:@"New Chat" 
														   font:[NSFont systemFontOfSize:11.0]],
                   buttonHeight);
  NSButton *newConvButton = [[[NSButton alloc] initWithFrame:newConvFrame] autorelease];
  [newConvButton setTitle:@"New Chat"];
  [newConvButton setBezelStyle:NSRoundedBezelStyle];  // Proper Aqua style
  [[newConvButton cell] setAlignment:NSCenterTextAlignment];  // Center text
  [newConvButton setTarget:self];
  [newConvButton setAction:@selector(newConversation:)];
  [newConvButton setFont:[NSFont systemFontOfSize:11.0]];
  NSButtonSizeToFitWithMinimum(newConvButton);
  [controlBar addSubview:newConvButton];
  
  // Clear button (right aligned)
  NSRect clearFrame = NSMakeRect(frame.size.width - margin - 70.0,
                   (controlBarHeight - buttonHeight) / 2.0,
                   [self calculateButtonWidth:@"Clear" 
														 font:[NSFont systemFontOfSize:11.0]],
                   buttonHeight);
  NSButton *clearButton = [[[NSButton alloc] initWithFrame:clearFrame] autorelease];
  [clearButton setTitle:@"Clear"];
  [clearButton setBezelStyle:NSRoundedBezelStyle];  // Proper Aqua style
  [[clearButton cell] setAlignment:NSCenterTextAlignment];  // Center text
  [clearButton setTarget:self];
  [clearButton setAction:@selector(clearCurrentChat:)];
  [clearButton setFont:[NSFont systemFontOfSize:11.0]];
  [clearButton setAutoresizingMask:NSViewMinXMargin];
  NSButtonSizeToFitWithMinimum(clearButton);
  [controlBar addSubview:clearButton];
  
  // Input area height
  float inputAreaHeight = 32.0;
  
  // Create chat text view with scroll view - adjusted for control bar with extra padding
  float topPadding = 8.0;  // Extra padding between control bar and text area
  NSRect scrollFrame = NSMakeRect(margin, 
                  margin + inputAreaHeight + sectionSpacing, 
                  frame.size.width - (margin * 2), 
                  frame.size.height - controlBarHeight - topPadding - (margin * 2) - inputAreaHeight - (sectionSpacing * 2));
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
                  [self calculateButtonWidth:@"Send" 
														  font:[NSFont systemFontOfSize:11.0]], 
                  sendButtonHeight);
  sendButton = [[NSButton alloc] initWithFrame:buttonFrame];
  [sendButton setTitle:@"Send"];
  [sendButton setBezelStyle:NSRoundedBezelStyle];  // Proper Aqua style
  [[sendButton cell] setAlignment:NSCenterTextAlignment];  // Center text
  [sendButton setTarget:self];
  [sendButton setAction:@selector(sendMessage:)];
  [sendButton setAutoresizingMask:NSViewMinXMargin];
  NSButtonSizeToFitWithMinimum(sendButton);
  [contentView addSubview:sendButton];
  
  // Set up min/max heights for the message field
  messageFieldMinHeight = fieldHeight;
  messageFieldMaxHeight = 120.0;  // Maximum height before scrolling
  
  // Create message input field with NSTextView in NSScrollView
  NSRect messageScrollFrame = NSMakeRect(margin, 
                       margin,
                       frame.size.width - (margin * 2) - sendButtonWidth - spacing, 
                       messageFieldMinHeight);
  messageScrollView = [[NSScrollView alloc] initWithFrame:messageScrollFrame];
  [messageScrollView setAutoresizingMask:NSViewWidthSizable];
  [messageScrollView setBorderType:NSBezelBorder];
  [messageScrollView setHasVerticalScroller:YES];
  [messageScrollView setHasHorizontalScroller:NO];
  [messageScrollView setAutohidesScrollers:YES];
  
  // Create the text view for message input
  NSSize contentSize = [messageScrollView contentSize];
  messageField = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, contentSize.width, contentSize.height)];
  [messageField setMinSize:NSMakeSize(0.0, contentSize.height)];
  [messageField setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
  [messageField setVerticallyResizable:YES];
  [messageField setHorizontallyResizable:NO];
  [messageField setAutoresizingMask:NSViewWidthSizable];
  [[messageField textContainer] setContainerSize:NSMakeSize(contentSize.width, FLT_MAX)];
  [[messageField textContainer] setWidthTracksTextView:YES];
  [messageField setDelegate:self];
  [messageField setFont:[NSFont systemFontOfSize:13.0]];  // Message font
  [messageField setRichText:NO];
  [messageField setImportsGraphics:NO];
  [messageField setUsesRuler:NO];
  [messageField setAllowsUndo:YES];
  
  [messageScrollView setDocumentView:messageField];
  [contentView addSubview:messageScrollView];
  
  // Create progress indicator - better positioned
  NSRect progressFrame = NSMakeRect(frame.size.width - margin - sendButtonWidth - spacing - 54, 
                    margin + (inputAreaHeight - 16) / 2.0,  // Center with input area
                    48, 
                    16);
  progressIndicator = [[NSProgressIndicator alloc] initWithFrame:progressFrame];
  [progressIndicator setStyle:NSProgressIndicatorBarStyle];
  [progressIndicator setDisplayedWhenStopped:NO];
  [progressIndicator setAutoresizingMask:NSViewMinXMargin];
  [progressIndicator setControlSize:NSSmallControlSize];
	[progressIndicator setIndeterminate:YES];
  [contentView addSubview:progressIndicator];
  
  [self setWindow:window];
  
  // Create conversation drawer
  [self createConversationDrawer];
  
  // Apply initial theme
  [self updateTheme];

  [window makeFirstResponder:messageField];
  SAFE_ARC_AUTORELEASE_POOL_POP();
}

// Toolbar removed - controls integrated into window UI

- (void)createConversationDrawer {
  SAFE_ARC_AUTORELEASE_POOL_PUSH();
  NSWindow *window = [self window];
  
  // Create drawer
  conversationDrawer = [[NEDrawer alloc] initWithContentSize:NSMakeSize(250, 400)
                          preferredEdge:NSMaxXEdge];
  [conversationDrawer setParentWindow:window];
  [conversationDrawer setMinContentSize:NSMakeSize(200, 300)];
  [conversationDrawer setMaxContentSize:NSMakeSize(400, 10000)];

  // Get current theme
  AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
  BOOL isDark = [appDelegate isDarkMode];
  
  // Create drawer content view with themed background
  ThemedView *drawerContent = [[[ThemedView alloc] initWithFrame:NSMakeRect(0, 0, 250, 400)] autorelease];
  [drawerContent setDarkMode:isDark];
  
  // Add title label with semantic font
  NSString* btnTitle = @"Conversations";
  
  NSTextField *titleLabel = [[[NSTextField alloc] initWithFrame:NSMakeRect(10, 370, 230, 20)] autorelease];
  [titleLabel setStringValue:@"Conversations"];
  [titleLabel setEditable:NO];
  [titleLabel setBordered:NO];
  [titleLabel setDrawsBackground:NO];
  [titleLabel setFont:[NSFont boldSystemFontOfSize:[NSFont systemFontSize] + 1.0]];  // Semantic size
  [titleLabel setTextColor:[ThemeColors labelColorForDarkMode:isDark]];
  
  [drawerContent addSubview:titleLabel];
  
  // Create table view for conversations
  NSScrollView *tableScroll = [[[NSScrollView alloc] initWithFrame:NSMakeRect(10, 40, 230, 320)] autorelease];
  [tableScroll setHasVerticalScroller:YES];
  [tableScroll setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
  
  conversationTable = [[[NSTableView alloc] initWithFrame:[[tableScroll contentView] frame]] autorelease];
  [conversationTable setDataSource:self];
  [conversationTable setDelegate:self];
  [conversationTable setUsesAlternatingRowBackgroundColors:YES];  // Enable alternating rows
  
  NSTableColumn *column = [[[NSTableColumn alloc] initWithIdentifier:@"title"] autorelease];
  [[column headerCell] setStringValue:@"Title"];
  [column setWidth:210];
  [conversationTable addTableColumn:column];
  
  [tableScroll setDocumentView:conversationTable];
  [drawerContent addSubview:tableScroll];
  
  // Add buttons
  NSButton *newButton = [[[NSButton alloc] initWithFrame:NSMakeRect(10, 10, 110, 25)] autorelease];
  [newButton setTitle:@"New Chat"];
  [newButton setBezelStyle:NSRoundedBezelStyle];  // Proper Aqua style
  [[newButton cell] setAlignment:NSCenterTextAlignment];  // Center text
  [newButton setTarget:self];
  [newButton setAction:@selector(newConversation:)];
  [newButton setFont:[NSFont systemFontOfSize:12]];
  NSButtonSizeToFitWithMinimum(newButton);
  [drawerContent addSubview:newButton];
  
  NSButton *deleteButton = [[[NSButton alloc] initWithFrame:NSMakeRect(125, 10, 110, 25)] autorelease];
  [deleteButton setTitle:@"Delete"];
  [deleteButton setBezelStyle:NSRoundedBezelStyle];  // Proper Aqua style
  [[deleteButton cell] setAlignment:NSCenterTextAlignment];  // Center text
  [deleteButton setTarget:self];
  [deleteButton setAction:@selector(deleteConversation:)];
  [deleteButton setFont:[NSFont systemFontOfSize:12]];
  NSButtonSizeToFitWithMinimum(deleteButton);
  [drawerContent addSubview:deleteButton];
  
  [conversationDrawer setContentView:drawerContent];


  // Open drawer by default
  [conversationDrawer open];
  SAFE_ARC_AUTORELEASE_POOL_POP();
}

- (void)textDidChange:(NSNotification *)notification {
  if ([notification object] == messageField) {
    [self adjustMessageFieldHeight];
  }
}

- (BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)aSelector {
  // Handle Enter key to send message (without Shift)
  if (aSelector == @selector(insertNewline:)) {
    NSEvent *currentEvent = [NSApp currentEvent];
    if ([currentEvent modifierFlags] & NSShiftKeyMask) {
      // Shift+Enter: Insert newline
      return NO;
    } else {
      // Enter alone: Send message
      [self sendMessage:nil];
      return YES;
    }
  }
  return NO;
}

- (void)adjustMessageFieldHeight {
  // Calculate the height needed for the current text
  NSLayoutManager *layoutManager = [messageField layoutManager];
  NSTextContainer *textContainer = [messageField textContainer];
  
  // Force layout
  [layoutManager glyphRangeForTextContainer:textContainer];
  NSRect usedRect = [layoutManager usedRectForTextContainer:textContainer];
  
  float newHeight = usedRect.size.height + 10;  // Add some padding
  
  // Clamp to min/max heights
  if (newHeight < messageFieldMinHeight) {
    newHeight = messageFieldMinHeight;
  } else if (newHeight > messageFieldMaxHeight) {
    newHeight = messageFieldMaxHeight;
  }
  
  // Get current frame
  NSRect scrollFrame = [messageScrollView frame];
  float heightDiff = newHeight - scrollFrame.size.height;
  
  if (fabs(heightDiff) > 0.1) {  // Only resize if there's a significant change
    // Adjust the scroll view frame
    scrollFrame.size.height = newHeight;
    [messageScrollView setFrame:scrollFrame];
    
    // Adjust the chat scroll view to compensate
    NSRect chatFrame = [scrollView frame];
    float controlBarHeight = 44.0;
    float bottomMargin = 10.0;
    chatFrame.origin.y = scrollFrame.origin.y + scrollFrame.size.height + bottomMargin;
    chatFrame.size.height = [[self window] frame].size.height - controlBarHeight - chatFrame.origin.y - bottomMargin;
    // Make sure we don't overlap with the control bar
    if (chatFrame.size.height + chatFrame.origin.y > [[self window] frame].size.height - controlBarHeight) {
      chatFrame.size.height = [[self window] frame].size.height - controlBarHeight - chatFrame.origin.y;
    }
    [scrollView setFrame:chatFrame];
    
    // Adjust send button position
    NSRect buttonFrame = [sendButton frame];
    buttonFrame.origin.y = scrollFrame.origin.y + (scrollFrame.size.height - buttonFrame.size.height) / 2.0;
    [sendButton setFrame:buttonFrame];
    
    // Adjust progress indicator position if visible
    if (progressIndicator) {
      NSRect progressFrame = [progressIndicator frame];
      progressFrame.origin.y = scrollFrame.origin.y + (scrollFrame.size.height - progressFrame.size.height) / 2.0;
      [progressIndicator setFrame:progressFrame];
    }
  }
}

- (void)sendMessage:(id)sender {
  NSString *message = [[messageField textStorage] string];
  // Trim whitespace and newlines to check if message has actual content
  NSString *trimmedMessage = [message stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  if ([trimmedMessage length] == 0) return;
  
  // Add to current conversation
  Conversation *current = [[ConversationManager sharedManager] currentConversation];
  if (current) {
    NSDictionary *userMsg = [NSDictionary dictionaryWithObjectsAndKeys:
                  @"user", @"role",
                  trimmedMessage, @"content",
                  nil];
    [current addMessage:userMsg];
    [[ConversationManager sharedManager] saveCurrentConversation];
  }
  
  // Add user message to chat
  [self appendMessage:trimmedMessage fromUser:YES];
  [messageField setString:@""];
  // Force immediate height adjustment after clearing
  [self performSelector:@selector(adjustMessageFieldHeight) withObject:nil afterDelay:0.0];
  
  // Update table to show new summary
  [conversationTable reloadData];
  
  // Disable controls and show progress
  [messageField setEditable:NO];
  [sendButton setEnabled:NO];
	[progressIndicator setHidden:NO];
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
  [apiManager sendMessage:trimmedMessage withAPIKey:apiKey];
}

- (void)resetControls {
  [messageField setEditable:YES];
  [sendButton setEnabled:YES];
  [progressIndicator stopAnimation:self];
	[progressIndicator setHidden:YES];
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
  // float messageFontSize = systemFontSize + fontAdjust;    // Message font (13.0 base) - unused
  
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
  NSDictionary *parseResult = [self parseMarkdownWithCodeBlocks:message isUser:isUser];
  NSAttributedString *messageStr = [parseResult objectForKey:@"attributedString"];
  NSArray *codeBlocks = [parseResult objectForKey:@"codeBlocks"];
  
  // Calculate offset for code block ranges
  NSUInteger baseOffset = [[chatTextView string] length] + [sender length];
  
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
  
  // Add copy buttons for code blocks
  if (codeBlocks && [codeBlocks count] > 0) {
    NSEnumerator *enumerator = [codeBlocks objectEnumerator];
    NSDictionary *codeBlock;
    while ((codeBlock = [enumerator nextObject])) {
      NSString *code = [codeBlock objectForKey:@"code"];
      NSRange range = [[codeBlock objectForKey:@"range"] rangeValue];
      // Adjust range to account for position in full text
      range.location += baseOffset;
      [self addCodeBlockButton:code atRange:range];
    }
  }
  
  // Scroll to bottom
  [chatTextView scrollRangeToVisible:NSMakeRange([[chatTextView string] length], 0)];
}

- (void)clearConversation {
  // Clear the chat text view
  [[chatTextView textStorage] deleteCharactersInRange:NSMakeRange(0, [[chatTextView string] length])];
  
  // Clear code block buttons
  [self removeAllCodeBlockButtons];
  
  // Clear the API manager's conversation history
  [apiManager release];
  apiManager = [[ClaudeAPIManager alloc] init];
  [apiManager setDelegate:self];
  
  // Reset the message field
  [messageField setString:@""];
  // Force immediate height adjustment after clearing
  [self performSelector:@selector(adjustMessageFieldHeight) withObject:nil afterDelay:0.0];
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
    } else if ([model rangeOfString:@"claude-sonnet-4-5-20250929"].location != NSNotFound) { 
		modelDisplay = @"Sonnet 4.5";
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
  
  // Update text view background and text color using semantic colors
  [chatTextView setBackgroundColor:[ThemeColors textBackgroundColorForDarkMode:isDark]];
  [chatTextView setTextColor:[ThemeColors labelColorForDarkMode:isDark]];
  [chatTextView setInsertionPointColor:[ThemeColors labelColorForDarkMode:isDark]];
  [scrollView setBackgroundColor:[ThemeColors windowBackgroundColorForDarkMode:isDark]];
  
  // Update window background
  [[self window] setBackgroundColor:[ThemeColors windowBackgroundColorForDarkMode:isDark]];
  
  // Update input field colors and font
  [messageField setTextColor:[ThemeColors labelColorForDarkMode:isDark]];
  [messageField setBackgroundColor:[ThemeColors controlBackgroundColorForDarkMode:isDark]];
  [messageField setInsertionPointColor:[ThemeColors labelColorForDarkMode:isDark]];
  [messageScrollView setBackgroundColor:[ThemeColors controlBackgroundColorForDarkMode:isDark]];
  
  // Apply user's chosen proportional font to input field
  NSString *propFontName = [appDelegate proportionalFontName];
  float propFontSize = [appDelegate proportionalFontSize];
  NSFont *inputFont = [NSFont fontWithName:propFontName size:propFontSize];
  if (!inputFont) inputFont = [NSFont systemFontOfSize:propFontSize];
  [messageField setFont:inputFont];
  
  // Update button text colors by setting their attributed title
  NSColor *buttonTextColor = [ThemeColors labelColorForDarkMode:isDark];
  
  // Update Send button
  NSMutableAttributedString *sendTitle = [[NSMutableAttributedString alloc] initWithString:[sendButton title]];
  [sendTitle addAttribute:NSForegroundColorAttributeName 
            value:buttonTextColor 
            range:NSMakeRange(0, [sendTitle length])];
  [sendButton setAttributedTitle:sendTitle];
  [sendTitle release];
  
  // Update other buttons in control bar
  NSView *contentView = [[self window] contentView];
  NSArray *allSubviews = [contentView subviews];
  int j;
  for (j = 0; j < [allSubviews count]; j++) {
    id subview = [allSubviews objectAtIndex:j];
    
    // Find control bar and update its buttons
    if ([subview isKindOfClass:[NSView class]]) {
      NSArray *controlBarSubviews = [subview subviews];
      int k;
      for (k = 0; k < [controlBarSubviews count]; k++) {
        id controlView = [controlBarSubviews objectAtIndex:k];
        if ([controlView isKindOfClass:[NSButton class]]) {
          NSButton *button = (NSButton *)controlView;
          NSMutableAttributedString *buttonTitle = [[NSMutableAttributedString alloc] initWithString:[button title]];
          [buttonTitle addAttribute:NSForegroundColorAttributeName 
                     value:buttonTextColor 
                     range:NSMakeRange(0, [buttonTitle length])];
          [button setAttributedTitle:buttonTitle];
          [buttonTitle release];
        }
      }
    }
  }
  
  // Update drawer if exists
  if (conversationDrawer) {
    NSView *drawerView = [conversationDrawer contentView];
    
    // Update drawer background if it's a ThemedView
    if ([drawerView isKindOfClass:[ThemedView class]]) {
      [(ThemedView *)drawerView setDarkMode:isDark];
    }
    
    // Update all subviews in drawer
    NSArray *subviews = [drawerView subviews];
    int i;
    for (i = 0; i < [subviews count]; i++) {
      id view = [subviews objectAtIndex:i];
      if ([view isKindOfClass:[NSTextField class]]) {
        NSTextField *field = (NSTextField *)view;
        [field setTextColor:[ThemeColors labelColorForDarkMode:isDark]];
      } else if ([view isKindOfClass:[NSButton class]]) {
        NSButton *button = (NSButton *)view;
        NSMutableAttributedString *buttonTitle = [[NSMutableAttributedString alloc] initWithString:[button title]];
        [buttonTitle addAttribute:NSForegroundColorAttributeName 
                   value:buttonTextColor 
                   range:NSMakeRange(0, [buttonTitle length])];
        [button setAttributedTitle:buttonTitle];
        [buttonTitle release];
      } else if ([view isKindOfClass:[NSScrollView class]]) {
        NSScrollView *scroll = (NSScrollView *)view;
        [scroll setBackgroundColor:[ThemeColors controlBackgroundColorForDarkMode:isDark]];
        [scroll setDrawsBackground:YES];
      }
    }
    
    [[conversationDrawer contentView] setNeedsDisplay:YES];
    
    // Set table view background to match window background
    [conversationTable setBackgroundColor:[ThemeColors windowBackgroundColorForDarkMode:isDark]];
    
    // Set grid color to be subtle
    if (isDark) {
      [conversationTable setGridColor:[NSColor colorWithCalibratedWhite:0.2 alpha:0.5]];
    } else {
      [conversationTable setGridColor:[NSColor colorWithCalibratedWhite:0.85 alpha:0.5]];
    }
    
    [conversationTable reloadData];
  }
  
  // Refresh existing text colors
  [self refreshChatColors];
}

- (void)updateFontSize {
  // Update input field font
  AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
  NSString *propFontName = [appDelegate proportionalFontName];
  float propFontSize = [appDelegate proportionalFontSize];
  NSFont *inputFont = [NSFont fontWithName:propFontName size:propFontSize];
  if (!inputFont) inputFont = [NSFont systemFontOfSize:propFontSize];
  [messageField setFont:inputFont];
  
  // Refresh the chat with new font sizes
  [self refreshChatColors];
}

- (void)refreshChatColors {
  // Re-render all messages with new colors/fonts
  NSMutableAttributedString *newHistory = [[NSMutableAttributedString alloc] init];
  
  // Get current conversation messages
  Conversation *currentConv = [[ConversationManager sharedManager] currentConversation];
  if (currentConv && [currentConv messages]) {
    NSArray *messages = [currentConv messages];
    int i;
    for (i = 0; i < [messages count]; i++) {
      NSDictionary *msg = [messages objectAtIndex:i];
      NSString *role = [msg objectForKey:@"role"];
      NSString *content = [msg objectForKey:@"content"];
      
      BOOL isUser = [role isEqualToString:@"user"];
      NSString *sender = isUser ? @"You: " : @"Claude: ";
      
      // Re-parse markdown with current theme colors
      AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
      BOOL isDark = [appDelegate isDarkMode];
      NSColor *senderColor = isUser ? 
        [ThemeColors systemBlueForDarkMode:isDark] : 
        [ThemeColors systemPurpleForDarkMode:isDark];
      
      NSFont *propFont = [NSFont fontWithName:[appDelegate proportionalFontName] 
                         size:[appDelegate proportionalFontSize]];
      if (!propFont) propFont = [NSFont systemFontOfSize:[appDelegate proportionalFontSize]];
      
      NSFont *boldFont = [[NSFontManager sharedFontManager] convertFont:propFont toHaveTrait:NSBoldFontMask];
      if (!boldFont) boldFont = [NSFont boldSystemFontOfSize:[propFont pointSize]];
      
      NSAttributedString *senderStr = [[NSAttributedString alloc] initWithString:sender 
                                       attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                             boldFont, NSFontAttributeName,
                                             senderColor, NSForegroundColorAttributeName,
                                             nil]];
      NSAttributedString *messageStr = [self parseMarkdown:content isUser:isUser];
      
      [newHistory appendAttributedString:senderStr];
      [senderStr release];
      [newHistory appendAttributedString:messageStr];
      
      if (i < [messages count] - 1) {
        NSAttributedString *newline = [[NSAttributedString alloc] initWithString:@"\n\n" 
                                         attributes:[NSDictionary dictionary]];
        [newHistory appendAttributedString:newline];
        [newline release];
      }
    }
  }
  
  // Update the text view
  [chatHistory release];
  chatHistory = newHistory;
  [[chatTextView textStorage] setAttributedString:chatHistory];
  
  // Scroll to bottom if we were already at bottom
  NSScrollView *enclosingScrollView = [chatTextView enclosingScrollView];
  NSClipView *clipView = [enclosingScrollView contentView];
  NSRect docRect = [[enclosingScrollView documentView] frame];
  NSRect clipRect = [clipView bounds];
  
  if (NSMaxY(clipRect) >= NSMaxY(docRect) - 10) {
    // Scroll to the end of the document
    NSRange range = NSMakeRange([[chatTextView textStorage] length], 0);
    [chatTextView scrollRangeToVisible:range];
  }
}

- (NSDictionary *)parseMarkdownWithCodeBlocks:(NSString *)text isUser:(BOOL)isUser {
  NSMutableArray *codeBlocks = [NSMutableArray array];
  NSAttributedString *attributedString = [self parseMarkdownInternal:text isUser:isUser codeBlocks:codeBlocks];
  
  return [NSDictionary dictionaryWithObjectsAndKeys:
      attributedString, @"attributedString",
      codeBlocks, @"codeBlocks",
      nil];
}

- (NSAttributedString *)parseMarkdown:(NSString *)text isUser:(BOOL)isUser {
  return [self parseMarkdownInternal:text isUser:isUser codeBlocks:nil];
}

- (NSAttributedString *)parseMarkdownInternal:(NSString *)text isUser:(BOOL)isUser codeBlocks:(NSMutableArray *)codeBlocksArray {
  NSMutableAttributedString *result = [[NSMutableAttributedString alloc] init];
  
  AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
  BOOL isDark = [appDelegate isDarkMode];
  
  // Use font preferences
  NSString *propFontName = [appDelegate proportionalFontName];
  NSString *monoFontName = [appDelegate monospaceFontName];
  float propFontSize = [appDelegate proportionalFontSize];
  float monoFontSize = [appDelegate monospaceFontSize];
  
  NSFont *propFont = [NSFont fontWithName:propFontName size:propFontSize];
  if (!propFont) propFont = [NSFont systemFontOfSize:propFontSize];
  
  NSFont *monoFont = [NSFont fontWithName:monoFontName size:monoFontSize];
  if (!monoFont) monoFont = [NSFont userFixedPitchFontOfSize:monoFontSize];
  
  NSColor *textColor = [ThemeColors labelColorForDarkMode:isDark];
  NSColor *codeColor = [ThemeColors codeColorForDarkMode:isDark];
  
  // Basic markdown parsing
  NSArray *lines = [text componentsSeparatedByString:@"\n"];
  int i;
  BOOL inCodeBlock = NO;
  NSMutableString *codeBlockContent = nil;
  
  for (i = 0; i < [lines count]; i++) {
    NSString *line = [lines objectAtIndex:i];
    NSMutableAttributedString *lineAttr = [[NSMutableAttributedString alloc] init];
    
    // Check for code block markers (```)
    if ([line hasPrefix:@"```"]) {
      if (!inCodeBlock) {
        // Start of code block
        inCodeBlock = YES;
        codeBlockContent = [[NSMutableString alloc] init];
        continue; // Skip this line
      } else {
        // End of code block
        inCodeBlock = NO;
        if (codeBlockContent && [codeBlockContent length] > 0) {
          // Remove trailing newline if present
          NSString *finalCodeContent = [[codeBlockContent copy] autorelease];
          if ([finalCodeContent hasSuffix:@"\n"]) {
            finalCodeContent = [finalCodeContent substringToIndex:[finalCodeContent length] - 1];
          }
          
          // Track the location where we're adding this code block
          NSRange codeRange = NSMakeRange([result length], [finalCodeContent length]);
          
          NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                       monoFont, NSFontAttributeName,
                       codeColor, NSForegroundColorAttributeName,
                       nil];
          [result appendAttributedString:[[[NSAttributedString alloc] initWithString:finalCodeContent attributes:attrs] autorelease]];
          
          // Store code block info for button creation
          if (codeBlocksArray) {
            NSDictionary *codeBlockInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                             finalCodeContent, @"code",
                             [NSValue valueWithRange:codeRange], @"range",
                             nil];
            [codeBlocksArray addObject:codeBlockInfo];
          }
        }
        [codeBlockContent release];
        codeBlockContent = nil;
        
        if (i < [lines count] - 1) {
          [result appendAttributedString:[[[NSAttributedString alloc] initWithString:@"\n"] autorelease]];
        }
        continue;
      }
    }
    
    if (inCodeBlock) {
      // Add line to code block
      [codeBlockContent appendString:line];
      [codeBlockContent appendString:@"\n"];
      continue;
    }
    
    // Check for headers (# ## ###)
    if ([line hasPrefix:@"### "]) {
      NSString *header = [line substringFromIndex:4];
      NSFont *headerFont = [[NSFontManager sharedFontManager] convertFont:propFont toHaveTrait:NSBoldFontMask];
      headerFont = [[NSFontManager sharedFontManager] convertFont:headerFont toSize:propFontSize + 1];
      NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                   headerFont, NSFontAttributeName,
                   textColor, NSForegroundColorAttributeName,
                   nil];
      [lineAttr appendAttributedString:[[[NSAttributedString alloc] initWithString:header attributes:attrs] autorelease]];
    }
    else if ([line hasPrefix:@"## "]) {
      NSString *header = [line substringFromIndex:3];
      NSFont *headerFont = [[NSFontManager sharedFontManager] convertFont:propFont toHaveTrait:NSBoldFontMask];
      headerFont = [[NSFontManager sharedFontManager] convertFont:headerFont toSize:propFontSize + 2];
      NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                   headerFont, NSFontAttributeName,
                   textColor, NSForegroundColorAttributeName,
                   nil];
      [lineAttr appendAttributedString:[[[NSAttributedString alloc] initWithString:header attributes:attrs] autorelease]];
    }
    else if ([line hasPrefix:@"# "]) {
      NSString *header = [line substringFromIndex:2];
      NSFont *headerFont = [[NSFontManager sharedFontManager] convertFont:propFont toHaveTrait:NSBoldFontMask];
      headerFont = [[NSFontManager sharedFontManager] convertFont:headerFont toSize:propFontSize + 3];
      NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                   headerFont, NSFontAttributeName,
                   textColor, NSForegroundColorAttributeName,
                   nil];
      [lineAttr appendAttributedString:[[[NSAttributedString alloc] initWithString:header attributes:attrs] autorelease]];
    }
    // Check for bullet points
    else if ([line hasPrefix:@"- "] || [line hasPrefix:@"* "]) {
      NSString *bullet = @"• ";
      NSString *content = [line substringFromIndex:2];
      NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                   propFont, NSFontAttributeName,
                   textColor, NSForegroundColorAttributeName,
                   nil];
      [lineAttr appendAttributedString:[[[NSAttributedString alloc] initWithString:bullet attributes:attrs] autorelease]];
      // Parse inline markdown in bullet content
      [self parseInlineMarkdown:content into:lineAttr propFont:propFont monoFont:monoFont textColor:textColor codeColor:codeColor];
    }
    // Check for code blocks (simple backtick detection)
    else if ([line hasPrefix:@"`"] && [line hasSuffix:@"`"] && [line length] > 2) {
      NSString *code = [line substringWithRange:NSMakeRange(1, [line length] - 2)];
      NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                   monoFont, NSFontAttributeName,
                   codeColor, NSForegroundColorAttributeName,
                   nil];
      [lineAttr appendAttributedString:[[[NSAttributedString alloc] initWithString:code attributes:attrs] autorelease]];
    }
    // Regular text with inline formatting
    else {
      [self parseInlineMarkdown:line into:lineAttr propFont:propFont monoFont:monoFont textColor:textColor codeColor:codeColor];
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
          propFont:(NSFont *)propFont
          monoFont:(NSFont *)monoFont
           textColor:(NSColor *)textColor 
           codeColor:(NSColor *)codeColor {
  
  // Simple inline parsing for **bold**, *italic*, __underline__, and `code`
  NSMutableString *remaining = [NSMutableString stringWithString:text];
  
  while ([remaining length] > 0) {
    // Check for formatting markers
    NSRange boldRange = [remaining rangeOfString:@"**"];
    NSRange italicRange = [remaining rangeOfString:@"*"];
    NSRange underlineRange = [remaining rangeOfString:@"__"];
    NSRange codeRange = [remaining rangeOfString:@"`"];
    
    // Find the earliest marker
    NSUInteger minLocation = [remaining length];
    NSString *markerType = nil;
    
    if (boldRange.location != NSNotFound && boldRange.location < minLocation) {
      minLocation = boldRange.location;
      markerType = @"bold";
    }
    if (underlineRange.location != NSNotFound && underlineRange.location < minLocation) {
      minLocation = underlineRange.location;
      markerType = @"underline";
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
                   propFont, NSFontAttributeName,
                   textColor, NSForegroundColorAttributeName,
                   nil];
      [result appendAttributedString:[[[NSAttributedString alloc] initWithString:remaining attributes:attrs] autorelease]];
      break;
    }
    
    // Add text before the marker
    if (minLocation > 0) {
      NSString *before = [remaining substringToIndex:minLocation];
      NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                   propFont, NSFontAttributeName,
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
        NSFont *boldFont = [[NSFontManager sharedFontManager] convertFont:propFont toHaveTrait:NSBoldFontMask];
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                     boldFont, NSFontAttributeName,
                     textColor, NSForegroundColorAttributeName,
                     nil];
        [result appendAttributedString:[[[NSAttributedString alloc] initWithString:boldText attributes:attrs] autorelease]];
        [remaining deleteCharactersInRange:NSMakeRange(0, endRange.location + 2)];
      } else {
        // No closing marker, treat as literal
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                     propFont, NSFontAttributeName,
                     textColor, NSForegroundColorAttributeName,
                     nil];
        [result appendAttributedString:[[[NSAttributedString alloc] initWithString:@"**" attributes:attrs] autorelease]];
      }
    }
    else if ([markerType isEqualToString:@"italic"]) {
      [remaining deleteCharactersInRange:NSMakeRange(0, minLocation + 1)];
      NSRange endRange = [remaining rangeOfString:@"*"];
      if (endRange.location != NSNotFound) {
        NSString *italicText = [remaining substringToIndex:endRange.location];
        // Use oblique trait for italic on Tiger
        NSFont *italicFont = [[NSFontManager sharedFontManager] 
                    convertFont:propFont
                    toHaveTrait:NSItalicFontMask];
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                     italicFont, NSFontAttributeName,
                     textColor, NSForegroundColorAttributeName,
                     nil];
        [result appendAttributedString:[[[NSAttributedString alloc] initWithString:italicText attributes:attrs] autorelease]];
        [remaining deleteCharactersInRange:NSMakeRange(0, endRange.location + 1)];
      } else {
        // No closing marker, treat as literal
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                     propFont, NSFontAttributeName,
                     textColor, NSForegroundColorAttributeName,
                     nil];
        [result appendAttributedString:[[[NSAttributedString alloc] initWithString:@"*" attributes:attrs] autorelease]];
      }
    }
    else if ([markerType isEqualToString:@"underline"]) {
      [remaining deleteCharactersInRange:NSMakeRange(0, minLocation + 2)];
      NSRange endRange = [remaining rangeOfString:@"__"];
      if (endRange.location != NSNotFound) {
        NSString *underlineText = [remaining substringToIndex:endRange.location];
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                     propFont, NSFontAttributeName,
                     textColor, NSForegroundColorAttributeName,
                     [NSNumber numberWithInt:NSUnderlineStyleSingle], NSUnderlineStyleAttributeName,
                     nil];
        [result appendAttributedString:[[[NSAttributedString alloc] initWithString:underlineText attributes:attrs] autorelease]];
        [remaining deleteCharactersInRange:NSMakeRange(0, endRange.location + 2)];
      } else {
        // No closing marker, treat as literal
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                     propFont, NSFontAttributeName,
                     textColor, NSForegroundColorAttributeName,
                     nil];
        [result appendAttributedString:[[[NSAttributedString alloc] initWithString:@"__" attributes:attrs] autorelease]];
      }
    }
    else if ([markerType isEqualToString:@"code"]) {
      [remaining deleteCharactersInRange:NSMakeRange(0, minLocation + 1)];
      NSRange endRange = [remaining rangeOfString:@"`"];
      if (endRange.location != NSNotFound) {
        NSString *codeText = [remaining substringToIndex:endRange.location];
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                     monoFont, NSFontAttributeName,
                     codeColor, NSForegroundColorAttributeName,
                     nil];
        [result appendAttributedString:[[[NSAttributedString alloc] initWithString:codeText attributes:attrs] autorelease]];
        [remaining deleteCharactersInRange:NSMakeRange(0, endRange.location + 1)];
      } else {
        // No closing marker, treat as literal
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                     monoFont, NSFontAttributeName,
                     codeColor, NSForegroundColorAttributeName,
                     nil];
        [result appendAttributedString:[[[NSAttributedString alloc] initWithString:@"`" attributes:attrs] autorelease]];
      }
    }
  }
}

#pragma mark - Control Actions

- (void)toggleDrawer:(id)sender {
  if ([conversationDrawer state] == NEDrawerStateOpen ||
    [conversationDrawer state] == NEDrawerStateOpening) {
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
    [[current messages] removeAllObjects];
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
    if (apiManager) {
      [apiManager setDelegate:nil];
      [apiManager release];
      apiManager = nil;
    }
    apiManager = [[ClaudeAPIManager alloc] init];
    [apiManager setDelegate:self];
    
    // Reload messages from conversation
    int i;
    for (i = 0; i < [[current messages] count]; i++) {
      NSDictionary *msg = [[current messages] objectAtIndex:i];
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

- (void)tableView:(NSTableView *)tableView 
  willDisplayCell:(id)cell 
   forTableColumn:(NSTableColumn *)tableColumn 
        row:(NSInteger)row {
  AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
  BOOL isDark = [appDelegate isDarkMode];
  
  // Set text color for the cell
  if ([cell isKindOfClass:[NSTextFieldCell class]]) {
    NSTextFieldCell *textCell = (NSTextFieldCell *)cell;
    
    // Set text color based on selection and theme
    if ([tableView selectedRow] == row) {
      // Selected row - white text on selection
      [textCell setTextColor:[NSColor whiteColor]];
      [textCell setDrawsBackground:NO];
    } else {
      // Normal row - use theme-appropriate text color
      [textCell setTextColor:[ThemeColors labelColorForDarkMode:isDark]];
      
      // Set alternating row background colors
      if (row % 2 == 1) {
        [textCell setBackgroundColor:[ThemeColors alternatingRowColorForDarkMode:isDark]];
        [textCell setDrawsBackground:YES];
      } else {
        [textCell setBackgroundColor:[ThemeColors windowBackgroundColorForDarkMode:isDark]];
        [textCell setDrawsBackground:YES];
      }
    }
  }
}

- (void)fontPreferencesChanged:(NSNotification *)notification {
  // Refresh the chat history with new fonts
  NSMutableAttributedString *newHistory = [[NSMutableAttributedString alloc] init];
  
  // Get current conversation messages
  Conversation *currentConv = [[ConversationManager sharedManager] currentConversation];
  if (currentConv && [currentConv messages]) {
    NSArray *messages = [currentConv messages];
    int i;
    for (i = 0; i < [messages count]; i++) {
      NSDictionary *msg = [messages objectAtIndex:i];
      NSString *role = [msg objectForKey:@"role"];
      NSString *content = [msg objectForKey:@"content"];
      
      BOOL isUser = [role isEqualToString:@"user"];
      NSString *sender = isUser ? @"You: " : @"Claude: ";
      
      // Re-parse markdown with new fonts
      AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
      BOOL isDark = [appDelegate isDarkMode];
      NSColor *senderColor = isUser ? 
        [ThemeColors userTextColorForDarkMode:isDark] : 
        [ThemeColors claudeTextColorForDarkMode:isDark];
      
      NSFont *propFont = [NSFont fontWithName:[appDelegate proportionalFontName] 
                         size:[appDelegate proportionalFontSize]];
      if (!propFont) propFont = [NSFont systemFontOfSize:[appDelegate proportionalFontSize]];
      
      NSAttributedString *senderStr = [[NSAttributedString alloc] initWithString:sender 
                                       attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                             [[NSFontManager sharedFontManager] convertFont:propFont toHaveTrait:NSBoldFontMask], NSFontAttributeName,
                                             senderColor, NSForegroundColorAttributeName,
                                             nil]];
      NSAttributedString *messageStr = [self parseMarkdown:content isUser:isUser];
      
      [newHistory appendAttributedString:senderStr];
      [senderStr release];
      [newHistory appendAttributedString:messageStr];
      
      if (i < [messages count] - 1) {
        NSAttributedString *newline = [[NSAttributedString alloc] initWithString:@"\n\n" 
                                         attributes:[NSDictionary dictionary]];
        [newHistory appendAttributedString:newline];
        [newline release];
      }
    }
  }
  
  // Update the text view
  [chatHistory release];
  chatHistory = newHistory;
  [[chatTextView textStorage] setAttributedString:chatHistory];
  
  // Scroll to bottom
  NSRange endRange = NSMakeRange([chatHistory length], 0);
  [chatTextView scrollRangeToVisible:endRange];
}

#pragma mark - Code Block Button Management

- (void)removeAllCodeBlockButtons {
  // Remove all existing code block buttons
  NSEnumerator *enumerator = [codeBlockButtons objectEnumerator];
  NSButton *button;
  while ((button = [enumerator nextObject])) {
    [button removeFromSuperview];
  }
  [codeBlockButtons removeAllObjects];
  [codeBlockRanges removeAllObjects];
}

- (void)addCodeBlockButton:(NSString *)code atRange:(NSRange)range {
  // Store the code block info
  NSDictionary *blockInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                 code, @"code",
                 [NSValue valueWithRange:range], @"range",
                 nil];
  [codeBlockRanges addObject:blockInfo];
  
  // Create a copy button for this code block
  NSButton *copyButton = [[[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 50, 20)] autorelease];
  [copyButton setTitle:@"Copy"];
  [copyButton setBezelStyle:NSRoundedBezelStyle];
  [copyButton setFont:[NSFont systemFontOfSize:10]];
  [copyButton setTag:[codeBlockRanges count] - 1]; // Use index as tag
  [copyButton setTarget:self];
  [copyButton setAction:@selector(copyCodeBlock:)];
  [copyButton setAlphaValue:0.9];
  
  [codeBlockButtons addObject:copyButton];
  [self updateCodeBlockButtonPositions];
}

- (void)updateCodeBlockButtonPositions {
  // Update positions of all code block buttons based on text layout
  int i;
  for (i = 0; i < [codeBlockButtons count]; i++) {
    NSButton *button = [codeBlockButtons objectAtIndex:i];
    NSDictionary *blockInfo = [codeBlockRanges objectAtIndex:i];
    NSRange range = [[blockInfo objectForKey:@"range"] rangeValue];
    
    if (range.location < [[chatTextView string] length]) {
      // Get the bounding rect for the code block
      NSRange glyphRange = [[chatTextView layoutManager] glyphRangeForCharacterRange:range 
                                     actualCharacterRange:NULL];
      NSRect boundingRect = [[chatTextView layoutManager] boundingRectForGlyphRange:glyphRange 
                                      inTextContainer:[chatTextView textContainer]];
      
      // Position button at top-right of code block
      NSPoint textOrigin = [chatTextView textContainerOrigin];
      NSRect buttonFrame = [button frame];
      buttonFrame.origin.x = boundingRect.origin.x + boundingRect.size.width - buttonFrame.size.width - 5 + textOrigin.x;
      buttonFrame.origin.y = boundingRect.origin.y + 2 + textOrigin.y;
      
      // Convert to scroll view coordinates
      NSRect convertedFrame = [chatTextView convertRect:buttonFrame toView:scrollView];
      [button setFrame:convertedFrame];
      
      if (![button superview]) {
        [scrollView addSubview:button];
      }
    }
  }
}

- (void)copyCodeBlock:(id)sender {
  NSButton *button = (NSButton *)sender;
  int index = [button tag];
  
  if (index >= 0 && index < [codeBlockRanges count]) {
    NSDictionary *blockInfo = [codeBlockRanges objectAtIndex:index];
    NSString *code = [blockInfo objectForKey:@"code"];
    
    // Copy to pasteboard
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    [pasteboard setString:code forType:NSStringPboardType];
    
    // Visual feedback
    NSString *originalTitle = [button title];
    [button setTitle:@"Copied!"];
    [button setEnabled:NO];
    
    // Reset after delay
    [self performSelector:@selector(resetCopyButton:) 
           withObject:[NSDictionary dictionaryWithObjectsAndKeys:
                 button, @"button",
                 originalTitle, @"title",
                 nil]
           afterDelay:1.0];
  }
}

- (void)resetCopyButton:(NSDictionary *)info {
  NSButton *button = [info objectForKey:@"button"];
  NSString *title = [info objectForKey:@"title"];
  [button setTitle:title];
  [button setEnabled:YES];
}

/**
 * Forces dark mode rendering for the drawer by manipulating
 * the drawer window's appearance at a deeper level.
 * Only use if the standard approach isn't working.
 */
- (void)forceDrawerDarkMode:(NSDrawer *)drawer isDark:(BOOL)isDark {
  // Get the drawer's private window
  SEL windowSelector = @selector(_drawerWindow);
  
  if (![drawer respondsToSelector:windowSelector])
    return;
  
  NSWindow *drawerWindow = [drawer performSelector:windowSelector];
  
  if (!drawerWindow)
    return;
  
  // Try to set the window's appearance if on 10.14+
  if ([drawerWindow respondsToSelector:@selector(setAppearance:)]) {
    Class NSAppearanceClass = NSClassFromString(@"NSAppearance");
    
    if (NSAppearanceClass) {
      SEL namedSelector = @selector(appearanceNamed:);
      
      if ([NSAppearanceClass respondsToSelector:namedSelector]) {
        NSString *appearanceName = isDark ? 
          @"NSAppearanceNameVibrantDark" : 
          @"NSAppearanceNameAqua";
        
        id appearance = [NSAppearanceClass performSelector:namedSelector 
                                                 withObject:appearanceName];
        
        if (appearance)
          [drawerWindow performSelector:@selector(setAppearance:) 
                             withObject:appearance];
      }
    }
  }
  
  // Set hasShadow to NO to reduce chrome visibility
  [drawerWindow setHasShadow:NO];
  
  // Make the window fully opaque
  [drawerWindow setOpaque:YES];
  [drawerWindow setAlphaValue:1.0];
}

@end

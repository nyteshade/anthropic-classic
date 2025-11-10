//
//  AppDelegate.m
//  ClaudeChat
//

#import "AppDelegate.h"
#import "ChatWindowController.h"
#import "ThemeColors.h"
#import "NSObject+Associations.h"
#import "SAFEArc.h"

@implementation AppDelegate

- (void)dealloc {
  SAFE_ARC_RELEASE(chatWindowController);
  SAFE_ARC_RELEASE(apiKey);
  SAFE_ARC_RELEASE(selectedModel);
  SAFE_ARC_RELEASE(availableModels);
  SAFE_ARC_RELEASE(monospaceFontName);
  SAFE_ARC_RELEASE(proportionalFontName);
  SAFE_ARC_SUPER_DEALLOC;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
  // Initialize models array
  availableModels = [[NSMutableArray alloc] init];
  
  // Set up menus
  [self setupMenus];
  
  // Load preferences
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  apiKey = SAFE_ARC_RETAIN([defaults stringForKey:@"ClaudeAPIKey"]);
  selectedModel = SAFE_ARC_RETAIN([defaults stringForKey:@"ClaudeSelectedModel"]);
  isDarkMode = [defaults boolForKey:@"ClaudeChatDarkMode"];
  fontSizeAdjustment = [defaults integerForKey:@"ClaudeChatFontSizeAdjustment"];

  // Load font preferences
  monospaceFontName = SAFE_ARC_RETAIN([defaults stringForKey:@"ClaudeChatMonospaceFontName"]);
  proportionalFontName = SAFE_ARC_RETAIN([defaults stringForKey:@"ClaudeChatProportionalFontName"]);
  monospaceFontSize = [defaults floatForKey:@"ClaudeChatMonospaceFontSize"];
  proportionalFontSize = [defaults floatForKey:@"ClaudeChatProportionalFontSize"];

  // Set default fonts if not configured
  if (!monospaceFontName || [monospaceFontName length] == 0) {
    monospaceFontName = SAFE_ARC_RETAIN(@"Monaco");
    monospaceFontSize = 11.0;
  }
  if (!proportionalFontName || [proportionalFontName length] == 0) {
    proportionalFontName = SAFE_ARC_RETAIN(@"Lucida Grande");
    proportionalFontSize = 13.0;
  }
  if (monospaceFontSize == 0) monospaceFontSize = 11.0;
  if (proportionalFontSize == 0) proportionalFontSize = 13.0;

  // Default to Claude Haiku 3 if no model selected
  if (!selectedModel || [selectedModel length] == 0) {
    selectedModel = SAFE_ARC_RETAIN(@"claude-3-haiku-20240307");
  }
  
  // Create and show main window
  chatWindowController = [[ChatWindowController alloc] init];
  [chatWindowController showWindow:self];
  
  // Check for API key
  if (!apiKey || [apiKey length] == 0) {
    [self performSelector:@selector(showPreferencesWindow) withObject:nil afterDelay:0.5];
  } else {
    // Fetch available models if we have an API key
    [self fetchAvailableModels];
  }
}

- (void)applicationWillTerminate:(NSNotification *)notification {
  // Save preferences
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)apiKey {
  return apiKey;
}

- (void)setApiKey:(NSString *)key {
  if (apiKey != key) {
    SAFE_ARC_RELEASE(apiKey);
    apiKey = SAFE_ARC_RETAIN(key);

    // Save to preferences
    [[NSUserDefaults standardUserDefaults] setObject:apiKey forKey:@"ClaudeAPIKey"];
    [[NSUserDefaults standardUserDefaults] synchronize];
  }
}

- (void)showAPIKeyDialog {
  // Redirect to unified preferences
  [self showPreferencesWindow];
}

- (void)showPreferencesWindow {
  SAFE_ARC_AUTORELEASE_POOL_PUSH();
  NSLog(@"showPreferencesWindow called, preferencesWindow=%@", preferencesWindow);
  if (preferencesWindow) {
    [preferencesWindow makeKeyAndOrderFront:nil];
    SAFE_ARC_AUTORELEASE_POOL_POP();
    return;
  }
  
  // Create window with API and Font settings
  preferencesWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(100, 100, 500, 450)
                           styleMask:NSTitledWindowMask | NSClosableWindowMask
                             backing:NSBackingStoreBuffered
                             defer:NO];
  [preferencesWindow setTitle:@"Preferences"];
  [preferencesWindow center];
  [preferencesWindow setReleasedWhenClosed:NO];  // Important: don't release on close
  [preferencesWindow setDelegate:self];  // Set delegate for window events
  [preferencesWindow setBackgroundColor:[ThemeColors windowBackgroundColorForDarkMode:isDarkMode]];
  
  NSView *contentView = [preferencesWindow contentView];
  
  // Note: Can't use CALayer on Tiger, so we set window background color instead
  
  // === API Key Section ===
  NSTextField *apiLabel = [[[NSTextField alloc] initWithFrame:NSMakeRect(20, 400, 100, 20)] autorelease];
  [apiLabel setStringValue:@"API Key:"];
  [apiLabel setBezeled:NO];
  [apiLabel setDrawsBackground:NO];
  [apiLabel setEditable:NO];
  [apiLabel setTextColor:[ThemeColors labelColorForDarkMode:isDarkMode]];
  [contentView addSubview:apiLabel];
  
  NSTextField *apiField = [[[NSTextField alloc] initWithFrame:NSMakeRect(20, 370, 460, 22)] autorelease];
  [apiField setStringValue:apiKey ? apiKey : @""];
  [apiField setTag:200];
  [apiField setBackgroundColor:[ThemeColors controlBackgroundColorForDarkMode:isDarkMode]];
  [apiField setTextColor:[ThemeColors labelColorForDarkMode:isDarkMode]];
  [contentView addSubview:apiField];
  
  // === Font Settings Section ===
  NSTextField *fontTitle = [[[NSTextField alloc] initWithFrame:NSMakeRect(20, 330, 200, 20)] autorelease];
  [fontTitle setStringValue:@"Font Settings"];
  [fontTitle setBezeled:NO];
  [fontTitle setDrawsBackground:NO];
  [fontTitle setEditable:NO];
  [fontTitle setFont:[NSFont boldSystemFontOfSize:13]];
  [fontTitle setTextColor:[ThemeColors labelColorForDarkMode:isDarkMode]];
  [contentView addSubview:fontTitle];
  
  // Proportional Font
  NSTextField *propLabel = [[[NSTextField alloc] initWithFrame:NSMakeRect(20, 290, 120, 20)] autorelease];
  [propLabel setStringValue:@"Message Font:"];
  [propLabel setBezeled:NO];
  [propLabel setDrawsBackground:NO];
  [propLabel setEditable:NO];
  [propLabel setTextColor:[ThemeColors labelColorForDarkMode:isDarkMode]];
  [contentView addSubview:propLabel];
  
  NSFont *propFont = [NSFont fontWithName:proportionalFontName size:proportionalFontSize];
  if (!propFont) propFont = [NSFont systemFontOfSize:proportionalFontSize];
  
  NSTextField *propDisplay = [[[NSTextField alloc] initWithFrame:NSMakeRect(150, 290, 250, 20)] autorelease];
  [propDisplay setStringValue:[NSString stringWithFormat:@"%@ %.0fpt", [propFont displayName], [propFont pointSize]]];
  [propDisplay setBezeled:NO];
  [propDisplay setDrawsBackground:NO];
  [propDisplay setEditable:NO];
  [propDisplay setTag:301];
  [propDisplay setTextColor:[ThemeColors secondaryLabelColorForDarkMode:isDarkMode]];
  [contentView addSubview:propDisplay];
  
  NSButton *propButton = [[[NSButton alloc] initWithFrame:NSMakeRect(410, 285, 70, 25)] autorelease];
  [propButton setTitle:@"Select..."];
  [propButton setBezelStyle:NSRoundedBezelStyle];
  [propButton setTarget:self];
  [propButton setAction:@selector(selectProportionalFont:)];
  [contentView addSubview:propButton];
  
  // Monospace Font
  NSTextField *monoLabel = [[[NSTextField alloc] initWithFrame:NSMakeRect(20, 250, 120, 20)] autorelease];
  [monoLabel setStringValue:@"Code Font:"];
  [monoLabel setBezeled:NO];
  [monoLabel setDrawsBackground:NO];
  [monoLabel setEditable:NO];
  [monoLabel setTextColor:[ThemeColors labelColorForDarkMode:isDarkMode]];
  [contentView addSubview:monoLabel];
  
  NSFont *monoFont = [NSFont fontWithName:monospaceFontName size:monospaceFontSize];
  if (!monoFont) monoFont = [NSFont userFixedPitchFontOfSize:monospaceFontSize];
  
  NSTextField *monoDisplay = [[[NSTextField alloc] initWithFrame:NSMakeRect(150, 250, 250, 20)] autorelease];
  [monoDisplay setStringValue:[NSString stringWithFormat:@"%@ %.0fpt", [monoFont displayName], [monoFont pointSize]]];
  [monoDisplay setBezeled:NO];
  [monoDisplay setDrawsBackground:NO];
  [monoDisplay setEditable:NO];
  [monoDisplay setTag:303];
  [monoDisplay setTextColor:[ThemeColors secondaryLabelColorForDarkMode:isDarkMode]];
  [contentView addSubview:monoDisplay];
  
  NSButton *monoButton = [[[NSButton alloc] initWithFrame:NSMakeRect(410, 245, 70, 25)] autorelease];
  [monoButton setTitle:@"Select..."];
  [monoButton setBezelStyle:NSRoundedBezelStyle];
  [monoButton setTarget:self];
  [monoButton setAction:@selector(selectMonospaceFont:)];
  [contentView addSubview:monoButton];
  
  // Font Size Adjustment Info
  NSTextField *sizeInfo = [[[NSTextField alloc] initWithFrame:NSMakeRect(20, 200, 460, 40)] autorelease];
  [sizeInfo setStringValue:@"Use ⌘+ and ⌘- to adjust font sizes globally while chatting.\nUse ⌘0 to reset to default sizes."];
  [sizeInfo setBezeled:NO];
  [sizeInfo setDrawsBackground:NO];
  [sizeInfo setEditable:NO];
  [sizeInfo setFont:[NSFont systemFontOfSize:11]];
  [sizeInfo setTextColor:[ThemeColors tertiaryLabelColorForDarkMode:isDarkMode]];
  [contentView addSubview:sizeInfo];
  
  // === Preview Section ===
  NSTextField *previewTitle = [[[NSTextField alloc] initWithFrame:NSMakeRect(20, 150, 100, 20)] autorelease];
  [previewTitle setStringValue:@"Preview:"];
  [previewTitle setBezeled:NO];
  [previewTitle setDrawsBackground:NO];
  [previewTitle setEditable:NO];
  [previewTitle setTextColor:[ThemeColors labelColorForDarkMode:isDarkMode]];
  [contentView addSubview:previewTitle];
  
  NSTextView *previewText = [[[NSTextView alloc] initWithFrame:NSMakeRect(20, 50, 460, 90)] autorelease];
  [previewText setEditable:NO];
  [previewText setDrawsBackground:YES];
  [previewText setBackgroundColor:[ThemeColors controlBackgroundColorForDarkMode:isDarkMode]];
  
  // Add sample text with both fonts
  NSMutableAttributedString *sampleText = [[[NSMutableAttributedString alloc] init] autorelease];
  
  NSDictionary *messageAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
                  propFont, NSFontAttributeName,
                  [ThemeColors labelColorForDarkMode:isDarkMode], NSForegroundColorAttributeName,
                  nil];
  NSAttributedString *messageText = [[[NSAttributedString alloc] initWithString:@"This is a message using the proportional font.\n" 
                                    attributes:messageAttrs] autorelease];
  [sampleText appendAttributedString:messageText];
  
  NSDictionary *codeAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
                 monoFont, NSFontAttributeName,
                 [ThemeColors labelColorForDarkMode:isDarkMode], NSForegroundColorAttributeName,
                 nil];
  NSAttributedString *codeText = [[[NSAttributedString alloc] initWithString:@"def hello_world():\n  print('This is code using monospace font')" 
                                   attributes:codeAttrs] autorelease];
  [sampleText appendAttributedString:codeText];
  
  [[previewText textStorage] setAttributedString:sampleText];
  
  NSScrollView *scrollView = [[[NSScrollView alloc] initWithFrame:NSMakeRect(20, 50, 460, 90)] autorelease];
  [scrollView setDocumentView:previewText];
  [scrollView setHasVerticalScroller:YES];
  [scrollView setBorderType:NSBezelBorder];
  [contentView addSubview:scrollView];
  
  // === Buttons ===
  NSButton *cancelButton = [[[NSButton alloc] initWithFrame:NSMakeRect(310, 10, 80, 25)] autorelease];
  [cancelButton setTitle:@"Cancel"];
  [cancelButton setBezelStyle:NSRoundedBezelStyle];
  [cancelButton setTarget:self];
  [cancelButton setAction:@selector(cancelPreferences:)];
  [contentView addSubview:cancelButton];
  
  NSButton *applyButton = [[[NSButton alloc] initWithFrame:NSMakeRect(400, 10, 80, 25)] autorelease];
  [applyButton setTitle:@"Apply"];
  [applyButton setBezelStyle:NSRoundedBezelStyle];
  [applyButton setTarget:self];
  [applyButton setAction:@selector(applyPreferences:)];
  [applyButton setKeyEquivalent:@"\r"];  // Make it the default button
  [contentView addSubview:applyButton];
  
  NSLog(@"Created preferences window: %@", preferencesWindow);
  NSLog(@"Content view: %@", contentView);

  [preferencesWindow makeKeyAndOrderFront:nil];
  SAFE_ARC_AUTORELEASE_POOL_POP();
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
  return YES;
}

- (void)setupMenus {
  SAFE_ARC_AUTORELEASE_POOL_PUSH();
  NSLog(@"Setting up menus, self=%@", self);
  // Clear any existing menu first to prevent duplication
  [NSApp setMainMenu:nil];

  NSMenu *mainMenu = [[[NSMenu alloc] init] autorelease];
  NSMenuItem *menuItem;
  NSMenu *submenu;

  // Application menu (macOS will automatically rename to app name)
  menuItem = [mainMenu addItemWithTitle:@"" action:nil keyEquivalent:@""];
  submenu = [[[NSMenu alloc] initWithTitle:@"Apple"] autorelease];

  NSMenuItem *aboutItem = [submenu addItemWithTitle:@"About ClaudeChat" 
                         action:@selector(showAbout:) 
                    keyEquivalent:@""];
  [aboutItem setTarget:self];
  
  [submenu addItem:[NSMenuItem separatorItem]];
  
  NSMenuItem *prefsItem = [submenu addItemWithTitle:@"Preferences..." 
                         action:@selector(showPreferences:) 
                    keyEquivalent:@","];
  [prefsItem setTarget:self];
  NSLog(@"Set preferences menu target to %@, action=%@", self, NSStringFromSelector([prefsItem action]));
  
  [submenu addItem:[NSMenuItem separatorItem]];
  
  [submenu addItemWithTitle:@"Hide ClaudeChat" 
             action:@selector(hide:) 
        keyEquivalent:@"h"];
  
  [submenu addItemWithTitle:@"Hide Others" 
             action:@selector(hideOtherApplications:) 
        keyEquivalent:@"h"];
  [[submenu itemAtIndex:[submenu numberOfItems] - 1] 
    setKeyEquivalentModifierMask:NSCommandKeyMask | NSAlternateKeyMask];
  
  [submenu addItemWithTitle:@"Show All" 
             action:@selector(unhideAllApplications:) 
        keyEquivalent:@""];
  
  [submenu addItem:[NSMenuItem separatorItem]];
  
  [submenu addItemWithTitle:@"Quit ClaudeChat" 
             action:@selector(terminate:) 
        keyEquivalent:@"q"];
  
  [mainMenu setSubmenu:submenu forItem:menuItem];

  // IMPORTANT: On Leopard/Tiger, must explicitly set the Apple menu
  // Modern macOS does this automatically, but older versions need this call
  [NSApp setAppleMenu:submenu];

  // File menu
  menuItem = [mainMenu addItemWithTitle:@"File" action:nil keyEquivalent:@""];
  submenu = [[[NSMenu alloc] initWithTitle:@"File"] autorelease];
  
  [submenu addItemWithTitle:@"New Conversation" 
             action:@selector(newConversation:) 
        keyEquivalent:@"n"];
  
  [submenu addItem:[NSMenuItem separatorItem]];
  
  [submenu addItemWithTitle:@"Close" 
             action:@selector(performClose:) 
        keyEquivalent:@"w"];
  
  [mainMenu setSubmenu:submenu forItem:menuItem];
  
  // Edit menu
  menuItem = [mainMenu addItemWithTitle:@"Edit" action:nil keyEquivalent:@""];
  submenu = [[[NSMenu alloc] initWithTitle:@"Edit"] autorelease];
  
  [submenu addItemWithTitle:@"Undo" 
             action:@selector(undo:) 
        keyEquivalent:@"z"];
  
  [submenu addItemWithTitle:@"Redo" 
             action:@selector(redo:) 
        keyEquivalent:@"Z"];
  
  [submenu addItem:[NSMenuItem separatorItem]];
  
  [submenu addItemWithTitle:@"Cut" 
             action:@selector(cut:) 
        keyEquivalent:@"x"];
  
  [submenu addItemWithTitle:@"Copy" 
             action:@selector(copy:) 
        keyEquivalent:@"c"];
  
  [submenu addItemWithTitle:@"Paste" 
             action:@selector(paste:) 
        keyEquivalent:@"v"];
  
  [submenu addItemWithTitle:@"Delete" 
             action:@selector(delete:) 
        keyEquivalent:@""];
  
  [submenu addItemWithTitle:@"Select All" 
             action:@selector(selectAll:) 
        keyEquivalent:@"a"];
  
  [submenu addItem:[NSMenuItem separatorItem]];
  
  [submenu addItemWithTitle:@"Find" 
             action:@selector(performFindPanelAction:) 
        keyEquivalent:@"f"];
  
  [submenu addItemWithTitle:@"Find Next" 
             action:@selector(performFindPanelAction:) 
        keyEquivalent:@"g"];
  [[submenu itemAtIndex:[submenu numberOfItems] - 1] setTag:NSFindPanelActionNext];
  
  [submenu addItemWithTitle:@"Find Previous" 
             action:@selector(performFindPanelAction:) 
        keyEquivalent:@"G"];
  [[submenu itemAtIndex:[submenu numberOfItems] - 1] setTag:NSFindPanelActionPrevious];
  
  [mainMenu setSubmenu:submenu forItem:menuItem];
  
  // View menu
  menuItem = [mainMenu addItemWithTitle:@"View" action:nil keyEquivalent:@""];
  submenu = [[[NSMenu alloc] initWithTitle:@"View"] autorelease];
  
  // Theme submenu
  NSMenuItem *themeItem = [submenu addItemWithTitle:@"Theme" 
                         action:nil 
                    keyEquivalent:@""];
  NSMenu *themeMenu = [[[NSMenu alloc] initWithTitle:@"Theme"] autorelease];
  
  NSMenuItem *lightItem = [themeMenu addItemWithTitle:@"Light Mode" 
                          action:@selector(setLightTheme:) 
                       keyEquivalent:@""];
  [lightItem setTarget:self];
  [lightItem setState:isDarkMode ? NSOffState : NSOnState];
  
  NSMenuItem *darkItem = [themeMenu addItemWithTitle:@"Dark Mode" 
                         action:@selector(setDarkTheme:) 
                      keyEquivalent:@""];
  [darkItem setTarget:self];
  [darkItem setState:isDarkMode ? NSOnState : NSOffState];
  
  [submenu setSubmenu:themeMenu forItem:themeItem];
  
  [submenu addItem:[NSMenuItem separatorItem]];
  
  // Font size options
  NSMenuItem *increaseFontItem = [submenu addItemWithTitle:@"Increase Font Size" 
                             action:@selector(increaseFontSize:) 
                        keyEquivalent:@"+"];
  [increaseFontItem setTarget:self];
  
  NSMenuItem *decreaseFontItem = [submenu addItemWithTitle:@"Decrease Font Size" 
                             action:@selector(decreaseFontSize:) 
                        keyEquivalent:@"-"];
  [decreaseFontItem setTarget:self];
  
  NSMenuItem *resetFontItem = [submenu addItemWithTitle:@"Reset Font Size" 
                          action:@selector(resetFontSize:) 
                       keyEquivalent:@"0"];
  [resetFontItem setTarget:self];
  
  [mainMenu setSubmenu:submenu forItem:menuItem];
  
  // Models menu
  menuItem = [mainMenu addItemWithTitle:@"Models" action:nil keyEquivalent:@""];
  modelsMenu = [[[NSMenu alloc] initWithTitle:@"Models"] autorelease];
  
  // Add default models (will be replaced/updated when API call completes)
  [self addDefaultModelsToMenu];
  
  [mainMenu setSubmenu:modelsMenu forItem:menuItem];
  
  // Window menu
  menuItem = [mainMenu addItemWithTitle:@"Window" action:nil keyEquivalent:@""];
  submenu = [[[NSMenu alloc] initWithTitle:@"Window"] autorelease];
  
  [submenu addItemWithTitle:@"Minimize" 
             action:@selector(performMiniaturize:) 
        keyEquivalent:@"m"];
  
  [submenu addItemWithTitle:@"Zoom" 
             action:@selector(performZoom:) 
        keyEquivalent:@""];
  
  [submenu addItem:[NSMenuItem separatorItem]];
  
  [submenu addItemWithTitle:@"Bring All to Front" 
             action:@selector(arrangeInFront:) 
        keyEquivalent:@""];
  
  [mainMenu setSubmenu:submenu forItem:menuItem];
  [NSApp setWindowsMenu:submenu];
  
  // Help menu
  menuItem = [mainMenu addItemWithTitle:@"Help" action:nil keyEquivalent:@""];
  submenu = [[[NSMenu alloc] initWithTitle:@"Help"] autorelease];
  
  [submenu addItemWithTitle:@"ClaudeChat Help" 
             action:@selector(showHelp:) 
        keyEquivalent:@"?"];
  
  [mainMenu setSubmenu:submenu forItem:menuItem];

  [NSApp setMainMenu:mainMenu];
  SAFE_ARC_AUTORELEASE_POOL_POP();
}

- (void)showAbout:(id)sender {
  SAFE_ARC_AUTORELEASE_POOL_PUSH();
  NSAlert *alert = [[[NSAlert alloc] init] autorelease];
  [alert setMessageText:@"ClaudeChat"];
  [alert setInformativeText:@"A Mac OS X Tiger-compatible Claude AI chat client.\n\nVersion 1.0\n\nDesigned to work on Mac OS X 10.4 and later."];
  [alert addButtonWithTitle:@"OK"];
  [alert runModal];
  SAFE_ARC_AUTORELEASE_POOL_POP();
}

- (void)showPreferences:(id)sender {
  NSLog(@"showPreferences called");
  [self showPreferencesWindow];
}

- (void)newConversation:(id)sender {
  if (chatWindowController) {
    [chatWindowController clearConversation];
  }
}

- (void)showHelp:(id)sender {
  SAFE_ARC_AUTORELEASE_POOL_PUSH();
  NSAlert *alert = [[[NSAlert alloc] init] autorelease];
  [alert setMessageText:@"ClaudeChat Help"];
  [alert setInformativeText:@"To use ClaudeChat:\n\n1. Set your Claude API key in Preferences (Cmd+,)\n2. Type your message in the text field\n3. Press Enter or click Send\n4. Claude's response will appear in the chat\n\nKeyboard shortcuts:\n- Cmd+C: Copy\n- Cmd+V: Paste\n- Cmd+A: Select All\n- Cmd+N: New Conversation"];
  [alert addButtonWithTitle:@"OK"];
  [alert runModal];
  SAFE_ARC_AUTORELEASE_POOL_POP();
}

- (NSString *)selectedModel {
  return selectedModel;
}

- (void)setSelectedModel:(NSString *)model {
  if (selectedModel != model) {
    SAFE_ARC_RELEASE(selectedModel);
    selectedModel = SAFE_ARC_RETAIN(model);

    // Save to preferences
    [[NSUserDefaults standardUserDefaults] setObject:selectedModel forKey:@"ClaudeSelectedModel"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    // Update menu checkmarks
    [self updateModelMenuCheckmarks];

    // Update window title
    if (chatWindowController) {
      [chatWindowController updateWindowTitle];
    }
  }
}

- (void)addDefaultModelsToMenu {
  SAFE_ARC_AUTORELEASE_POOL_PUSH();
  // Clear existing items
  while ([modelsMenu numberOfItems] > 0) {
    [modelsMenu removeItemAtIndex:0];
  }

  // Clear our models map
  models = [[NSMutableDictionary alloc] init];
  
  // Add current Claude models
  NSArray *defaultModels = [NSArray arrayWithObjects:
    [NSDictionary dictionaryWithObjectsAndKeys:
      @"Claude Opus 4.1", 					@"name",
      @"claude-opus-4-1-20250805", 			@"id",
      @"Latest and most capable", 			@"description",
	  [NSNumber numberWithInt:32000],		@"max-tokens",
	  [NSNumber numberWithInt:200000],		@"context-window",
      nil],
    [NSDictionary dictionaryWithObjectsAndKeys:
      @"Claude Opus 4", 					@"name",
      @"claude-opus-4-20250514", 			@"id",
      @"Powerful reasoning model", 			@"description",
	  [NSNumber numberWithInt:32000],		@"max-tokens",
	  [NSNumber numberWithInt:200000],		@"context-window",
      nil],
	[NSDictionary dictionaryWithObjectsAndKeys:
	  @"Claude Sonnet 4.5", 				@"name",
	  @"claude-sonnet-4-5-20250929",		@"id",
	  @"Latest model", 						@"description",
	  [NSNumber numberWithInt:64000],		@"max-tokens",
	  [NSNumber numberWithInt:200000],		@"context-window",
	  nil],
    [NSDictionary dictionaryWithObjectsAndKeys:
      @"Claude Sonnet 4", 					@"name",
      @"claude-sonnet-4-20250514", 			@"id",
      @"Balanced performance", 				@"description",
	  [NSNumber numberWithInt:64000],		@"max-tokens",
	  [NSNumber numberWithInt:200000],		@"context-window",
      nil],
    [NSDictionary dictionaryWithObjectsAndKeys:
      @"Claude Sonnet 3.7", 				@"name",
      @"claude-3-7-sonnet-latest", 			@"id",
      @"Fast and intelligent", 				@"description",
	  [NSNumber numberWithInt:64000],		@"max-tokens",
	  [NSNumber numberWithInt:200000],		@"context-window",
      nil],
    [NSDictionary dictionaryWithObjectsAndKeys:
      @"Claude Haiku 3", 					@"name",
      @"claude-3-haiku-20240307", 			@"id",
      @"Quick responses", 					@"description",
	  [NSNumber numberWithInt:4096],		@"max-tokens",
	  [NSNumber numberWithInt:200000],		@"context-window",
      nil],
    nil];
  
  int i;
  for (i = 0; i < [defaultModels count]; i++) {	
    NSDictionary *model = [defaultModels objectAtIndex:i];
    NSString *title = [NSString stringWithFormat:@"%@ - %@", 
              [model objectForKey:@"name"],
              [model objectForKey:@"description"]];
    
    NSMenuItem *item = [modelsMenu addItemWithTitle:title
                         action:@selector(selectModel:)
                      keyEquivalent:@""];
    [item setRepresentedObject:model];
    [item setTarget:self];

	  // Prime our models map
  	[models setObject:model forKey:[model objectForKey:@"id"]];
    
    // Add keyboard shortcut for first 3 models
    if (i < 3) {
      [item setKeyEquivalent:[NSString stringWithFormat:@"%d", i + 1]];
      [item setKeyEquivalentModifierMask:NSCommandKeyMask | NSAlternateKeyMask];
    }
    
    // Check if this is the selected model
    if ([[model objectForKey:@"id"] isEqualToString:selectedModel]) {
      [item setState:NSOnState];
    }
  }

  [modelsMenu addItem:[NSMenuItem separatorItem]];

  SAFE_ARC_AUTORELEASE_POOL_POP();
}

- (void)selectModel:(id)sender {
  NSMenuItem *item = (NSMenuItem *)sender;
  NSString *modelId = [[item representedObject] objectForKey:@"id"];
  [self setSelectedModel:modelId];
}

- (void)updateModelMenuCheckmarks {
  int i;
  for (i = 0; i < [modelsMenu numberOfItems]; i++) {
    NSMenuItem *item = [modelsMenu itemAtIndex:i];
    if ([[item representedObject] objectForKey:@"id"]) {
      if ([[[item representedObject] objectForKey:@"id"] isEqualToString:selectedModel]) {
        [item setState:NSOnState];
      } else {
        [item setState:NSOffState];
      }
    }
  }
}

- (void)fetchAvailableModels {
  // Note: Claude API doesn't currently have a models endpoint
  // But we'll structure this for future compatibility
  
  if (!apiKey || [apiKey length] == 0) {
    return;
  }
  
  // For now, we'll just use the default models
  // In the future, this could make an API call to get available models
  
  // You could implement this with a call like:
  // GET https://api.anthropic.com/v1/models
  // But this endpoint doesn't exist yet in the Claude API
  
  // For demonstration, let's simulate updating the menu
  [self performSelector:@selector(updateModelsMenu) withObject:nil afterDelay:0.1];
}

- (void)updateModelsMenu {
  // This would be called after successfully fetching models from API
  // For now, it just ensures the default models are shown
  [self addDefaultModelsToMenu];
}

- (BOOL)isDarkMode {
  return isDarkMode;
}

- (int)fontSizeAdjustment {
  return fontSizeAdjustment;
}

- (void)setLightTheme:(id)sender {
  isDarkMode = NO;
  [[NSUserDefaults standardUserDefaults] setBool:isDarkMode forKey:@"ClaudeChatDarkMode"];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  [self updateThemeMenus];
  if (chatWindowController) {
    [chatWindowController updateTheme];
  }
}

- (void)setDarkTheme:(id)sender {
  isDarkMode = YES;
  [[NSUserDefaults standardUserDefaults] setBool:isDarkMode forKey:@"ClaudeChatDarkMode"];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  [self updateThemeMenus];
  if (chatWindowController) {
    [chatWindowController updateTheme];
  }
}

- (void)updateThemeMenus {
  NSMenu *mainMenu = [NSApp mainMenu];
  NSMenuItem *viewItem = [mainMenu itemWithTitle:@"View"];
  if (viewItem) {
    NSMenu *viewMenu = [viewItem submenu];
    NSMenuItem *themeItem = [viewMenu itemWithTitle:@"Theme"];
    if (themeItem) {
      NSMenu *themeMenu = [themeItem submenu];
      [[themeMenu itemWithTitle:@"Light Mode"] setState:isDarkMode ? NSOffState : NSOnState];
      [[themeMenu itemWithTitle:@"Dark Mode"] setState:isDarkMode ? NSOnState : NSOffState];
    }
  }
}

- (void)increaseFontSize:(id)sender {
  if (fontSizeAdjustment < 10) {  // Max +10pt
    fontSizeAdjustment += 2;
    [[NSUserDefaults standardUserDefaults] setInteger:fontSizeAdjustment forKey:@"ClaudeChatFontSizeAdjustment"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if (chatWindowController) {
      [chatWindowController updateFontSize];
    }
  }
}

- (void)decreaseFontSize:(id)sender {
  if (fontSizeAdjustment > -6) {  // Min -6pt
    fontSizeAdjustment -= 2;
    [[NSUserDefaults standardUserDefaults] setInteger:fontSizeAdjustment forKey:@"ClaudeChatFontSizeAdjustment"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if (chatWindowController) {
      [chatWindowController updateFontSize];
    }
  }
}

- (void)resetFontSize:(id)sender {
  fontSizeAdjustment = 0;
  [[NSUserDefaults standardUserDefaults] setInteger:fontSizeAdjustment forKey:@"ClaudeChatFontSizeAdjustment"];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  if (chatWindowController) {
    [chatWindowController updateFontSize];
  }
}

- (NSDictionary*)modelMap {
  return models;
}

- (NSString *)monospaceFontName {
  return monospaceFontName;
}

- (NSString *)proportionalFontName {
  return proportionalFontName;
}

- (float)monospaceFontSize {
  return monospaceFontSize + fontSizeAdjustment;
}

- (float)proportionalFontSize {
  return proportionalFontSize + fontSizeAdjustment;
}

- (void)selectProportionalFont:(id)sender {
  NSFontPanel *fontPanel = [NSFontPanel sharedFontPanel];
  NSFont *currentFont = [NSFont fontWithName:proportionalFontName size:proportionalFontSize];
  if (!currentFont) currentFont = [NSFont systemFontOfSize:proportionalFontSize];
  
  [fontPanel setPanelFont:currentFont isMultiple:NO];
  // Note: setTarget and setAction are not available on NSFontPanel in older macOS
  // We'll use NSFontManager instead
  [[NSFontManager sharedFontManager] setTarget:self];
  [[NSFontManager sharedFontManager] setAction:@selector(changeProportionalFont:)];
  [fontPanel makeKeyAndOrderFront:nil];
}

- (void)selectMonospaceFont:(id)sender {
  NSFontPanel *fontPanel = [NSFontPanel sharedFontPanel];
  NSFont *currentFont = [NSFont fontWithName:monospaceFontName size:monospaceFontSize];
  if (!currentFont) currentFont = [NSFont userFixedPitchFontOfSize:monospaceFontSize];
  
  [fontPanel setPanelFont:currentFont isMultiple:NO];
  // Note: setTarget and setAction are not available on NSFontPanel in older macOS
  // We'll use NSFontManager instead
  [[NSFontManager sharedFontManager] setTarget:self];
  [[NSFontManager sharedFontManager] setAction:@selector(changeMonospaceFont:)];
  [fontPanel makeKeyAndOrderFront:nil];
}

- (void)changeProportionalFont:(id)sender {
  // Get the current font and convert it
  NSFont *currentFont = [NSFont fontWithName:proportionalFontName size:proportionalFontSize];
  if (!currentFont) currentFont = [NSFont systemFontOfSize:proportionalFontSize];
  NSFont *newFont = [[NSFontManager sharedFontManager] convertFont:currentFont];
  if (newFont) {
    SAFE_ARC_RELEASE(proportionalFontName);
    proportionalFontName = SAFE_ARC_RETAIN([newFont fontName]);
    proportionalFontSize = [newFont pointSize];
    
    // Update display field in preferences window
    NSTextField *display = (NSTextField *)[[preferencesWindow contentView] viewWithTag:301];
    if (display) {
      [display setStringValue:[NSString stringWithFormat:@"%@ %.0fpt", [newFont displayName], [newFont pointSize]]];
    }
    
    [self updateFontPreview];
  }
}

- (void)changeMonospaceFont:(id)sender {
  // Get the current font and convert it
  NSFont *currentFont = [NSFont fontWithName:monospaceFontName size:monospaceFontSize];
  if (!currentFont) currentFont = [NSFont userFixedPitchFontOfSize:monospaceFontSize];
  NSFont *newFont = [[NSFontManager sharedFontManager] convertFont:currentFont];
  if (newFont) {
    SAFE_ARC_RELEASE(monospaceFontName);
    monospaceFontName = SAFE_ARC_RETAIN([newFont fontName]);
    monospaceFontSize = [newFont pointSize];
    
    // Update display field in preferences window
    NSTextField *display = (NSTextField *)[[preferencesWindow contentView] viewWithTag:303];
    if (display) {
      [display setStringValue:[NSString stringWithFormat:@"%@ %.0fpt", [newFont displayName], [newFont pointSize]]];
    }
    
    [self updateFontPreview];
  }
}

- (void)updateFontPreview {
  // For now, skip preview updates since we can't use tags on NSTextView
  // TODO: Store reference to preview text view
  return;
}

- (void)cancelPreferences:(id)sender {
  [preferencesWindow close];
  // Don't set to nil here - let windowWillClose handle it
}

- (void)applySimplePreferences:(id)sender {
  NSTextField *apiField = (NSTextField *)[[preferencesWindow contentView] viewWithTag:200];
  if (apiField) {
    NSString *newKey = [apiField stringValue];
    if (newKey && [newKey length] > 0) {
      [self setApiKey:newKey];
    }
  }
  [preferencesWindow close];
  // Don't set to nil here - let windowWillClose handle it
}

- (void)applyPreferences:(id)sender {
  // Save API key
  NSTextField *apiField = (NSTextField *)[[preferencesWindow contentView] viewWithTag:200];
  if (apiField) {
    NSString *newKey = [apiField stringValue];
    if (newKey && [newKey length] > 0) {
      [self setApiKey:newKey];
    }
  }
  
  // Save font preferences
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:proportionalFontName forKey:@"ClaudeChatProportionalFontName"];
  [defaults setFloat:proportionalFontSize forKey:@"ClaudeChatProportionalFontSize"];
  [defaults setObject:monospaceFontName forKey:@"ClaudeChatMonospaceFontName"];
  [defaults setFloat:monospaceFontSize forKey:@"ClaudeChatMonospaceFontSize"];
  [defaults synchronize];
  
  // Notify chat window to update
  if (chatWindowController) {
    [chatWindowController updateTheme];
    [chatWindowController updateFontSize];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FontPreferencesChanged" object:nil];
  }
  
  [preferencesWindow close];
  // Don't set to nil here - let windowWillClose handle it
}

- (void)windowWillClose:(NSNotification *)notification {
  if ([notification object] == preferencesWindow) {
    preferencesWindow = nil;
  }
}

- (void)showFontPreferences:(id)sender {
  // Redirect to unified preferences
  [self showPreferencesWindow];
}

@end

//
//  AppDelegate.m
//  ClaudeChat
//

#import "AppDelegate.h"
#import "ChatWindowController.h"

@implementation AppDelegate

- (void)dealloc {
    [chatWindowController release];
    [apiKey release];
    [selectedModel release];
    [availableModels release];
    [monospaceFontName release];
    [proportionalFontName release];
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    // Initialize models array
    availableModels = [[NSMutableArray alloc] init];
    
    // Set up menus
    [self setupMenus];
    
    // Load preferences
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    apiKey = [[defaults stringForKey:@"ClaudeAPIKey"] retain];
    selectedModel = [[defaults stringForKey:@"ClaudeSelectedModel"] retain];
    isDarkMode = [defaults boolForKey:@"ClaudeChatDarkMode"];
    fontSizeAdjustment = [defaults integerForKey:@"ClaudeChatFontSizeAdjustment"];
    
    // Load font preferences
    monospaceFontName = [[defaults stringForKey:@"ClaudeChatMonospaceFontName"] retain];
    proportionalFontName = [[defaults stringForKey:@"ClaudeChatProportionalFontName"] retain];
    monospaceFontSize = [defaults floatForKey:@"ClaudeChatMonospaceFontSize"];
    proportionalFontSize = [defaults floatForKey:@"ClaudeChatProportionalFontSize"];
    
    // Set default fonts if not configured
    if (!monospaceFontName || [monospaceFontName length] == 0) {
        monospaceFontName = [@"Monaco" retain];
        monospaceFontSize = 11.0;
    }
    if (!proportionalFontName || [proportionalFontName length] == 0) {
        proportionalFontName = [@"Lucida Grande" retain];
        proportionalFontSize = 13.0;
    }
    if (monospaceFontSize == 0) monospaceFontSize = 11.0;
    if (proportionalFontSize == 0) proportionalFontSize = 13.0;
    
    // Default to Claude Haiku 3 if no model selected
    if (!selectedModel || [selectedModel length] == 0) {
        selectedModel = [@"claude-3-haiku-20240307" retain];
    }
    
    // Create and show main window
    chatWindowController = [[ChatWindowController alloc] init];
    [chatWindowController showWindow:self];
    
    // Check for API key
    if (!apiKey || [apiKey length] == 0) {
        [self showAPIKeyDialog];
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
        [apiKey release];
        apiKey = [key retain];
        
        // Save to preferences
        [[NSUserDefaults standardUserDefaults] setObject:apiKey forKey:@"ClaudeAPIKey"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)showAPIKeyDialog {
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"API Key Required"];
    [alert setInformativeText:@"Please enter your Claude API key:"];
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    
    NSTextField *input = [[[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 300, 24)] autorelease];
    [input setStringValue:apiKey ? apiKey : @""];
    [alert setAccessoryView:input];
    
    NSInteger button = [alert runModal];
    if (button == NSAlertFirstButtonReturn) {
        [self setApiKey:[input stringValue]];
    }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

- (void)setupMenus {
    // Clear any existing menu first to prevent duplication
    [NSApp setMainMenu:nil];
    
    NSMenu *mainMenu = [[[NSMenu alloc] init] autorelease];
    NSMenuItem *menuItem;
    NSMenu *submenu;
    
    // Application menu
    menuItem = [mainMenu addItemWithTitle:@"" action:nil keyEquivalent:@""];
    submenu = [[[NSMenu alloc] initWithTitle:@"ClaudeChat"] autorelease];
    
    [submenu addItemWithTitle:@"About ClaudeChat" 
                       action:@selector(showAbout:) 
                keyEquivalent:@""];
    
    [submenu addItem:[NSMenuItem separatorItem]];
    
    [submenu addItemWithTitle:@"Preferences..." 
                       action:@selector(showPreferences:) 
                keyEquivalent:@","];
    
    [submenu addItemWithTitle:@"Font Preferences..." 
                       action:@selector(showFontPreferences:) 
                keyEquivalent:@""];
    
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
}

- (void)showAbout:(id)sender {
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"ClaudeChat"];
    [alert setInformativeText:@"A Mac OS X Tiger-compatible Claude AI chat client.\n\nVersion 1.0\n\nDesigned to work on Mac OS X 10.4 and later."];
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

- (void)showPreferences:(id)sender {
    [self showAPIKeyDialog];
}

- (void)newConversation:(id)sender {
    if (chatWindowController) {
        [chatWindowController clearConversation];
    }
}

- (void)showHelp:(id)sender {
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"ClaudeChat Help"];
    [alert setInformativeText:@"To use ClaudeChat:\n\n1. Set your Claude API key in Preferences (Cmd+,)\n2. Type your message in the text field\n3. Press Enter or click Send\n4. Claude's response will appear in the chat\n\nKeyboard shortcuts:\n- Cmd+C: Copy\n- Cmd+V: Paste\n- Cmd+A: Select All\n- Cmd+N: New Conversation"];
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

- (NSString *)selectedModel {
    return selectedModel;
}

- (void)setSelectedModel:(NSString *)model {
    if (selectedModel != model) {
        [selectedModel release];
        selectedModel = [model retain];
        
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
    // Clear existing items
    while ([modelsMenu numberOfItems] > 0) {
        [modelsMenu removeItemAtIndex:0];
    }
    
    // Add current Claude models
    NSArray *defaultModels = [NSArray arrayWithObjects:
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"Claude Opus 4.1", @"name",
            @"claude-opus-4-1-20250805", @"id",
            @"Latest and most capable", @"description",
            nil],
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"Claude Opus 4", @"name",
            @"claude-opus-4-20250514", @"id",
            @"Powerful reasoning model", @"description",
            nil],
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"Claude Sonnet 4", @"name",
            @"claude-sonnet-4-20250514", @"id",
            @"Balanced performance", @"description",
            nil],
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"Claude Sonnet 3.7", @"name",
            @"claude-3-7-sonnet-latest", @"id",
            @"Fast and intelligent", @"description",
            nil],
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"Claude Haiku 3", @"name",
            @"claude-3-haiku-20240307", @"id",
            @"Quick responses", @"description",
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
        [item setRepresentedObject:[model objectForKey:@"id"]];
        [item setTarget:self];
        
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
    
    // Add separator and refresh option
    [modelsMenu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem *refreshItem = [modelsMenu addItemWithTitle:@"Refresh Model List"
                                                     action:@selector(fetchAvailableModels)
                                              keyEquivalent:@""];
    [refreshItem setTarget:self];
}

- (void)selectModel:(id)sender {
    NSMenuItem *item = (NSMenuItem *)sender;
    NSString *modelId = [item representedObject];
    [self setSelectedModel:modelId];
}

- (void)updateModelMenuCheckmarks {
    int i;
    for (i = 0; i < [modelsMenu numberOfItems]; i++) {
        NSMenuItem *item = [modelsMenu itemAtIndex:i];
        if ([item representedObject]) {
            if ([[item representedObject] isEqualToString:selectedModel]) {
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

- (void)showFontPreferences:(id)sender {
    NSWindow *prefWindow = [[[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 400, 300)
                                                         styleMask:NSTitledWindowMask | NSClosableWindowMask
                                                           backing:NSBackingStoreBuffered
                                                             defer:YES] autorelease];
    [prefWindow setTitle:@"Font Preferences"];
    [prefWindow center];
    
    NSView *contentView = [prefWindow contentView];
    
    // Monospace font settings
    NSTextField *monoLabel = [[[NSTextField alloc] initWithFrame:NSMakeRect(20, 250, 150, 20)] autorelease];
    [monoLabel setStringValue:@"Monospace Font:"];
    [monoLabel setBezeled:NO];
    [monoLabel setDrawsBackground:NO];
    [monoLabel setEditable:NO];
    [monoLabel setSelectable:NO];
    [contentView addSubview:monoLabel];
    
    NSTextField *monoField = [[[NSTextField alloc] initWithFrame:NSMakeRect(180, 250, 150, 22)] autorelease];
    [monoField setStringValue:monospaceFontName];
    [monoField setTag:100];
    [contentView addSubview:monoField];
    
    NSTextField *monoSizeField = [[[NSTextField alloc] initWithFrame:NSMakeRect(340, 250, 40, 22)] autorelease];
    [monoSizeField setFloatValue:monospaceFontSize];
    [monoSizeField setTag:101];
    [contentView addSubview:monoSizeField];
    
    // Proportional font settings
    NSTextField *propLabel = [[[NSTextField alloc] initWithFrame:NSMakeRect(20, 210, 150, 20)] autorelease];
    [propLabel setStringValue:@"Proportional Font:"];
    [propLabel setBezeled:NO];
    [propLabel setDrawsBackground:NO];
    [propLabel setEditable:NO];
    [propLabel setSelectable:NO];
    [contentView addSubview:propLabel];
    
    NSTextField *propField = [[[NSTextField alloc] initWithFrame:NSMakeRect(180, 210, 150, 22)] autorelease];
    [propField setStringValue:proportionalFontName];
    [propField setTag:102];
    [contentView addSubview:propField];
    
    NSTextField *propSizeField = [[[NSTextField alloc] initWithFrame:NSMakeRect(340, 210, 40, 22)] autorelease];
    [propSizeField setFloatValue:proportionalFontSize];
    [propSizeField setTag:103];
    [contentView addSubview:propSizeField];
    
    // Sample text
    NSTextField *sampleLabel = [[[NSTextField alloc] initWithFrame:NSMakeRect(20, 170, 360, 20)] autorelease];
    [sampleLabel setStringValue:@"Sample Text:"];
    [sampleLabel setBezeled:NO];
    [sampleLabel setDrawsBackground:NO];
    [sampleLabel setEditable:NO];
    [sampleLabel setSelectable:NO];
    [contentView addSubview:sampleLabel];
    
    NSScrollView *sampleScrollView = [[[NSScrollView alloc] initWithFrame:NSMakeRect(20, 50, 360, 110)] autorelease];
    [sampleScrollView setBorderType:NSBezelBorder];
    [sampleScrollView setHasVerticalScroller:YES];
    [sampleScrollView setHasHorizontalScroller:NO];
    
    NSTextView *sampleText = [[[NSTextView alloc] initWithFrame:[[sampleScrollView contentView] frame]] autorelease];
    [sampleText setString:@"Regular text in proportional font.\n**Bold text** and *italic text*.\n`Code in monospace font`\n```\nCode block\nin monospace\n```"];
    [sampleText setEditable:NO];
    [[sampleText textContainer] setWidthTracksTextView:YES];
    [sampleScrollView setDocumentView:sampleText];
    [contentView addSubview:sampleScrollView];
    
    // Buttons
    NSButton *cancelButton = [[[NSButton alloc] initWithFrame:NSMakeRect(220, 10, 80, 25)] autorelease];
    [cancelButton setTitle:@"Cancel"];
    [cancelButton setBezelStyle:NSRoundedBezelStyle];
    [cancelButton setTarget:self];
    [cancelButton setAction:@selector(cancelFontPreferences:)];
    [cancelButton setTag:1001];
    [contentView addSubview:cancelButton];
    
    NSButton *applyButton = [[[NSButton alloc] initWithFrame:NSMakeRect(310, 10, 80, 25)] autorelease];
    [applyButton setTitle:@"Apply"];
    [applyButton setBezelStyle:NSRoundedBezelStyle];
    [applyButton setTarget:self];
    [applyButton setAction:@selector(applyFontPreferences:)];
    [applyButton setTag:1000];
    [applyButton setKeyEquivalent:@"\r"];
    [contentView addSubview:applyButton];
    
    // Store reference to sample text view for updates
    [prefWindow setReleasedWhenClosed:YES];
    [prefWindow makeKeyAndOrderFront:nil];
    
    // Update sample text with current fonts
    [self updateFontPreferenceSample:sampleText];
}

- (void)updateFontPreferenceSample:(NSTextView *)sampleText {
    NSMutableAttributedString *sample = [[NSMutableAttributedString alloc] init];
    
    NSFont *propFont = [NSFont fontWithName:proportionalFontName size:proportionalFontSize];
    if (!propFont) propFont = [NSFont systemFontOfSize:proportionalFontSize];
    
    NSFont *monoFont = [NSFont fontWithName:monospaceFontName size:monospaceFontSize];
    if (!monoFont) monoFont = [NSFont userFixedPitchFontOfSize:monospaceFontSize];
    
    [sample appendAttributedString:[[[NSAttributedString alloc] initWithString:@"Regular text in proportional font.\n" 
                                                                     attributes:[NSDictionary dictionaryWithObject:propFont forKey:NSFontAttributeName]] autorelease]];
    
    NSFont *boldFont = [[NSFontManager sharedFontManager] convertFont:propFont toHaveTrait:NSBoldFontMask];
    [sample appendAttributedString:[[[NSAttributedString alloc] initWithString:@"Bold text" 
                                                                     attributes:[NSDictionary dictionaryWithObject:boldFont forKey:NSFontAttributeName]] autorelease]];
    
    [sample appendAttributedString:[[[NSAttributedString alloc] initWithString:@" and " 
                                                                     attributes:[NSDictionary dictionaryWithObject:propFont forKey:NSFontAttributeName]] autorelease]];
    
    NSFont *italicFont = [[NSFontManager sharedFontManager] convertFont:propFont toHaveTrait:NSItalicFontMask];
    [sample appendAttributedString:[[[NSAttributedString alloc] initWithString:@"italic text" 
                                                                     attributes:[NSDictionary dictionaryWithObject:italicFont forKey:NSFontAttributeName]] autorelease]];
    
    [sample appendAttributedString:[[[NSAttributedString alloc] initWithString:@".\n" 
                                                                     attributes:[NSDictionary dictionaryWithObject:propFont forKey:NSFontAttributeName]] autorelease]];
    
    [sample appendAttributedString:[[[NSAttributedString alloc] initWithString:@"Code in monospace font\n" 
                                                                     attributes:[NSDictionary dictionaryWithObject:monoFont forKey:NSFontAttributeName]] autorelease]];
    
    [sample appendAttributedString:[[[NSAttributedString alloc] initWithString:@"Code block\nin monospace\n" 
                                                                     attributes:[NSDictionary dictionaryWithObject:monoFont forKey:NSFontAttributeName]] autorelease]];
    
    [[sampleText textStorage] setAttributedString:sample];
    [sample release];
}

- (void)cancelFontPreferences:(id)sender {
    [[sender window] close];
}

- (void)applyFontPreferences:(id)sender {
    NSWindow *window = [sender window];
    
    NSTextField *monoField = (NSTextField *)[[window contentView] viewWithTag:100];
    NSTextField *monoSizeField = (NSTextField *)[[window contentView] viewWithTag:101];
    NSTextField *propField = (NSTextField *)[[window contentView] viewWithTag:102];
    NSTextField *propSizeField = (NSTextField *)[[window contentView] viewWithTag:103];
    
    // Update font settings
    [monospaceFontName release];
    monospaceFontName = [[monoField stringValue] retain];
    monospaceFontSize = [monoSizeField floatValue];
    
    [proportionalFontName release];
    proportionalFontName = [[propField stringValue] retain];
    proportionalFontSize = [propSizeField floatValue];
    
    // Save to preferences
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:monospaceFontName forKey:@"ClaudeChatMonospaceFontName"];
    [defaults setFloat:monospaceFontSize forKey:@"ClaudeChatMonospaceFontSize"];
    [defaults setObject:proportionalFontName forKey:@"ClaudeChatProportionalFontName"];
    [defaults setFloat:proportionalFontSize forKey:@"ClaudeChatProportionalFontSize"];
    [defaults synchronize];
    
    // Notify chat window to refresh
    if (chatWindowController) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"FontPreferencesChanged" object:nil];
    }
    
    [window close];
}

@end
//
//  AppDelegate.h
//  ClaudeChat
//
//  A Mac OS X Tiger-compatible Claude chat client
//

#import <Cocoa/Cocoa.h>

@class ChatWindowController;

@interface AppDelegate : NSObject {
    ChatWindowController *chatWindowController;
    NSString *apiKey;
    NSString *selectedModel;
    NSMenu *modelsMenu;
    NSMutableArray *availableModels;
    BOOL isDarkMode;
    int fontSizeAdjustment;
    NSString *monospaceFontName;
    NSString *proportionalFontName;
    float monospaceFontSize;
    float proportionalFontSize;
    NSWindow *preferencesWindow;
    NSFontManager *fontManager;
	  NSMutableDictionary *models;
}

- (BOOL)isDarkMode;
- (float)monospaceFontSize;
- (float)proportionalFontSize;
- (int)fontSizeAdjustment;

- (NSDictionary*)modelMap;
- (NSString *)apiKey;
- (NSString *)monospaceFontName;
- (NSString *)proportionalFontName;
- (NSString *)selectedModel;

- (void)addDefaultModelsToMenu;
- (void)applicationDidFinishLaunching:(NSNotification *)notification;
- (void)applicationWillTerminate:(NSNotification *)notification;
- (void)decreaseFontSize:(id)sender;
- (void)fetchAvailableModels;
- (void)increaseFontSize:(id)sender;
- (void)resetFontSize:(id)sender;
- (void)selectModel:(id)sender;
- (void)setApiKey:(NSString *)key;
- (void)setSelectedModel:(NSString *)model;
- (void)setupMenus;
- (void)showFontPreferences:(id)sender;
- (void)showPreferencesWindow;
- (void)updateFontPreview;
- (void)updateModelMenuCheckmarks;
- (void)updateThemeMenus;

@end
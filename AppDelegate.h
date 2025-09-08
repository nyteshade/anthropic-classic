//
//  AppDelegate.h
//  ClaudeChat
//
//  A Mac OS X Tiger-compatible Claude chat client
//

#import <Cocoa/Cocoa.h>

@class ChatWindowController;

@interface AppDelegate : NSObject <NSApplicationDelegate> {
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
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification;
- (void)applicationWillTerminate:(NSNotification *)notification;
- (NSString *)apiKey;
- (void)setApiKey:(NSString *)key;
- (NSString *)selectedModel;
- (void)setSelectedModel:(NSString *)model;
- (void)fetchAvailableModels;
- (void)selectModel:(id)sender;
- (BOOL)isDarkMode;
- (int)fontSizeAdjustment;
- (void)increaseFontSize:(id)sender;
- (void)decreaseFontSize:(id)sender;
- (void)resetFontSize:(id)sender;
- (NSString *)monospaceFontName;
- (NSString *)proportionalFontName;
- (float)monospaceFontSize;
- (float)proportionalFontSize;
- (void)showFontPreferences:(id)sender;

@end
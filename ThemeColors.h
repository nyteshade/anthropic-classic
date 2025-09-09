//
//  ThemeColors.h
//  ClaudeChat
//
//  Apple semantic colors for light/dark themes
//  Based on macOS Human Interface Guidelines
//

#import <Cocoa/Cocoa.h>

@interface ThemeColors : NSObject

// Text colors
+ (NSColor *)labelColorForDarkMode:(BOOL)isDark;
+ (NSColor *)secondaryLabelColorForDarkMode:(BOOL)isDark;
+ (NSColor *)tertiaryLabelColorForDarkMode:(BOOL)isDark;
+ (NSColor *)quaternaryLabelColorForDarkMode:(BOOL)isDark;

// Background colors
+ (NSColor *)textBackgroundColorForDarkMode:(BOOL)isDark;
+ (NSColor *)windowBackgroundColorForDarkMode:(BOOL)isDark;
+ (NSColor *)controlBackgroundColorForDarkMode:(BOOL)isDark;
+ (NSColor *)alternatingRowColorForDarkMode:(BOOL)isDark;

// Accent colors
+ (NSColor *)linkColorForDarkMode:(BOOL)isDark;
+ (NSColor *)systemBlueForDarkMode:(BOOL)isDark;
+ (NSColor *)systemPurpleForDarkMode:(BOOL)isDark;
+ (NSColor *)systemGreenForDarkMode:(BOOL)isDark;
+ (NSColor *)systemRedForDarkMode:(BOOL)isDark;

// Code colors
+ (NSColor *)codeColorForDarkMode:(BOOL)isDark;
+ (NSColor *)codeBackgroundColorForDarkMode:(BOOL)isDark;

// Chat-specific colors
+ (NSColor *)userTextColorForDarkMode:(BOOL)isDark;
+ (NSColor *)claudeTextColorForDarkMode:(BOOL)isDark;

@end
//
//  ThemeColors.m
//  ClaudeChat
//
//  Apple semantic colors hardcoded for Tiger compatibility
//
//  Modern semantic colors are preferred on macOS 11+ using compile-time and runtime checks,
//  while maintaining compatibility with non-ARC and older macOS versions.
//

#import "ThemeColors.h"

@implementation ThemeColors

// MARK: - Text Colors (based on macOS semantic colors)

+ (NSColor *)labelColorForDarkMode:(BOOL)isDark {
#if defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 110000
    // Modern semantic color branch (macOS 11+)
    if (@available(macOS 11.0, *)) {
        NSColor *c = NSColor.labelColor;
        if (c)
            return c;
    }
#endif
    if (isDark) {
        // ~85% white
        return [NSColor colorWithCalibratedWhite:0.85 alpha:1.0];
    } else {
        // Pure black
        return [NSColor colorWithCalibratedWhite:0.0 alpha:1.0];
    }
}

+ (NSColor *)secondaryLabelColorForDarkMode:(BOOL)isDark {
#if defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 110000
    // Modern semantic color branch (macOS 11+)
    if (@available(macOS 11.0, *)) {
        NSColor *c = NSColor.secondaryLabelColor;
        if (c)
            return c;
    }
#endif
    if (isDark) {
        // ~55% white
        return [NSColor colorWithCalibratedWhite:0.55 alpha:1.0];
    } else {
        // ~50% black
        return [NSColor colorWithCalibratedWhite:0.5 alpha:1.0];
    }
}

+ (NSColor *)tertiaryLabelColorForDarkMode:(BOOL)isDark {
#if defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 110000
    // Modern semantic color branch (macOS 11+)
    if (@available(macOS 11.0, *)) {
        NSColor *c = NSColor.tertiaryLabelColor;
        if (c)
            return c;
    }
#endif
    if (isDark) {
        // ~35% white
        return [NSColor colorWithCalibratedWhite:0.35 alpha:1.0];
    } else {
        // ~66% black
        return [NSColor colorWithCalibratedWhite:0.66 alpha:1.0];
    }
}

+ (NSColor *)quaternaryLabelColorForDarkMode:(BOOL)isDark {
#if defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 110000
    // Modern semantic color branch (macOS 11+)
    if (@available(macOS 11.0, *)) {
        NSColor *c = NSColor.quaternaryLabelColor;
        if (c)
            return c;
    }
#endif
    if (isDark) {
        // ~25% white
        return [NSColor colorWithCalibratedWhite:0.25 alpha:1.0];
    } else {
        // ~75% black
        return [NSColor colorWithCalibratedWhite:0.75 alpha:1.0];
    }
}

// MARK: - Background Colors

+ (NSColor *)textBackgroundColorForDarkMode:(BOOL)isDark {
#if defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 110000
    // Modern semantic color branch (macOS 11+)
    if (@available(macOS 11.0, *)) {
        NSColor *c = NSColor.textBackgroundColor;
        if (c)
            return c;
    }
#endif
    if (isDark) {
        // Dark gray background
        return [NSColor colorWithCalibratedRed:0.118 green:0.118 blue:0.118 alpha:1.0];
    } else {
        // Pure white
        return [NSColor colorWithCalibratedWhite:1.0 alpha:1.0];
    }
}

+ (NSColor *)windowBackgroundColorForDarkMode:(BOOL)isDark {
#if defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 110000
    // Modern semantic color branch (macOS 11+)
    if (@available(macOS 11.0, *)) {
        NSColor *c = NSColor.windowBackgroundColor;
        if (c)
            return c;
    }
#endif
    if (isDark) {
        // Slightly lighter than text background
        return [NSColor colorWithCalibratedRed:0.149 green:0.149 blue:0.149 alpha:1.0];
    } else {
        // Very light gray
        return [NSColor colorWithCalibratedWhite:0.95 alpha:1.0];
    }
}

+ (NSColor *)controlBackgroundColorForDarkMode:(BOOL)isDark {
#if defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 110000
    // Modern semantic color branch (macOS 11+)
    if (@available(macOS 11.0, *)) {
        NSColor *c = NSColor.controlBackgroundColor;
        if (c)
            return c;
    }
#endif
    if (isDark) {
        // Medium dark gray
        return [NSColor colorWithCalibratedRed:0.25 green:0.25 blue:0.25 alpha:1.0];
    } else {
        // White
        return [NSColor colorWithCalibratedWhite:1.0 alpha:1.0];
    }
}

+ (NSColor *)alternatingRowColorForDarkMode:(BOOL)isDark {
#if defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 110000
    // Modern semantic color branch (macOS 11+)
    if (@available(macOS 11.0, *)) {
        NSArray<NSColor *> *colors = [NSColor alternatingContentBackgroundColors];
        if (colors.count > 0) {
            NSColor *c = [colors objectAtIndex:0];
            if (c)
                return c;
        }
    }
#endif
    if (isDark) {
        // Slightly lighter than window background for subtle contrast
        return [NSColor colorWithCalibratedRed:0.17 green:0.17 blue:0.17 alpha:1.0];
    } else {
        // Very light blue-gray, typical macOS alternating row color
        return [NSColor colorWithCalibratedRed:0.96 green:0.97 blue:0.98 alpha:1.0];
    }
}

// MARK: - System Colors

+ (NSColor *)systemBlueForDarkMode:(BOOL)isDark {
#if defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 110000
    // Modern semantic color branch (macOS 11+)
    if (@available(macOS 11.0, *)) {
        NSColor *c = NSColor.systemBlueColor;
        if (c)
            return c;
    }
#endif
    if (isDark) {
        // Brighter blue for dark mode
        return [NSColor colorWithCalibratedRed:0.039 green:0.518 blue:1.0 alpha:1.0];
    } else {
        // Standard system blue
        return [NSColor colorWithCalibratedRed:0.0 green:0.478 blue:1.0 alpha:1.0];
    }
}

+ (NSColor *)systemPurpleForDarkMode:(BOOL)isDark {
#if defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 110000
    // Modern semantic color branch (macOS 11+)
    if (@available(macOS 11.0, *)) {
        NSColor *c = NSColor.systemPurpleColor;
        if (c)
            return c;
    }
#endif
    if (isDark) {
        // Brighter purple for dark mode
        return [NSColor colorWithCalibratedRed:0.75 green:0.35 blue:0.95 alpha:1.0];
    } else {
        // Standard system purple
        return [NSColor colorWithCalibratedRed:0.686 green:0.322 blue:0.871 alpha:1.0];
    }
}

+ (NSColor *)systemGreenForDarkMode:(BOOL)isDark {
#if defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 110000
    // Modern semantic color branch (macOS 11+)
    if (@available(macOS 11.0, *)) {
        NSColor *c = NSColor.systemGreenColor;
        if (c)
            return c;
    }
#endif
    if (isDark) {
        // Brighter green for dark mode
        return [NSColor colorWithCalibratedRed:0.196 green:0.843 blue:0.294 alpha:1.0];
    } else {
        // Standard system green
        return [NSColor colorWithCalibratedRed:0.161 green:0.682 blue:0.208 alpha:1.0];
    }
}

+ (NSColor *)systemRedForDarkMode:(BOOL)isDark {
#if defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 110000
    // Modern semantic color branch (macOS 11+)
    if (@available(macOS 11.0, *)) {
        NSColor *c = NSColor.systemRedColor;
        if (c)
            return c;
    }
#endif
    if (isDark) {
        // Brighter red for dark mode
        return [NSColor colorWithCalibratedRed:1.0 green:0.271 blue:0.227 alpha:1.0];
    } else {
        // Standard system red
        return [NSColor colorWithCalibratedRed:0.863 green:0.196 blue:0.184 alpha:1.0];
    }
}

+ (NSColor *)linkColorForDarkMode:(BOOL)isDark {
#if defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 110000
    // Modern semantic color branch (macOS 11+)
    if (@available(macOS 11.0, *)) {
        NSColor *c = NSColor.linkColor;
        if (c)
            return c;
    }
#endif
    return [self systemBlueForDarkMode:isDark];
}

// MARK: - Code Colors

+ (NSColor *)codeColorForDarkMode:(BOOL)isDark {
    if (isDark) {
        // Mint/cyan for dark mode
        return [NSColor colorWithCalibratedRed:0.4 green:0.9 blue:0.8 alpha:1.0];
    } else {
        // Dark green for light mode
        return [NSColor colorWithCalibratedRed:0.0 green:0.5 blue:0.25 alpha:1.0];
    }
}

+ (NSColor *)codeBackgroundColorForDarkMode:(BOOL)isDark {
    if (isDark) {
        // Very dark gray
        return [NSColor colorWithCalibratedRed:0.08 green:0.08 blue:0.08 alpha:1.0];
    } else {
        // Very light gray
        return [NSColor colorWithCalibratedWhite:0.96 alpha:1.0];
    }
}

+ (NSColor *)userTextColorForDarkMode:(BOOL)isDark {
    return [self systemBlueForDarkMode:isDark];
}

+ (NSColor *)claudeTextColorForDarkMode:(BOOL)isDark {
    return [self systemPurpleForDarkMode:isDark];
}

@end

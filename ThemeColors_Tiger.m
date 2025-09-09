//
//  ThemeColors_Tiger.m
//  ClaudeChat
//
//  Tiger/Leopard-specific implementation using default Aqua colors
//

#import "ThemeColors.h"

@implementation ThemeColors

// MARK: - Text Colors (use system defaults on Tiger/Leopard)

+ (NSColor *)labelColorForDarkMode:(BOOL)isDark {
    if (isDark) {
        // Dark mode simulation on Tiger - use light text
        return [NSColor colorWithCalibratedWhite:0.85 alpha:1.0];
    } else {
        // Use system default black text for Aqua
        return [NSColor controlTextColor];
    }
}

+ (NSColor *)secondaryLabelColorForDarkMode:(BOOL)isDark {
    if (isDark) {
        return [NSColor colorWithCalibratedWhite:0.55 alpha:1.0];
    } else {
        // Use system disabled control text color
        return [NSColor disabledControlTextColor];
    }
}

+ (NSColor *)tertiaryLabelColorForDarkMode:(BOOL)isDark {
    if (isDark) {
        return [NSColor colorWithCalibratedWhite:0.35 alpha:1.0];
    } else {
        return [NSColor colorWithCalibratedWhite:0.66 alpha:1.0];
    }
}

+ (NSColor *)quaternaryLabelColorForDarkMode:(BOOL)isDark {
    if (isDark) {
        return [NSColor colorWithCalibratedWhite:0.25 alpha:1.0];
    } else {
        return [NSColor colorWithCalibratedWhite:0.75 alpha:1.0];
    }
}

// MARK: - Background Colors (use Aqua defaults for light mode)

+ (NSColor *)textBackgroundColorForDarkMode:(BOOL)isDark {
    if (isDark) {
        // Dark mode simulation
        return [NSColor colorWithCalibratedRed:0.118 green:0.118 blue:0.118 alpha:1.0];
    } else {
        // Use system text background (white)
        return [NSColor textBackgroundColor];
    }
}

+ (NSColor *)windowBackgroundColorForDarkMode:(BOOL)isDark {
    if (isDark) {
        // Dark mode simulation
        return [NSColor colorWithCalibratedRed:0.149 green:0.149 blue:0.149 alpha:1.0];
    } else {
        // Use system window background (Aqua pinstripe on Tiger)
        return [NSColor windowBackgroundColor];
    }
}

+ (NSColor *)controlBackgroundColorForDarkMode:(BOOL)isDark {
    if (isDark) {
        // Dark mode simulation
        return [NSColor colorWithCalibratedRed:0.25 green:0.25 blue:0.25 alpha:1.0];
    } else {
        // Use system control color
        return [NSColor controlColor];
    }
}

+ (NSColor *)alternatingRowColorForDarkMode:(BOOL)isDark {
    if (isDark) {
        // Dark mode simulation - slightly lighter for alternating rows
        return [NSColor colorWithCalibratedRed:0.17 green:0.17 blue:0.17 alpha:1.0];
    } else {
        // Use system alternating row colors (blue-white stripes in Aqua)
        // Tiger doesn't have controlAlternatingRowBackgroundColors, so we'll use a light blue
        return [NSColor colorWithCalibratedRed:0.929 green:0.953 blue:0.996 alpha:1.0];
    }
}

// MARK: - System Colors (use Aqua defaults for light mode)

+ (NSColor *)systemBlueForDarkMode:(BOOL)isDark {
    if (isDark) {
        return [NSColor colorWithCalibratedRed:0.039 green:0.518 blue:1.0 alpha:1.0];
    } else {
        // Classic Aqua blue
        return [NSColor colorWithCalibratedRed:0.0 green:0.4 blue:0.8 alpha:1.0];
    }
}

+ (NSColor *)systemPurpleForDarkMode:(BOOL)isDark {
    if (isDark) {
        return [NSColor colorWithCalibratedRed:0.75 green:0.35 blue:0.95 alpha:1.0];
    } else {
        return [NSColor purpleColor];
    }
}

+ (NSColor *)systemGreenForDarkMode:(BOOL)isDark {
    if (isDark) {
        return [NSColor colorWithCalibratedRed:0.196 green:0.843 blue:0.294 alpha:1.0];
    } else {
        return [NSColor colorWithCalibratedRed:0.0 green:0.5 blue:0.0 alpha:1.0];
    }
}

+ (NSColor *)systemRedForDarkMode:(BOOL)isDark {
    if (isDark) {
        return [NSColor colorWithCalibratedRed:1.0 green:0.271 blue:0.227 alpha:1.0];
    } else {
        return [NSColor redColor];
    }
}

+ (NSColor *)linkColorForDarkMode:(BOOL)isDark {
    return [self systemBlueForDarkMode:isDark];
}

// MARK: - Code Colors

+ (NSColor *)codeColorForDarkMode:(BOOL)isDark {
    if (isDark) {
        return [NSColor colorWithCalibratedRed:0.4 green:0.9 blue:0.8 alpha:1.0];
    } else {
        return [NSColor colorWithCalibratedRed:0.0 green:0.5 blue:0.25 alpha:1.0];
    }
}

+ (NSColor *)codeBackgroundColorForDarkMode:(BOOL)isDark {
    if (isDark) {
        return [NSColor colorWithCalibratedRed:0.08 green:0.08 blue:0.08 alpha:1.0];
    } else {
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
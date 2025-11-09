//
//  NESizingHelpers.h
//  Tiger-safe sizing and layout helpers for AppKit controls.
//
//  This header declares a handful of lightweight functions to help size
//  NSButton and other Cocoa controls in a way that respects Aqua padding,
//  keeps layouts dynamic, and remains compatible with Mac OS X 10.4 Tiger.
//
//  Design goals
//  ------------
//  - Prefer the control/cell's own sizing (sizeToFit / cellSize)
//  - Enforce sensible minimum widths for dialog/action buttons
//  - Provide quick baseline-alignment utilities for tidy forms
//  - Offer a simple row layout helper (label + field + trailing button)
//  - Avoid Auto Layout (not present on Tiger); rely on frames + autoresizing
//
//  Usage sketch
//  ------------
//    [okButton setBezelStyle:NSRoundedBezelStyle];
//    [okButton setControlSize:NSRegularControlSize];
//    [okButton setTitle:NSLocalizedString(@"OK", nil)];
//    NSButtonSizeToFitWithMinimum(okButton); // natural size, clamped to min width
//
//    // In -resizeSubviewsWithOldSize:, lay out a simple form row
//    LayoutFormRow(self, nameLabel, nameField, okButton, NSWidth([self bounds]));
//
//    // Keep baselines aligned across label/field pairs
//    AlignBaselines(nameLabel, nameField);
//
//  Notes
//  -----
//  * All APIs here are available on 10.4 (Tiger) and later.
//  * This code assumes **manual reference counting** (no ARC).
//  * Keep inter-control spacing consistent; these helpers only size/position.
//
//  © 2025 Nyteshade Enterprises — MIT license (optional; adjust as needed).
//

#ifndef NESizingHelpers_h
#define NESizingHelpers_h

#import <Cocoa/Cocoa.h>
#import "TigerCompat.h"

#ifdef __cplusplus
extern "C" {
#endif

// MARK: - Button sizing

/**
 Returns a conservative minimum button width for a given control size.

 These floors help dialog/action buttons remain comfortably clickable and
 visually balanced, while still allowing dynamic widening for longer titles.

 @param size  The NSControlSize (NSMiniControlSize, NSSmallControlSize, NSRegularControlSize).
 @return      A suggested minimum width in points.
 */
extern CGFloat NSButtonMinimumWidthForControlSize(NSControlSize size);

/**
 Sizes a button to its natural content (title/image/font/bezel), then clamps
 its width to a sensible minimum based on its control size.

 This function also ensures the button's font matches its control size before
 measuring, which keeps Aqua padding/metrics correct.

 @param button  The NSButton to size in-place. No-op if nil.

 @discussion
 Call this after setting bezelStyle, controlSize, title (or attributedTitle),
 image, imagePosition, and font (if you use a custom one). If you later mutate
 any of those properties (e.g., after localization), call this again.

 Height is preserved as measured; only width is clamped upward if below the
 recommended minimum.
 */
extern void NSButtonSizeToFitWithMinimum(NSButton *button);

// MARK: - Baseline alignment

/**
 Returns the offset from the bottom of a view's frame to its text baseline,
 given the view's (text) font.

 For common single-line text-bearing controls (NSTextField, NSSearchField,
 etc.), this consults the control's cell for an accurate title rect. If the
 view isn't a control, falls back to the font's ascender.

 @param view  A text-bearing NSView (NSTextField, etc.). May be nil.
 @param font  The NSFont used by the view. If nil, returns 0.
 @return      The baseline offset in points from NSMinY([view frame]).
 */
extern CGFloat BaselineOffsetForView(NSView *view, NSFont *font);

/**
 Vertically aligns the baselines of two text-bearing controls by shifting the
 second view (rightView) up or down to match the first (leftView).

 This is useful for keeping labels and fields visually tidy in form rows.

 @param leftView   The reference view whose baseline is considered correct.
 @param rightView  The view to be adjusted to match leftView's baseline.
 */
extern void AlignBaselines(NSView *leftView, NSView *rightView);

// MARK: - Simple form-row layout (label • field • trailing button)

/**
 Lays out a single horizontal row inside a container view:

   [label][hGap][field][bGap][button]   with outer content margins

 The label is sized to fit its content, the button is sized (with a minimum),
 and the field expands to fill the remaining space between label and button.
 All three are vertically centered within the row's available height.

 Use this from -resizeSubviewsWithOldSize: (or when content changes) and set
 autoresizing masks so that the container resizes with its superview. The field
 should typically have NSViewWidthSizable so it grows/shrinks horizontally.

 @param container        The parent view whose bounds define the row's height.
 @param label            Typically an NSTextField (bezeled or not). May be nil.
 @param field            Typically an NSTextField or NSPopUpButton. May be nil.
 @param button           The trailing NSButton (right-anchored). May be nil.
 @param containerWidth   The available width for layout (usually NSWidth([container bounds])).

 @discussion
 Spacing and margins are chosen to be Aqua-friendly but intentionally simple.
 Adjust constants in the implementation to suit your visual rhythm.
 */
extern void LayoutFormRow(NSView *container,
                          NSView *label,
                          NSView *field,
                          NSButton *button,
                          CGFloat containerWidth);

#ifdef __cplusplus
} // extern "C"
#endif

#endif /* NESizingHelpers_h */

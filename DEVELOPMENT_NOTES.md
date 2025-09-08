# Claude Chat Development Notes

## Project Overview
A Mac OS X Tiger-compatible (10.4+) Claude chat application built with pure Objective-C, manual memory management, and programmatically generated UI.

## Current Status (2025-09-08)

### Completed Features
1. **Core Application Structure**
   - AppDelegate with API key management and model selection
   - ChatWindowController with conversation management
   - Tiger-compatible networking (NSURLConnection)
   - Manual JSON parsing for Tiger compatibility
   - Delegate pattern instead of blocks (prevents crashes on Tiger)

2. **UI Implementation (HIG-Compliant)**
   - **Control Bar** (44pt height) with integrated buttons:
     - Conversations toggle (110pt wide)
     - New Chat button (80pt wide)
     - Clear button (70pt wide, right-aligned)
   - **Proper Spacing**:
     - 20pt window margins
     - 8pt inline element spacing
     - 10pt section spacing
   - **Semantic Font Sizing**:
     - System font size as base (13pt)
     - Small system font for controls (11pt)
     - Dynamic adjustment support

3. **Conversation Management**
   - NSDrawer for conversation list
   - Persistent storage in ~/Library/Application Support/ClaudeChat/
   - Full conversation history maintained
   - Switching between conversations works
   - API responses saved to conversations

4. **Theme Support**
   - Light/dark mode switching
   - Apple semantic colors (hardcoded for Tiger)
   - Theme persistence across sessions

5. **Markdown Parsing**
   - Basic markdown rendering in chat
   - Headers (#, ##, ###)
   - Bullet points (-, *)
   - Code blocks (backticks)
   - Bold and italic text

6. **Model Support**
   - Claude Opus 4.1 (claude-opus-4-1-20250805)
   - Claude Opus 4 (claude-opus-4-20250620)
   - Claude Sonnet 4 (claude-sonnet-4-20250416)
   - Claude Sonnet 3.7 (claude-3-7-sonnet-20241215)
   - Claude Haiku 3 (claude-3-haiku-20240307)

### Technical Decisions

#### Memory Management
- Manual retain/release (no ARC)
- Careful autoreleasepool management in background threads
- Delegate pattern to avoid block deallocation crashes

#### UI Generation
- Programmatic UI only (no XIB/NIB files)
- NSTexturedRoundedBezelStyle for control buttons
- NSRoundedBezelStyle for Send button
- Focus rings on text fields

#### Networking
- NSURLConnection for Tiger compatibility
- Synchronous requests in background threads
- Manual JSON serialization/parsing

#### File Structure
```
/Users/brie/Desktop/AIChat/
├── main.m
├── AppDelegate.h/m
├── ChatWindowController.h/m
├── ClaudeAPIManager.h
├── ClaudeAPIManager_Tiger.m
├── NetworkManager_Tiger.h/m
├── ConversationManager.h/m
├── ThemeColors.h/m
├── Makefile.tiger
└── build/
    └── ClaudeChat.app/
```

### Build Instructions
```bash
# Clean build for Tiger compatibility
make -f Makefile.tiger clean && make -f Makefile.tiger

# Run the application
./build/ClaudeChat.app/Contents/MacOS/ClaudeChat
```

### Known Issues Fixed
1. ✅ Crash when sending messages - Fixed by removing blocks
2. ✅ Font too small - Using semantic sizing
3. ✅ Poor spacing - Following Apple HIG
4. ✅ Response parsing failure - Fixed JSON parser
5. ✅ Font size menu not working - Fixed implementation
6. ✅ Conversation selection not working - Fixed delegate methods
7. ✅ No drawer toggle - Added control bar buttons
8. ✅ Toolbar not HIG-compliant - Removed, integrated into window

### Current UI Layout
```
┌─────────────────────────────────────┐
│ Control Bar (44pt)                  │
│ [Conversations] [New Chat]   [Clear]│
├─────────────────────────────────────┤
│                                     │
│         Chat Text View              │
│         (with scroll)               │
│                                     │
├─────────────────────────────────────┤
│ [Message Field............] [Send]  │
└─────────────────────────────────────┘

Drawer (250pt wide):
┌──────────────┐
│ Conversations│
├──────────────┤
│ • Chat 1     │
│ • Chat 2     │
│ • Chat 3     │
└──────────────┘
```

### Remaining Considerations

1. **Icon/Image Assets**
   - Currently using text-only buttons
   - Could add custom icons if needed
   - SF Symbols not available on Tiger

2. **Performance**
   - Conversation switching could be optimized
   - Consider limiting history sent to API

3. **Polish Items**
   - Add keyboard shortcuts for common actions
   - Improve markdown parser for more formats
   - Add export conversation feature
   - Add search within conversations

### User Feedback Integration
- "Follow the HIG" - ✅ Implemented proper spacing and semantic fonts
- "Toolbar elements into window UI" - ✅ Moved to control bar
- "Semantic font allocations" - ✅ Using NSFont system sizes
- "Spacing doesn't feel balanced" - ✅ Applied consistent HIG spacing

### Next Session Starting Point
The application is fully functional with HIG-compliant UI. Any future work should focus on:
1. Adding custom icons/images if needed
2. Performance optimizations
3. Additional features (export, search, etc.)
4. Testing on actual Tiger hardware

### Compiler Warnings to Address
```
ChatWindowController.m:314:11: warning: unused variable 'messageFontSize'
ConversationManager.m:96:67: warning: null passed to callee requiring non-null
ConversationManager.m:132:62: warning: NSUInteger format string
```

These are minor and don't affect functionality but could be cleaned up.
# Xcode Project Generation

## Quick Start

Generate an Xcode project for your current platform:
```bash
make xcode
```

Or auto-detect platform:
```bash
./tools/generate-xcode.sh
```

Or specify a platform:
```bash
./tools/generate-xcode.sh leopard
```

## Clean and Regenerate

To remove all Xcode projects and start fresh:
```bash
make clean-xcode
make xcode
```

## Available Platforms

- `tiger` - Mac OS X 10.4 Tiger (PowerPC/Intel) - Xcode 2.5 compatible
- `leopard` - Mac OS X 10.5 Leopard (PowerPC/Intel) - Xcode 3.1 compatible
- `snow` - Mac OS X 10.6 Snow Leopard - Xcode 3.2+ compatible
- `lion` - Mac OS X 10.7 Lion - Xcode 3.2+ compatible
- `mountain` - Mac OS X 10.8 Mountain Lion - Xcode 3.2+ compatible
- `modern` - Mac OS X 10.9+ / macOS - Xcode 3.2+ compatible

**Note**: Each platform generates a project file compatible with the Xcode version typically used on that OS version. Tiger and Leopard use older project formats (objectVersion 42/45) for compatibility with Xcode 2.5 and 3.1.

## Debugging Tips

### Open Project
```bash
open xcode/ClaudeChat-leopard.xcodeproj
```

### Key Breakpoints for Window Issue

Set breakpoints at these locations to debug why the window doesn't appear:

1. **AppDelegate.m:62** - Where chatWindowController is created
2. **ChatWindowController.m:20** - init method
3. **ChatWindowController.m:70** - createWindow method start
4. **ChatWindowController.m:259** - Where mainWindow is retained
5. **ChatWindowController.m:38** - showWindow method

### Debugger Commands

While paused at a breakpoint, use these commands in the debugger console:

```lldb
po window                      # Print window object
po mainWindow                  # Print mainWindow variable
po (int)[window retainCount]   # Check retain count
po [self window]               # What NSWindowController thinks
po chatWindowController        # Check if controller is valid
bt                             # Show call stack
```

### Check Console Output

Look for these log messages:
- "Setting up menus"
- "ChatWindowController showWindow:"
- "ERROR: ChatWindowController showWindow called but window is nil!"

## Project Settings

The generated Xcode projects have:
- **ARC**: Disabled (uses MRC with SAFEArc.h macros)
- **Debugging**: Symbols enabled, optimization disabled in Debug
- **OpenSSL**: Included for Tiger through Mountain Lion
- **Deployment Target**: Set per platform

## Notes

- Projects use relative paths, so they work on any machine
- Debug builds include full symbols for debugging
- The project matches Makefile settings exactly

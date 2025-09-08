# ClaudeChat - Mac OS X Tiger Compatible Chat Client

A native Cocoa application for chatting with Claude AI, designed to work on Mac OS X Tiger (10.4) and later.

## Features

- Native Cocoa UI built programmatically (no XIB/NIB files)
- Compatible with Mac OS X Tiger (10.4) through modern macOS
- Simple chat interface with conversation history
- API key management with secure storage in preferences
- Network abstraction layer for SSL/TLS compatibility

## Requirements

- Mac OS X 10.4 (Tiger) or later
- Claude API key from Anthropic
- Xcode Developer Tools or GCC compiler

## Building on Modern macOS

For building on a modern Mac (10.6+):

```bash
# Standard build
make

# Run the application
make run

# Clean build files
make clean
```

## Building for Tiger Compatibility

For maximum Tiger compatibility (no ARC, no blocks):

```bash
# Use the Tiger-specific makefile
make -f Makefile.tiger

# Run the application
make -f Makefile.tiger run
```

## Manual Compilation

If you prefer to compile manually:

```bash
# Compile all source files
gcc -c -ObjC -o main.o main.m
gcc -c -ObjC -o AppDelegate.o AppDelegate.m
gcc -c -ObjC -o ChatWindowController.o ChatWindowController.m
gcc -c -ObjC -o ClaudeAPIManager_Tiger.o ClaudeAPIManager_Tiger.m
gcc -c -ObjC -o NetworkManager_Tiger.o NetworkManager_Tiger.m

# Link the application
gcc -framework Cocoa -framework Foundation \
    -o ClaudeChat \
    main.o AppDelegate.o ChatWindowController.o \
    ClaudeAPIManager_Tiger.o NetworkManager_Tiger.o

# Create app bundle
mkdir -p build/ClaudeChat.app/Contents/MacOS
mv ClaudeChat build/ClaudeChat.app/Contents/MacOS/

# Create Info.plist (see Makefile for template)
```

## Using with OpenSSL

For enhanced SSL support on older systems, you can compile with OpenSSL:

```bash
# Install OpenSSL via MacPorts or Homebrew
# MacPorts: sudo port install openssl
# Homebrew: brew install openssl

# Compile with OpenSSL support
make OPENSSL_CFLAGS="-I/opt/local/include" \
     OPENSSL_LIBS="-L/opt/local/lib -lssl -lcrypto"
```

## API Key Setup

1. Launch the application
2. You'll be prompted to enter your Claude API key
3. The key is stored securely in user preferences
4. To change the key later, quit and relaunch the app

## Architecture Notes

### Tiger Compatibility

- Uses manual memory management (no ARC)
- No blocks or GCD (uses NSThread/performSelector)
- Compatible with gcc compiler
- Uses NSURLConnection for networking
- Manual JSON serialization for older systems

### File Structure

- `main.m` - Application entry point
- `AppDelegate.*` - Application lifecycle and API key management
- `ChatWindowController.*` - Main chat window UI and logic
- `ClaudeAPIManager.*` - Claude API communication
- `NetworkManager.*` - Network abstraction layer
- `*_Tiger.*` - Tiger-specific implementations without modern features

## Testing on Different OS X Versions

The application has been designed to work on:
- Mac OS X 10.4 (Tiger)
- Mac OS X 10.5 (Leopard)
- Mac OS X 10.6 (Snow Leopard)
- Mac OS X 10.7+ (Lion and later)

## Known Limitations

- On Tiger, SSL certificate validation may be limited
- JSON parsing is simplified for Tiger compatibility
- No support for streaming responses
- Limited to claude-3-haiku model for simplicity

## License

This is a demonstration project for educational purposes.
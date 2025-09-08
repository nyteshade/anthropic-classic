# ClaudeChat - Development Notes

## Project Overview
ClaudeChat is a native macOS application for interacting with Claude AI via the Anthropic API. The app is designed to work on both modern macOS systems (Intel/ARM) and legacy PowerPC systems running Mac OS X Tiger/Leopard.

## Build System

### Smart Build Script
Use `./build.sh` to automatically detect your system and build with the appropriate configuration:
- Detects architecture (PowerPC, Intel, ARM)
- Checks for required dependencies (MacPorts OpenSSL on older systems)
- Selects the correct Makefile automatically

### Manual Build Options

#### Modern macOS (Intel/ARM, macOS 10.6+)
```bash
make clean
make
```
Uses system SSL/TLS libraries and modern Objective-C features.

#### Tiger/Leopard (PowerPC, Mac OS X 10.4-10.5)
```bash
make -f Makefile.tiger clean
make -f Makefile.tiger
```
Requires MacPorts OpenSSL: `sudo port install openssl`

## Architecture

### Core Components

1. **AppDelegate**: Main application delegate, handles menu and preferences
2. **ChatWindowController**: Main UI controller, manages chat interface
3. **ClaudeAPIManager_Tiger**: Handles API communication with Claude
4. **HTTPSClient**: Network layer with two implementations:
   - `HTTPSClient.m`: Uses NSURLConnection (modern macOS)
   - `HTTPSClient_OpenSSL.m`: Uses OpenSSL directly (Tiger/Leopard)
5. **ConversationManager**: Manages chat history and persistence
6. **yyjson**: C89-compatible JSON parser for reliable parsing

### Key Features

- **Multiple conversation support** with sidebar drawer
- **Markdown rendering** for code blocks and formatting
- **Dark/Light mode** support
- **Customizable fonts** for user and Claude messages
- **Persistent conversation history** saved to disk
- **API key secure storage** in system preferences

## Network Stack

### Modern Systems
- Uses NSURLConnection with system SSL/TLS
- Automatic certificate validation
- Native integration with macOS security framework

### Legacy Systems (Tiger/Leopard)
- Requires MacPorts OpenSSL for modern TLS support
- Direct OpenSSL implementation bypasses outdated system SSL
- Handles TLS 1.2+ required by Anthropic API

## Known Issues and Solutions

### Issue: Crash when deleting all conversations
**Solution**: Fixed in ConversationManager.m - automatically creates new conversation when all are deleted

### Issue: SSL/TLS errors on Tiger/Leopard
**Solution**: Install MacPorts OpenSSL and use Makefile.tiger

### Issue: JSON parsing failures
**Solution**: Integrated yyjson library for robust C89-compatible parsing

## Testing

### JSON Parser Test
```bash
gcc -o test_json_parser test_json_parser.c yyjson.c
./test_json_parser test_response.json
```

### API Response Testing
The app includes detailed logging. Run from terminal to see output:
```bash
./build/ClaudeChat.app/Contents/MacOS/ClaudeChat
```

## File Organization

### Main Application Files
- `main.m` - Application entry point
- `AppDelegate.m/h` - Application delegate
- `ChatWindowController.m/h` - Main window controller
- `ClaudeAPIManager.h` - API manager interface
- `ClaudeAPIManager_Tiger.m` - Tiger-compatible API implementation

### Network Layer
- `HTTPSClient.m/h` - Network client for modern systems
- `HTTPSClient_OpenSSL.m` - OpenSSL-based client for legacy systems
- `NetworkManager_Tiger.m/h` - Legacy network utilities

### UI Components
- `ThemeColors.m/h` - Theme management
- `CodeBlockView.m/h` - Code block rendering
- `ConversationManager.m/h` - Conversation management

### Build System
- `Makefile` - Modern macOS builds
- `Makefile.tiger` - Tiger/PowerPC builds
- `build.sh` - Smart build script

### Utilities
- `yyjson.c/h` - JSON parser
- `test_json_parser.c` - JSON parser test harness
- `test_response.json` - Sample API response for testing

## Development Guidelines

1. **Maintain C89 compatibility** in C code for Tiger support
2. **Test on both modern and legacy systems** when possible
3. **Use conditional compilation** for platform-specific features
4. **Keep network code modular** to support different SSL implementations
5. **Log extensively** for debugging on systems without modern dev tools

## Deployment

### Modern macOS
Simply distribute the .app bundle from `build/ClaudeChat.app`

### Tiger/Leopard
Ensure users have MacPorts OpenSSL installed:
```bash
sudo port install openssl
```
Then distribute the .app bundle built with `make -f Makefile.tiger`

## API Configuration

Users need to:
1. Obtain an API key from https://console.anthropic.com/
2. Enter the key in ClaudeChat preferences
3. Select their preferred Claude model

The API key is stored securely in NSUserDefaults.
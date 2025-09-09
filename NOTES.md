# ClaudeChat Development Notes - September 8, 2025

## Recent Fixes Completed

### 1. API Message Handling
- **Issue**: Messages were being sent with whitespace/newlines causing "empty content" API errors
- **Fix**: Changed to use `trimmedMessage` instead of raw `message` in ChatWindowController.m (lines 383, 390, 414)

### 2. Button Styling for Tiger/Leopard
- **Issue**: Buttons didn't have proper Aqua appearance on older macOS
- **Fix**: Changed all buttons from `NSTexturedRoundedBezelStyle` to `NSRoundRectBezelStyle`
- **Fix**: Added center text alignment to all buttons using `[[button cell] setAlignment:NSCenterTextAlignment]`

### 3. UI Layout
- **Issue**: Insufficient padding between control buttons and text area
- **Fix**: Added 8pt extra padding (`topPadding`) between control bar and chat text view

### 4. OpenSSL/HTTPS Issues on Leopard
- **Issue**: OpenSSL headers not found on Leopard PowerPC with MacPorts
- **Fix**: Removed `__has_include` checks (not supported by older GCC)
- **Fix**: Now relies on Makefile's `-I/opt/local/include` flag for header paths

### 5. API Key Processing
- **Issue**: API key had trailing newline character
- **Fix**: Added trimming of whitespace/newlines in ClaudeAPIManager_Tiger.m

### 6. HTTPSClient Data Corruption
- **Issue**: Binary data was being converted to string, corrupting the request
- **Fix**: Added new `sendRequestData:` method that handles NSData directly
- **Fix**: Modified `sendPOSTRequest` to use binary data throughout

### 7. Build Configuration
- **Issue**: Makefile.tiger was including both HTTPSClient.m and HTTPSClient_OpenSSL.m causing duplicate symbols
- **Fix**: Makefile.tiger now only includes HTTPSClient_OpenSSL.m for OpenSSL support
- **Note**: Regular Makefile uses HTTPSClient.m (native SSL), Tiger makefile uses HTTPSClient_OpenSSL.m (MacPorts OpenSSL)

## Protocol Compatibility
- Removed all formal protocol declarations for Tiger/Leopard compatibility
- Relies on informal protocols (respondsToSelector checks)
- Affected protocols: NSApplicationDelegate, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate, NSTextViewDelegate

## Build Instructions
- **Modern macOS**: `make`
- **Tiger/Leopard PowerPC**: `make -f Makefile.tiger`
- Requires MacPorts OpenSSL installed at `/opt/local/` for Tiger/Leopard

## Remaining Considerations
- The response parsing now has detailed logging to help diagnose any remaining SSL/JSON issues on Leopard
- If JSON parsing fails, console will show which fields are present in the response
- Theme colors are properly set up for both light and dark modes with Tiger-compatible Aqua colors

## Testing Status
- Builds successfully on modern macOS (M3 Max)
- Tiger/Leopard build needs testing on actual PowerPC hardware
- API communication should now work correctly with proper trimming and binary data handling
#!/bin/bash

echo "======================================="
echo "ClaudeChat Build Test"
echo "======================================="
echo

# Clean build
echo "Cleaning previous build..."
make clean

# Build
echo "Building application..."
if make; then
    echo "✓ Build successful"
else
    echo "✗ Build failed"
    exit 1
fi

# Check executable exists
if [ -f "build/ClaudeChat.app/Contents/MacOS/ClaudeChat" ]; then
    echo "✓ Executable created"
else
    echo "✗ Executable not found"
    exit 1
fi

# Check Info.plist exists
if [ -f "build/ClaudeChat.app/Contents/Info.plist" ]; then
    echo "✓ Info.plist created"
else
    echo "✗ Info.plist not found"
    exit 1
fi

# Test JSON parser
echo
echo "Testing JSON parser..."
if gcc -o test_json_parser test_json_parser.c yyjson.c 2>/dev/null && ./test_json_parser test_response.json 2>&1 | grep -q "Extracted text"; then
    echo "✓ JSON parser works"
else
    echo "✗ JSON parser test failed"
fi

echo
echo "======================================="
echo "All tests passed!"
echo "======================================="
echo
echo "To run the app: open build/ClaudeChat.app"

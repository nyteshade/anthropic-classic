#!/bin/bash

echo "ClaudeChat Build Test Script"
echo "============================"
echo ""

# Clean previous builds
echo "Cleaning previous builds..."
make -f Makefile.tiger clean

# Build the application
echo "Building ClaudeChat for Tiger compatibility..."
if make -f Makefile.tiger; then
    echo "✓ Build successful!"
    
    # Check if the executable exists
    if [ -f "build/ClaudeChat.app/Contents/MacOS/ClaudeChat" ]; then
        echo "✓ Executable created"
        
        # Check file info
        echo ""
        echo "Application info:"
        file build/ClaudeChat.app/Contents/MacOS/ClaudeChat
        
        # Check compatibility
        echo ""
        echo "Checking minimum OS version:"
        otool -l build/ClaudeChat.app/Contents/MacOS/ClaudeChat | grep -A 3 LC_VERSION_MIN_MACOSX
        
        echo ""
        echo "Application bundle created at: build/ClaudeChat.app"
        echo "To run: open build/ClaudeChat.app"
    else
        echo "✗ Executable not found"
        exit 1
    fi
else
    echo "✗ Build failed"
    exit 1
fi
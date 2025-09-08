#!/bin/bash
#
# Smart build script for ClaudeChat
# Detects system architecture and available libraries
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "======================================="
echo "ClaudeChat Build System"
echo "======================================="

# Detect architecture
ARCH=$(uname -m)
OS_VERSION=$(sw_vers -productVersion)
OS_MAJOR=$(echo $OS_VERSION | cut -d. -f1)
OS_MINOR=$(echo $OS_VERSION | cut -d. -f2)

echo "System: macOS $OS_VERSION"
echo "Architecture: $ARCH"

# Check for PowerPC
if [[ "$ARCH" == "ppc" ]] || [[ "$ARCH" == "ppc64" ]]; then
    echo -e "${YELLOW}PowerPC architecture detected${NC}"
    USE_TIGER_BUILD=true
elif [[ "$OS_MAJOR" -eq 10 ]] && [[ "$OS_MINOR" -le 5 ]]; then
    echo -e "${YELLOW}Mac OS X 10.5 or earlier detected${NC}"
    USE_TIGER_BUILD=true
else
    echo -e "${GREEN}Modern macOS detected${NC}"
    USE_TIGER_BUILD=false
fi

# Check for MacPorts OpenSSL if using Tiger build
if [ "$USE_TIGER_BUILD" = true ]; then
    echo ""
    echo "Checking for MacPorts OpenSSL..."
    
    if [ -f "/opt/local/include/openssl/ssl.h" ]; then
        echo -e "${GREEN}✓ MacPorts OpenSSL found${NC}"
        
        # Use the OpenSSL version of HTTPSClient
        if [ -f "HTTPSClient_OpenSSL.m" ]; then
            echo "Using HTTPSClient with OpenSSL support"
            cp HTTPSClient_OpenSSL.m HTTPSClient_Tiger.m
        fi
        
        MAKEFILE="Makefile.tiger"
    else
        echo -e "${RED}✗ MacPorts OpenSSL not found${NC}"
        echo ""
        echo "Tiger/Leopard builds require MacPorts OpenSSL."
        echo "Install with: sudo port install openssl"
        echo ""
        echo "Alternatively, you can try the fallback build (may have limited HTTPS support):"
        echo "  make -f Makefile.tiger"
        exit 1
    fi
else
    # Modern build - use system SSL
    echo "Using system SSL/TLS libraries"
    MAKEFILE="Makefile"
fi

# Clean previous build
echo ""
echo "Cleaning previous build..."
make -f $MAKEFILE clean

# Build the application
echo ""
echo "Building ClaudeChat with $MAKEFILE..."
make -f $MAKEFILE

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}=======================================${NC}"
    echo -e "${GREEN}Build successful!${NC}"
    echo -e "${GREEN}=======================================${NC}"
    echo ""
    echo "Application built at: build/ClaudeChat.app"
    echo ""
    echo "To run the application:"
    echo "  open build/ClaudeChat.app"
    echo "Or:"
    echo "  ./build/ClaudeChat.app/Contents/MacOS/ClaudeChat"
else
    echo ""
    echo -e "${RED}=======================================${NC}"
    echo -e "${RED}Build failed!${NC}"
    echo -e "${RED}=======================================${NC}"
    echo ""
    echo "Check the error messages above for details."
    exit 1
fi
################################################################################
# ClaudeChat Smart Makefile
# Compatible with Mac OS X 10.4 Tiger through modern macOS
#
# Features:
# - Auto-discovers source files (.m, .c)
# - Platform-specific source selection (platform/<os>/ or generic/)
# - Automatic OS detection and compiler configuration
# - No manual file list maintenance required
#
# Usage:
#   make              # Build for current platform
#   make clean        # Clean build artifacts
#   make run          # Build and run
#   make debug        # Build with debug symbols
#   make xcode        # Generate Xcode project for current platform
#
################################################################################

################################################################################
# MARK: - Application Configuration
################################################################################

APP_NAME = ClaudeChat
BUNDLE_ID = com.nyteshade.anthropic-classic
VERSION = 1.0
BUILD_NUMBER = 1


################################################################################
# MARK: - Platform Detection
################################################################################

# Detect operating system version
OS_VERSION := $(shell sw_vers -productVersion 2>/dev/null || echo "unknown")
OS_MAJOR := $(shell echo $(OS_VERSION) | cut -d. -f1)
OS_MINOR := $(shell echo $(OS_VERSION) | cut -d. -f2)

# Detect architecture
ARCH := $(shell uname -m)

# Determine platform identifier for source selection
# tiger    = 10.4
# leopard  = 10.5
# snow     = 10.6
# lion     = 10.7
# mountain = 10.8
# modern   = 10.9+

ifeq ($(OS_MAJOR),10)
  ifeq ($(OS_MINOR),4)
    PLATFORM = tiger
    MIN_OS_VERSION = 10.4
    NEEDS_OPENSSL = yes
  else ifeq ($(OS_MINOR),5)
    PLATFORM = leopard
    MIN_OS_VERSION = 10.5
    NEEDS_OPENSSL = yes
  else ifeq ($(OS_MINOR),6)
    PLATFORM = snow
    MIN_OS_VERSION = 10.6
    NEEDS_OPENSSL = yes
  else ifeq ($(OS_MINOR),7)
    PLATFORM = lion
    MIN_OS_VERSION = 10.7
    NEEDS_OPENSSL = yes
  else ifeq ($(OS_MINOR),8)
    PLATFORM = mountain
    MIN_OS_VERSION = 10.8
    NEEDS_OPENSSL = yes
  else
    PLATFORM = modern
    MIN_OS_VERSION = 10.9
    NEEDS_OPENSSL = no
  endif
else
  # macOS 11+
  PLATFORM = modern
  MIN_OS_VERSION = 11.0
  NEEDS_OPENSSL = no
endif

# PowerPC detection
ifneq (,$(findstring ppc,$(ARCH)))
  PLATFORM = tiger
  MIN_OS_VERSION = 10.4
  NEEDS_OPENSSL = yes
endif


################################################################################
# MARK: - Compiler Configuration
################################################################################

# Select compiler based on platform
ifeq ($(PLATFORM),tiger)
  CC = gcc-apple-4.2
  OBJC = $(CC)
  ARCH_FLAGS =
else ifeq ($(PLATFORM),leopard)
  CC = gcc-apple-4.2
  OBJC = $(CC)
  ARCH_FLAGS = -arch x86_64
else ifeq ($(PLATFORM),snow)
  CC = gcc-apple-4.2
  OBJC = $(CC)
  ARCH_FLAGS = -arch x86_64
else
  # Modern platforms - use clang
  CC = clang
  OBJC = clang
  ARCH_FLAGS = -arch x86_64
endif

# Base compiler flags
CFLAGS = -Wall -O2 -std=c99 $(ARCH_FLAGS)
OBJCFLAGS = -Wall -O2 -ObjC -fobjc-arc-exceptions $(ARCH_FLAGS)

# SDK flags
SDKFLAGS = -mmacosx-version-min=$(MIN_OS_VERSION)

# Framework flags
FRAMEWORKS = -framework Cocoa -framework Foundation

# OpenSSL configuration (for early platforms)
ifeq ($(NEEDS_OPENSSL),yes)
  OPENSSL_CFLAGS = -I/opt/local/include
  OPENSSL_LDFLAGS = -L/opt/local/lib -lssl -lcrypto

  # Check if OpenSSL is available
  OPENSSL_CHECK := $(shell test -f /opt/local/include/openssl/ssl.h && echo "yes" || echo "no")
  ifneq ($(OPENSSL_CHECK),yes)
    $(warning )
    $(warning WARNING: MacPorts OpenSSL not found!)
    $(warning For OS X $(OS_MAJOR).$(OS_MINOR), you need MacPorts OpenSSL.)
    $(warning Install with: sudo port install openssl)
    $(warning )
  endif
else
  OPENSSL_CFLAGS =
  OPENSSL_LDFLAGS =
endif


################################################################################
# MARK: - Directory Structure
################################################################################

BUILD_DIR = build
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
CONTENTS_DIR = $(APP_BUNDLE)/Contents
MACOS_DIR = $(CONTENTS_DIR)/MacOS
RESOURCES_DIR = $(CONTENTS_DIR)/Resources

# Source directories
SRC_DIRS = . platform/$(PLATFORM) platform/generic
VPATH = $(SRC_DIRS)


################################################################################
# MARK: - Source File Discovery
################################################################################

# Find all .m files, excluding build and xcode directories
ALL_M_FILES := $(shell find . -name "*.m" ! -path "./build/*" ! -path "./xcode/*" ! -path "./.git/*" -type f)

# Find all .c files
ALL_C_FILES := $(shell find . -name "*.c" ! -path "./build/*" ! -path "./xcode/*" ! -path "./.git/*" -type f)

# Platform-specific source selection
# Priority: platform/$(PLATFORM)/ > platform/generic/ > root
define find-source
  $(firstword \
    $(wildcard platform/$(PLATFORM)/$(1)) \
    $(wildcard platform/generic/$(1)) \
    $(wildcard $(1)))
endef

# Get base names of all sources
M_BASENAMES := $(notdir $(ALL_M_FILES))
C_BASENAMES := $(notdir $(ALL_C_FILES))

# Filter out platform-specific duplicates
M_SOURCES := $(foreach src,$(M_BASENAMES),$(call find-source,$(src)))
C_SOURCES := $(foreach src,$(C_BASENAMES),$(call find-source,$(src)))

# For early platforms, prefer _Tiger or _OpenSSL variants
ifeq ($(NEEDS_OPENSSL),yes)
  # Use Tiger-specific versions if available
  M_SOURCES := $(subst ClaudeAPIManager.m,ClaudeAPIManager_Tiger.m,$(M_SOURCES))
  M_SOURCES := $(subst HTTPSClient.m,HTTPSClient_OpenSSL.m,$(M_SOURCES))
  M_SOURCES := $(subst ThemeColors.m,ThemeColors_Tiger.m,$(M_SOURCES))
  M_SOURCES := $(subst NetworkManager.m,NetworkManager_Tiger.m,$(M_SOURCES))

  # Remove standard versions to avoid duplicates
  M_SOURCES := $(filter-out %/ClaudeAPIManager.m,$(M_SOURCES))
  M_SOURCES := $(filter-out %/HTTPSClient.m,$(M_SOURCES))
  M_SOURCES := $(filter-out %/ThemeColors.m,$(M_SOURCES))
  M_SOURCES := $(filter-out %/NetworkManager.m,$(M_SOURCES))
endif

# Generate object file names
M_OBJECTS := $(addprefix $(BUILD_DIR)/,$(notdir $(M_SOURCES:.m=.o)))
C_OBJECTS := $(addprefix $(BUILD_DIR)/,$(notdir $(C_SOURCES:.c=.o)))
OBJECTS = $(M_OBJECTS) $(C_OBJECTS)


################################################################################
# MARK: - Build Rules
################################################################################

.PHONY: all clean run debug info xcode

all: info app

info:
	@echo "=========================================="
	@echo "Building $(APP_NAME) v$(VERSION)"
	@echo "=========================================="
	@echo "Platform:      $(PLATFORM)"
	@echo "OS Version:    $(OS_VERSION)"
	@echo "Architecture:  $(ARCH)"
	@echo "Min OS:        $(MIN_OS_VERSION)"
	@echo "OpenSSL:       $(NEEDS_OPENSSL)"
	@echo "Compiler:      $(CC)"
	@echo "=========================================="
	@echo ""

# Create build directory
$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

# Create app bundle structure
$(APP_BUNDLE): | $(BUILD_DIR)
	@mkdir -p $(MACOS_DIR)
	@mkdir -p $(RESOURCES_DIR)

# Build executable
$(MACOS_DIR)/$(APP_NAME): $(OBJECTS) | $(APP_BUNDLE)
	@echo "Linking $(APP_NAME)..."
	$(OBJC) $(OBJCFLAGS) $(SDKFLAGS) $(FRAMEWORKS) $(OPENSSL_LDFLAGS) -o $@ $(OBJECTS)
	@echo "Build complete: $@"

# Compile Objective-C files
$(BUILD_DIR)/%.o: %.m | $(BUILD_DIR)
	@echo "Compiling $<..."
	$(OBJC) $(OBJCFLAGS) $(SDKFLAGS) $(OPENSSL_CFLAGS) -c $< -o $@

# Compile C files
$(BUILD_DIR)/%.o: %.c | $(BUILD_DIR)
	@echo "Compiling $<..."
	$(CC) $(CFLAGS) $(SDKFLAGS) $(OPENSSL_CFLAGS) -c $< -o $@

# Create Info.plist
$(CONTENTS_DIR)/Info.plist: Info.plist | $(APP_BUNDLE)
	@echo "Copying Info.plist..."
	@sed -e 's/\(CFBundleExecutable.*\)<string>.*<\/string>/\1<string>$(APP_NAME)<\/string>/' \
	     -e 's/\(LSMinimumSystemVersion.*\)<string>.*<\/string>/\1<string>$(MIN_OS_VERSION)<\/string>/' \
	     -e 's/\(CFBundleShortVersionString.*\)<string>.*<\/string>/\1<string>$(VERSION)<\/string>/' \
	     -e 's/\(CFBundleVersion.*\)<string>.*<\/string>/\1<string>$(BUILD_NUMBER)<\/string>/' \
	     $< > $@

# Build app
app: $(MACOS_DIR)/$(APP_NAME) $(CONTENTS_DIR)/Info.plist
	@echo ""
	@echo "=========================================="
	@echo "✓ Build successful!"
	@echo "=========================================="
	@echo "Application: $(APP_BUNDLE)"
	@echo ""

# Run the app
run: app
	@echo "Launching $(APP_NAME)..."
	@open $(APP_BUNDLE)

# Clean build files
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	@rm -f *.o
	@echo "Clean complete."

# Debug build
debug: CFLAGS += -g -DDEBUG
debug: OBJCFLAGS += -g -DDEBUG
debug: app

# Generate Xcode project
xcode:
	@echo "Generating Xcode project for $(PLATFORM)..."
	@./tools/generate-xcode.sh $(PLATFORM)

# Show detected sources
sources:
	@echo "Objective-C sources:"
	@for src in $(M_SOURCES); do echo "  $$src"; done
	@echo ""
	@echo "C sources:"
	@for src in $(C_SOURCES); do echo "  $$src"; done
	@echo ""
	@echo "Object files:"
	@for obj in $(OBJECTS); do echo "  $$obj"; done

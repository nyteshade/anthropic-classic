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
VERSION = 1.2.2
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
  else
    ifeq ($(OS_MINOR),5)
      PLATFORM = leopard
      MIN_OS_VERSION = 10.5
      NEEDS_OPENSSL = yes
    else
      ifeq ($(OS_MINOR),6)
        PLATFORM = snow
        MIN_OS_VERSION = 10.6
        NEEDS_OPENSSL = yes
      else
        ifeq ($(OS_MINOR),7)
          PLATFORM = lion
          MIN_OS_VERSION = 10.7
          NEEDS_OPENSSL = yes
        else
          ifeq ($(OS_MINOR),8)
            PLATFORM = mountain
            MIN_OS_VERSION = 10.8
            NEEDS_OPENSSL = yes
          else
            PLATFORM = modern
            MIN_OS_VERSION = 10.9
            NEEDS_OPENSSL = no
          endif
        endif
      endif
    endif
  endif
else
  # macOS 11+
  PLATFORM = modern
  MIN_OS_VERSION = 11.0
  NEEDS_OPENSSL = no
endif

# PowerPC detection - don't override platform, just note it
# Check for "ppc", "powerpc", or "Power" in architecture string
IS_PPC = no
ifneq (,$(findstring ppc,$(ARCH)))
  IS_PPC = yes
endif
ifneq (,$(findstring powerpc,$(ARCH)))
  IS_PPC = yes
endif
ifneq (,$(findstring Power,$(ARCH)))
  IS_PPC = yes
endif
ifeq ($(IS_PPC),yes)
  # PowerPC systems need OpenSSL regardless of OS version
  NEEDS_OPENSSL = yes
endif


################################################################################
# MARK: - Compiler Configuration
################################################################################

# Detect available GCC compiler
# Try in order: gcc-apple-4.2, gcc-4.2, gcc-4.0, gcc
GCC_APPLE_42 := $(shell which gcc-apple-4.2 2>/dev/null)
GCC_42 := $(shell which gcc-4.2 2>/dev/null)
GCC_40 := $(shell which gcc-4.0 2>/dev/null)

ifneq ($(GCC_APPLE_42),)
  GCC_COMPILER = gcc-apple-4.2
  GCC_VERSION = 4.2
else
  ifneq ($(GCC_42),)
    GCC_COMPILER = gcc-4.2
    GCC_VERSION = 4.2
  else
    ifneq ($(GCC_40),)
      GCC_COMPILER = gcc-4.0
      GCC_VERSION = 4.0
    else
      GCC_COMPILER = gcc
      GCC_VERSION = unknown
    endif
  endif
endif

# Set architecture flags based on actual CPU architecture
# PowerPC doesn't use -arch flags (or uses -arch ppc/ppc64)
# Intel uses -arch x86_64 or -arch i386
ifeq ($(IS_PPC),yes)
  # PowerPC - no arch flags needed for single architecture builds
  ARCH_FLAGS =
else
  # Intel - use x86_64 for 64-bit
  ifeq ($(ARCH),x86_64)
    ARCH_FLAGS = -arch x86_64
  else
    ifeq ($(ARCH),i386)
      ARCH_FLAGS = -arch i386
    else
      # Default to x86_64 for Intel
      ARCH_FLAGS = -arch x86_64
    endif
  endif
endif

# Select compiler based on platform
ifeq ($(PLATFORM),tiger)
  CC = $(GCC_COMPILER)
  OBJC = $(CC)
else
  ifeq ($(PLATFORM),leopard)
    CC = $(GCC_COMPILER)
    OBJC = $(CC)
  else
    ifeq ($(PLATFORM),snow)
      CC = $(GCC_COMPILER)
      OBJC = $(CC)
    else
      ifeq ($(PLATFORM),lion)
        CC = $(GCC_COMPILER)
        OBJC = $(CC)
      else
        ifeq ($(PLATFORM),mountain)
          CC = $(GCC_COMPILER)
          OBJC = $(CC)
        else
          # Modern platforms (10.9+) - use clang
          CC = clang
          OBJC = clang
        endif
      endif
    endif
  endif
endif

# Base compiler flags
# NOTE: We use manual reference counting (MRC) via SAFEArc.h for compatibility
#       ARC was introduced in OS X 10.7 Lion, so we disable it on modern compilers
# NOTE: gcc-4.0 and gcc-4.2 don't support -fno-objc-arc (ARC didn't exist yet)
# NOTE: gcc-4.0 doesn't support -std=c99, use -std=gnu99 or omit
# Add -MMD -MP for automatic dependency generation (only recompile what changed)
ifeq ($(GCC_VERSION),4.0)
  CFLAGS = -Wall -O2 $(ARCH_FLAGS) -MMD -MP
  OBJCFLAGS = -Wall -O2 -ObjC $(ARCH_FLAGS) -MMD -MP
else
  ifeq ($(CC),clang)
    # Clang supports -fno-objc-arc, use it to explicitly disable ARC
    CFLAGS = -Wall -O2 -std=c99 $(ARCH_FLAGS) -MMD -MP
    OBJCFLAGS = -Wall -O2 -ObjC -fno-objc-arc $(ARCH_FLAGS) -MMD -MP
  else
    # GCC 4.2 and earlier don't have ARC, so no flag needed
    CFLAGS = -Wall -O2 -std=c99 $(ARCH_FLAGS) -MMD -MP
    OBJCFLAGS = -Wall -O2 -ObjC $(ARCH_FLAGS) -MMD -MP
  endif
endif

# SDK flags
# Note: -mmacosx-version-min not supported on Tiger's gcc-4.2
# Only use on platforms where it's supported (10.5+)
ifeq ($(PLATFORM),tiger)
  SDKFLAGS =
else
  SDKFLAGS = -mmacosx-version-min=$(MIN_OS_VERSION)
endif

# Framework flags
FRAMEWORKS = -framework Cocoa -framework Foundation

# OpenSSL configuration (for early platforms)
ifeq ($(NEEDS_OPENSSL),yes)
  # Check multiple possible OpenSSL locations
  # Priority: /usr/local (Homebrew/manual), /opt/local (MacPorts), /opt/homebrew (M1 Homebrew)

  OPENSSL_PREFIX :=

  ifeq ($(shell test -f /usr/local/include/openssl/ssl.h && echo yes),yes)
    OPENSSL_PREFIX = /usr/local
  else
    ifeq ($(shell test -f /opt/local/include/openssl/ssl.h && echo yes),yes)
      OPENSSL_PREFIX = /opt/local
    else
      ifeq ($(shell test -f /opt/homebrew/include/openssl/ssl.h && echo yes),yes)
        OPENSSL_PREFIX = /opt/homebrew
      endif
    endif
  endif

  ifneq ($(OPENSSL_PREFIX),)
    OPENSSL_CFLAGS = -I$(OPENSSL_PREFIX)/include
    # Use explicit library paths and prioritize our OpenSSL over system libraries
    # -Wl,-search_paths_first ensures our -L path is searched before system paths
    OPENSSL_LDFLAGS = -Wl,-search_paths_first -L$(OPENSSL_PREFIX)/lib -lssl -lcrypto
  else
    OPENSSL_CFLAGS =
    OPENSSL_LDFLAGS =
    $(warning )
    $(warning WARNING: OpenSSL not found!)
    $(warning For OS X $(OS_MAJOR).$(OS_MINOR), you need OpenSSL.)
    $(warning Install with: sudo port install openssl   OR   brew install openssl)
    $(warning Common locations: /usr/local, /opt/local, /opt/homebrew)
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

# Find all .m files, excluding build, xcode directories, and variant files
# Variant files (*_OpenSSL.m, *_Tiger.m) are excluded here and selected via substitution below
ALL_M_FILES := $(shell find . -name "*.m" \
  ! -path "./build/*" \
  ! -path "./xcode/*" \
  ! -path "./.git/*" \
  ! -name "*_OpenSSL.m" \
  ! -name "*_Tiger.m" \
  -type f)

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

# For early platforms, prefer _OpenSSL and _Tiger variants where they exist
# Note: ClaudeAPIManager.m and ThemeColors.m are already Tiger-compatible via
#       conditional compilation, so no _Tiger variants are needed
ifeq ($(NEEDS_OPENSSL),yes)
  # Use OpenSSL version for HTTPS client (required for Tiger-Mountain Lion)
  M_SOURCES := $(subst HTTPSClient.m,HTTPSClient_OpenSSL.m,$(M_SOURCES))
  M_SOURCES := $(filter-out %HTTPSClient.m ./HTTPSClient.m,$(M_SOURCES))

  # Use Tiger-specific NetworkManager if it exists
  M_SOURCES := $(subst NetworkManager.m,NetworkManager_Tiger.m,$(M_SOURCES))
  M_SOURCES := $(filter-out %NetworkManager.m ./NetworkManager.m,$(M_SOURCES))

  # ClaudeAPIManager.m works on all platforms (no substitution needed)
  # ThemeColors.m works on all platforms with conditional compilation (no substitution needed)
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
ifeq ($(IS_PPC),yes)
	@echo "CPU Type:      PowerPC"
else
	@echo "CPU Type:      Intel"
endif
	@echo "Arch Flags:    $(ARCH_FLAGS)"
	@echo "Min OS:        $(MIN_OS_VERSION)"
ifeq ($(NEEDS_OPENSSL),yes)
	@echo "OpenSSL:       $(NEEDS_OPENSSL) ($(OPENSSL_PREFIX))"
else
	@echo "OpenSSL:       $(NEEDS_OPENSSL)"
endif
	@echo "Compiler:      $(CC)"
ifneq ($(GCC_VERSION),unknown)
	@echo "GCC Version:   $(GCC_VERSION)"
endif
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
	$(OBJC) $(OBJCFLAGS) $(SDKFLAGS) -o $@ $(OBJECTS) $(FRAMEWORKS) $(OPENSSL_LDFLAGS)
	@chmod +x $@
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
	@perl -pe 'BEGIN{undef $$/;} \
	           s/(<key>LSMinimumSystemVersion<\/key>\s*<string>)[^<]*(<\/string>)/$$1$(MIN_OS_VERSION)$$2/s; \
	           s/(<key>CFBundleShortVersionString<\/key>\s*<string>)[^<]*(<\/string>)/$$1$(VERSION)$$2/s; \
	           s/(<key>CFBundleVersion<\/key>\s*<string>)[^<]*(<\/string>)/$$1$(BUILD_NUMBER)$$2/s' \
	    $< > $@

# Create PkgInfo
$(CONTENTS_DIR)/PkgInfo: | $(APP_BUNDLE)
	@echo "Creating PkgInfo..."
	@echo -n "APPL????" > $@

# Extract icon file from zip to preserve attributes
$(RESOURCES_DIR)/ClaudeClassic.icns: ClaudeClassic.icns.zip | $(APP_BUNDLE)
	@echo "Extracting icon from zip..."
	@unzip -o ClaudeClassic.icns.zip -d $(RESOURCES_DIR)
	@touch $(RESOURCES_DIR)/ClaudeClassic.icns
	@touch $(APP_BUNDLE)
	@echo "Resetting icon cache (this may take a moment)..."
	@-/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -kill -r -domain local -domain system -domain user 2>/dev/null || true
	@-killall Finder 2>/dev/null || true

# Build app
app: $(MACOS_DIR)/$(APP_NAME) $(CONTENTS_DIR)/Info.plist $(CONTENTS_DIR)/PkgInfo $(RESOURCES_DIR)/ClaudeClassic.icns
	@echo ""
	@echo "=========================================="
	@echo "✓ Build successful!"
	@echo "=========================================="
	@echo "Application: $(APP_BUNDLE)"
	@echo ""
	@echo "Bundle structure:"
	@ls -la $(MACOS_DIR)/
	@echo ""
	@echo "Info.plist executable name:"
	@grep -A1 CFBundleExecutable $(CONTENTS_DIR)/Info.plist | tail -1
	@echo ""

# Run the app
run: app
	@echo "Launching $(APP_NAME)..."
	@open $(APP_BUNDLE)

# Clean build files
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	@rm -f *.o *.d
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

# Include auto-generated dependency files
# The - prefix means don't error if files don't exist yet (first build)
-include $(OBJECTS:.o=.d)

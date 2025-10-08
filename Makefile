# Makefile for ClaudeChat
# Compatible with OS X Tiger and later

APP_NAME = ClaudeChat
BUNDLE_ID = com.example.claudechat

# Source files
SOURCES = main.m \
          NEPadding.m \
          NSView+Essentials.m \
					NSObject+Associations.m \
          AppDelegate.m \
          ChatWindowController.m \
          ClaudeAPIManager_Tiger.m \
          NetworkManager_Tiger.m \
          HTTPSClient.m \
          ThemeColors.m \
          ThemedView.m \
          ConversationManager.m \
          CodeBlockView.m

C_SOURCES = yyjson.c

HEADERS = AppDelegate.h \
          ChatWindowController.h \
          ClaudeAPIManager.h \
          HTTPSClient.h \
          CodeBlockView.h

# Compiler settings
CC = clang
OBJC = $(CC)
CFLAGS = -Wall -O2
OBJCFLAGS = $(CFLAGS) -ObjC

# Framework flags
FRAMEWORKS = -framework Cocoa -framework Foundation

# Target SDK (use 10.4 for Tiger compatibility if available)
# You can override this with: make MACOSX_DEPLOYMENT_TARGET=10.4
MACOSX_DEPLOYMENT_TARGET ?= 10.6
SDKFLAGS = -mmacosx-version-min=$(MACOSX_DEPLOYMENT_TARGET)

# Build directories
BUILD_DIR = build
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
CONTENTS_DIR = $(APP_BUNDLE)/Contents
MACOS_DIR = $(CONTENTS_DIR)/MacOS
RESOURCES_DIR = $(CONTENTS_DIR)/Resources

# Object files
OBJECTS = $(SOURCES:.m=.o) $(C_SOURCES:.c=.o)

# Default target
all: app

# Create app bundle structure
$(APP_BUNDLE):
	@mkdir -p $(MACOS_DIR)
	@mkdir -p $(RESOURCES_DIR)

# Build executable
$(MACOS_DIR)/$(APP_NAME): $(OBJECTS) | $(APP_BUNDLE)
	$(OBJC) $(OBJCFLAGS) $(SDKFLAGS) $(FRAMEWORKS) -o $@ $(OBJECTS)

# Compile Objective-C source files
%.o: %.m $(HEADERS)
	$(OBJC) $(OBJCFLAGS) $(SDKFLAGS) -c $< -o $@

# Compile C source files
%.o: %.c
	$(CC) $(CFLAGS) $(SDKFLAGS) -c $< -o $@

# Create Info.plist
$(CONTENTS_DIR)/Info.plist: | $(APP_BUNDLE)
	@echo '<?xml version="1.0" encoding="UTF-8"?>' > $@
	@echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $@
	@echo '<plist version="1.0">' >> $@
	@echo '<dict>' >> $@
	@echo '    <key>CFBundleExecutable</key>' >> $@
	@echo '    <string>$(APP_NAME)</string>' >> $@
	@echo '    <key>CFBundleIdentifier</key>' >> $@
	@echo '    <string>$(BUNDLE_ID)</string>' >> $@
	@echo '    <key>CFBundleName</key>' >> $@
	@echo '    <string>$(APP_NAME)</string>' >> $@
	@echo '    <key>CFBundlePackageType</key>' >> $@
	@echo '    <string>APPL</string>' >> $@
	@echo '    <key>CFBundleShortVersionString</key>' >> $@
	@echo '    <string>1.0</string>' >> $@
	@echo '    <key>CFBundleVersion</key>' >> $@
	@echo '    <string>1</string>' >> $@
	@echo '    <key>LSMinimumSystemVersion</key>' >> $@
	@echo '    <string>$(MACOSX_DEPLOYMENT_TARGET)</string>' >> $@
	@echo '    <key>NSPrincipalClass</key>' >> $@
	@echo '    <string>NSApplication</string>' >> $@
	@echo '</dict>' >> $@
	@echo '</plist>' >> $@

# Build app
app: $(MACOS_DIR)/$(APP_NAME) $(CONTENTS_DIR)/Info.plist

# Run the app
run: app
	open $(APP_BUNDLE)

# Clean build files
clean:
	rm -rf $(BUILD_DIR)
	rm -f *.o

# Build for Tiger/PowerPC (use Makefile.tiger instead)
tiger:
	@echo "Use 'make -f Makefile.tiger' for Tiger/PowerPC builds"

# Build with debugging symbols
debug: CFLAGS += -g -DDEBUG
debug: app

.PHONY: all app run clean tiger debug
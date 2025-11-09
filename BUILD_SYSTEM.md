# ClaudeChat Build System

Modern, intelligent build system for Mac OS X 10.4 Tiger through modern macOS.

## Features

- **Auto-Discovery**: Automatically finds all `.m` and `.c` files
- **Platform Detection**: Detects OS version and selects appropriate compiler/settings
- **Platform-Specific Sources**: Uses `platform/<os>/` or `platform/generic/` for variants
- **No Manual Maintenance**: Add new files and build - no Makefile edits needed
- **Xcode Generation**: Creates platform-specific Xcode projects on demand
- **Cross-Version Compatible**: Single Makefile works from Tiger to modern macOS

## Quick Start

```bash
# Build for current platform
make

# Build and run
make run

# Build with debug symbols
make debug

# Clean build artifacts
make clean

# Show detected sources and configuration
make sources

# Generate Xcode project for current platform
make xcode
```

## Platform Detection

The build system automatically detects your platform and configures appropriately:

| Platform | OS Version | Compiler | OpenSSL | Min Target |
|----------|------------|----------|---------|------------|
| **tiger** | 10.4 | gcc-4.2 | MacPorts | 10.4 |
| **leopard** | 10.5 | gcc-4.2 | MacPorts | 10.5 |
| **snow** | 10.6 | gcc-4.2 | MacPorts | 10.6 |
| **lion** | 10.7 | gcc-4.2 | MacPorts | 10.7 |
| **mountain** | 10.8 | gcc-4.2 | MacPorts | 10.8 |
| **modern** | 10.9+ | clang | System | 10.9+ |

PowerPC systems automatically select Tiger platform.

## Platform-Specific Sources

For platform-specific implementations, use this directory structure:

```
platform/
├── tiger/           # OS X 10.4 specific
├── leopard/         # OS X 10.5 specific
├── snow/            # OS X 10.6 specific
├── lion/            # OS X 10.7 specific
├── mountain/        # OS X 10.8 specific
├── modern/          # OS X 10.9+ specific
└── generic/         # Fallback implementations
```

**Resolution order**:
1. `platform/<current-platform>/File.m`
2. `platform/generic/File.m`
3. `./File.m` (root directory)

### Example

```bash
# Root has generic implementation
./HTTPSClient.m

# Tiger-specific implementation (uses OpenSSL)
platform/tiger/HTTPSClient.m

# Modern uses system TLS
platform/modern/HTTPSClient.m
```

When building on Tiger, the system uses `platform/tiger/HTTPSClient.m`.
When building on modern macOS, it uses `platform/modern/HTTPSClient.m`.
On platforms without specific versions, falls back to `./HTTPSClient.m`.

## Current Implementation

Currently, platform-specific files use naming suffixes:
- `*_Tiger.m` - Tiger/Leopard/Snow Leopard variants
- `*_OpenSSL.m` - OpenSSL-based implementations

These are automatically selected on older platforms. You can gradually migrate to the `platform/` structure.

## Xcode Project Generation

Generate platform-specific Xcode projects:

```bash
# Generate for current platform
make xcode

# Or use directly
./tools/generate-xcode.sh tiger
./tools/generate-xcode.sh modern
```

This creates: `xcode/ClaudeChat-<platform>.xcodeproj/`

Each project is configured for its platform:
- Correct SDK and deployment target
- Appropriate compiler
- OpenSSL paths (if needed)
- Platform-specific source files

**Note**: Generated projects reference files in place - no copying. Edit the original sources.

## Adding New Files

Just create the file and build - no Makefile changes needed!

```bash
# Create new source file
touch NewFeature.m
touch NewFeature.h

# Build automatically includes it
make
```

For platform-specific implementations:

```bash
# Create Tiger-specific version
mkdir -p platform/tiger
touch platform/tiger/NewFeature.m

# Create modern version
mkdir -p platform/modern
touch platform/modern/NewFeature.m

# Build automatically selects correct version
make
```

## Build Configuration

### OpenSSL (Tiger through Mountain Lion)

On older platforms, you need MacPorts OpenSSL:

```bash
sudo port install openssl
```

The Makefile checks for `/opt/local/include/openssl/ssl.h` and warns if missing.

### Environment Variables

Override defaults:

```bash
# Force minimum OS version
make MIN_OS_VERSION=10.5

# Use specific compiler
make CC=clang

# Custom architecture
make ARCH_FLAGS="-arch i386"
```

## Migration from Old Makefiles

Old Makefiles (`Makefile` and `Makefile.tiger`) are replaced by the new system.

To migrate:

```bash
# Backup old files
mv Makefile Makefile.old
mv Makefile.tiger Makefile.tiger.old

# Activate new system
mv Makefile.new Makefile

# Test build
make clean
make
```

The new Makefile handles all platforms that the old ones did, plus:
- Lion (10.7)
- Mountain Lion (10.8)
- Automatic platform detection
- No manual file list maintenance

## Troubleshooting

### OpenSSL Not Found

```
WARNING: MacPorts OpenSSL not found!
```

**Solution**: Install MacPorts, then: `sudo port install openssl`

### Wrong Compiler Selected

Check detection:
```bash
make info
```

Override if needed:
```bash
make CC=gcc-4.2
```

### Source Not Found

Check source discovery:
```bash
make sources
```

Ensure files are not in excluded directories (`build/`, `xcode/`, `.git/`).

### Platform-Specific File Not Used

The build system prefers:
1. Explicit `_Tiger`/`_OpenSSL` suffixes on older platforms
2. Then checks `platform/` directories

Both methods work - use whichever fits your workflow.

## Code Style

All code should follow the project style guide:

- **Indentation**: 2 spaces (no tabs)
- **Bracing**: Opening brace on new line for functions/methods
- **Spacing**: 2 blank lines between functions
- **Documentation**: Comprehensive header comments
- **Marks**: Use `#pragma mark -` to organize code sections

See `STYLE_GUIDE.md` for details.

## Advanced Usage

### Custom Build Directory

```bash
make BUILD_DIR=mybuild
```

### Parallel Builds

```bash
make -j4
```

### Verbose Output

```bash
make VERBOSE=1
```

### Platform Override

Force build for specific platform:

```bash
# Force Tiger build on modern system (for testing)
PLATFORM=tiger make
```

## File Structure

```
.
├── Makefile                    # Smart build system
├── Info.plist                  # App bundle metadata
├── build/                      # Build artifacts (auto-created)
│   └── ClaudeChat.app/
├── platform/                   # Platform-specific sources
│   ├── generic/
│   ├── tiger/
│   ├── modern/
│   └── ...
├── tools/
│   └── generate-xcode.sh       # Xcode project generator
├── xcode/                      # Generated Xcode projects
│   ├── ClaudeChat-tiger.xcodeproj/
│   └── ClaudeChat-modern.xcodeproj/
└── *.m, *.h, *.c               # Source files
```

## Benefits Over Old System

### Old Makefiles

- ❌ Manual file list maintenance
- ❌ Separate Makefile per platform family
- ❌ Hardcoded source lists
- ❌ Xcode projects out of sync
- ❌ Easy to forget to add new files

### New System

- ✅ Automatic file discovery
- ✅ Single Makefile for all platforms
- ✅ Auto-includes new files
- ✅ Generate Xcode projects on demand
- ✅ Platform-specific source selection
- ✅ Add file and build - just works

## Questions?

Check the inline Makefile comments for implementation details. The Makefile is heavily documented.

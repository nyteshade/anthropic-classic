#!/bin/bash
################################################################################
# Xcode Project Generator
# Generates platform-specific Xcode projects from Makefile configuration
#
# Usage: ./tools/generate-xcode.sh [platform]
#   platform: tiger, leopard, snow, lion, mountain, modern (auto-detected if omitted)
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

################################################################################
# MARK: - Platform Detection
################################################################################

if [ -z "$1" ]; then
  # Auto-detect platform
  OS_VERSION=$(sw_vers -productVersion)
  OS_MAJOR=$(echo $OS_VERSION | cut -d. -f1)
  OS_MINOR=$(echo $OS_VERSION | cut -d. -f2)
  ARCH=$(uname -m)

  if [[ "$ARCH" == "ppc"* ]]; then
    PLATFORM="tiger"
  elif [ "$OS_MAJOR" -eq 10 ]; then
    case $OS_MINOR in
      4) PLATFORM="tiger" ;;
      5) PLATFORM="leopard" ;;
      6) PLATFORM="snow" ;;
      7) PLATFORM="lion" ;;
      8) PLATFORM="mountain" ;;
      *) PLATFORM="modern" ;;
    esac
  else
    PLATFORM="modern"
  fi
else
  PLATFORM="$1"
fi

echo -e "${BLUE}=========================================="
echo "Xcode Project Generator"
echo -e "==========================================${NC}"
echo "Platform: $PLATFORM"
echo ""

################################################################################
# MARK: - Configuration
################################################################################

APP_NAME="ClaudeChat"
BUNDLE_ID="com.nyteshade.anthropic-classic"
PROJECT_NAME="${APP_NAME}-${PLATFORM}"
XCODEPROJ_DIR="xcode/${PROJECT_NAME}.xcodeproj"
PBXPROJ="${XCODEPROJ_DIR}/project.pbxproj"

# Ensure xcode directory exists
mkdir -p "xcode"
mkdir -p "$XCODEPROJ_DIR"

################################################################################
# MARK: - Gather Sources
################################################################################

echo "Discovering source files..."

# Find all source files
M_FILES=$(find . -name "*.m" ! -path "./build/*" ! -path "./xcode/*" ! -path "./.git/*" -type f | sed 's|^\./||')
C_FILES=$(find . -name "*.c" ! -path "./build/*" ! -path "./xcode/*" ! -path "./.git/*" -type f | sed 's|^\./||')
H_FILES=$(find . -name "*.h" ! -path "./build/*" ! -path "./xcode/*" ! -path "./.git/*" -type f | sed 's|^\./||')

# Platform-specific filtering
case $PLATFORM in
  tiger|leopard|snow|lion|mountain)
    # Use Tiger/OpenSSL variants
    M_FILES=$(echo "$M_FILES" | grep -v "ClaudeAPIManager\.m$" || true)
    M_FILES=$(echo "$M_FILES" | grep -v "HTTPSClient\.m$" || true)
    M_FILES=$(echo "$M_FILES" | grep -v "ThemeColors\.m$" || true)
    M_FILES=$(echo -e "${M_FILES}\nClaudeAPIManager_Tiger.m\nHTTPSClient_OpenSSL.m\nThemeColors_Tiger.m")
    NEEDS_OPENSSL="yes"
    ;;
  modern)
    # Use modern variants
    M_FILES=$(echo "$M_FILES" | grep -v "_Tiger\.m$" || true)
    M_FILES=$(echo "$M_FILES" | grep -v "_OpenSSL\.m$" || true)
    NEEDS_OPENSSL="no"
    ;;
esac

# Remove duplicates and sort
M_FILES=$(echo "$M_FILES" | sort -u)
C_FILES=$(echo "$C_FILES" | sort -u)
H_FILES=$(echo "$H_FILES" | sort -u)

################################################################################
# MARK: - Generate UUIDs
################################################################################

# Simple UUID generator for older systems
generate_uuid() {
  if command -v uuidgen &> /dev/null; then
    uuidgen | tr -d '-' | tr '[:lower:]' '[:upper:]' | cut -c1-24
  else
    # Fallback for very old systems - try md5sum (Linux) or md5 (macOS)
    local hash_input="$(date +%s%N)$(od -An -N4 -tu4 /dev/random 2>/dev/null | tr -d ' ')"
    if command -v md5sum &> /dev/null; then
      echo "$hash_input" | md5sum | cut -d' ' -f1 | tr '[:lower:]' '[:upper:]' | cut -c1-24
    elif command -v md5 &> /dev/null; then
      echo "$hash_input" | md5 | tr '[:lower:]' '[:upper:]' | cut -c1-24
    elif [ -x /sbin/md5 ]; then
      # Leopard/Tiger has md5 in /sbin
      echo "$hash_input" | /sbin/md5 | tr '[:lower:]' '[:upper:]' | cut -c1-24
    else
      # Last resort: use od to generate pseudo-random hex
      echo "$hash_input" | od -An -tx1 | tr -d ' \n' | tr '[:lower:]' '[:upper:]' | cut -c1-24
    fi
  fi
}

PROJECT_UUID=$(generate_uuid)
MAINGROUP_UUID=$(generate_uuid)
PRODUCTS_GROUP_UUID=$(generate_uuid)
SOURCES_GROUP_UUID=$(generate_uuid)
HEADERS_GROUP_UUID=$(generate_uuid)
RESOURCES_GROUP_UUID=$(generate_uuid)
TARGET_UUID=$(generate_uuid)
BUILDCONFIG_DEBUG_UUID=$(generate_uuid)
BUILDCONFIG_RELEASE_UUID=$(generate_uuid)
BUILDCONFIG_LIST_UUID=$(generate_uuid)
FRAMEWORKS_BUILDPHASE_UUID=$(generate_uuid)
SOURCES_BUILDPHASE_UUID=$(generate_uuid)
RESOURCES_BUILDPHASE_UUID=$(generate_uuid)
PRODUCT_REF_UUID=$(generate_uuid)

################################################################################
# MARK: - Generate File References
################################################################################

echo "Generating project structure..."

file_refs=""
source_file_refs=""
header_file_refs=""
build_file_refs=""
sources_build_refs=""

# Helper to generate file reference
gen_file_ref() {
  local file="$1"
  local filetype="$2"
  local uuid=$(generate_uuid)

  file_refs="${file_refs}
		${uuid} /* ${file} */ = {isa = PBXFileReference; lastKnownFileType = ${filetype}; path = ${file}; sourceTree = \"<group>\"; };"

  echo "$uuid"
}

# Helper to generate build file reference
gen_build_ref() {
  local file_uuid="$1"
  local uuid=$(generate_uuid)

  build_file_refs="${build_file_refs}
		${uuid} /* Build */ = {isa = PBXBuildFile; fileRef = ${file_uuid}; };"

  echo "$uuid"
}

# Process source files
while IFS= read -r file; do
  [ -z "$file" ] && continue
  file_uuid=$(gen_file_ref "$file" "sourcecode.c.objc")
  build_uuid=$(gen_build_ref "$file_uuid")
  source_file_refs="${source_file_refs}
				${file_uuid} /* ${file} */,"
  sources_build_refs="${sources_build_refs}
				${build_uuid} /* ${file} */,"
done <<< "$M_FILES"

# Process C files
while IFS= read -r file; do
  [ -z "$file" ] && continue
  file_uuid=$(gen_file_ref "$file" "sourcecode.c.c")
  build_uuid=$(gen_build_ref "$file_uuid")
  source_file_refs="${source_file_refs}
				${file_uuid} /* ${file} */,"
  sources_build_refs="${sources_build_refs}
				${build_uuid} /* ${file} */,"
done <<< "$C_FILES"

# Process header files
while IFS= read -r file; do
  [ -z "$file" ] && continue
  file_uuid=$(gen_file_ref "$file" "sourcecode.c.h")
  header_file_refs="${header_file_refs}
				${file_uuid} /* ${file} */,"
done <<< "$H_FILES"

# Info.plist reference
INFOPLIST_UUID=$(gen_file_ref "Info.plist" "text.plist.xml")

################################################################################
# MARK: - Set Platform-Specific Build Settings
################################################################################

case $PLATFORM in
  tiger)
    SDK_VERSION="10.4"
    COMPILER="com.apple.compilers.gcc.4_2"
    ARCHS="ppc i386"
    XCODE_VERSION="Xcode 2.5"
    OBJECT_VERSION="42"
    ;;
  leopard)
    SDK_VERSION="10.5"
    COMPILER="com.apple.compilers.gcc.4_2"
    ARCHS="i386 x86_64"
    XCODE_VERSION="Xcode 3.1"
    OBJECT_VERSION="45"
    ;;
  snow)
    SDK_VERSION="10.6"
    COMPILER="com.apple.compilers.gcc.4_2"
    ARCHS="i386 x86_64"
    XCODE_VERSION="Xcode 3.2"
    OBJECT_VERSION="46"
    ;;
  lion)
    SDK_VERSION="10.7"
    COMPILER="com.apple.compilers.llvm.clang.1_0"
    ARCHS="x86_64"
    XCODE_VERSION="Xcode 3.2"
    OBJECT_VERSION="46"
    ;;
  mountain)
    SDK_VERSION="10.8"
    COMPILER="com.apple.compilers.llvm.clang.1_0"
    ARCHS="x86_64"
    XCODE_VERSION="Xcode 3.2"
    OBJECT_VERSION="46"
    ;;
  modern)
    SDK_VERSION="10.9"
    COMPILER="com.apple.compilers.llvm.clang.1_0"
    ARCHS="x86_64"
    XCODE_VERSION="Xcode 3.2"
    OBJECT_VERSION="46"
    ;;
esac

# OpenSSL settings
if [ "$NEEDS_OPENSSL" = "yes" ]; then
  HEADER_SEARCH_PATHS="HEADER_SEARCH_PATHS = /opt/local/include;"
  LIBRARY_SEARCH_PATHS="LIBRARY_SEARCH_PATHS = /opt/local/lib;"
  OTHER_LDFLAGS='OTHER_LDFLAGS = "-lssl -lcrypto";'
else
  HEADER_SEARCH_PATHS=""
  LIBRARY_SEARCH_PATHS=""
  OTHER_LDFLAGS=""
fi

# ARC settings (only for Snow Leopard and later)
# Tiger and Leopard (Xcode 2.5/3.1) don't recognize these settings
case $PLATFORM in
  tiger|leopard)
    # Old Xcode - no ARC settings
    ARC_SETTINGS=""
    ;;
  *)
    # Xcode 3.2+ - explicitly disable ARC
    ARC_SETTINGS="CLANG_ENABLE_OBJC_ARC = NO;
				OTHER_CFLAGS = \"-fno-objc-arc\";"
    ;;
esac

################################################################################
# MARK: - Generate project.pbxproj
################################################################################

cat > "$PBXPROJ" << EOF
// !\$!*UTF8*\$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = ${OBJECT_VERSION};
	objects = {

/* Begin PBXBuildFile section */
${build_file_refs}
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
${file_refs}
		${PRODUCT_REF_UUID} /* ${APP_NAME}.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = ${APP_NAME}.app; sourceTree = BUILT_PRODUCTS_DIR; };
		${INFOPLIST_UUID} /* Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = \"<group>\"; };
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		${FRAMEWORKS_BUILDPHASE_UUID} /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		${MAINGROUP_UUID} /* Main */ = {
			isa = PBXGroup;
			children = (
				${SOURCES_GROUP_UUID} /* Sources */,
				${HEADERS_GROUP_UUID} /* Headers */,
				${RESOURCES_GROUP_UUID} /* Resources */,
				${PRODUCTS_GROUP_UUID} /* Products */,
			);
			sourceTree = \"<group>\";
		};
		${PRODUCTS_GROUP_UUID} /* Products */ = {
			isa = PBXGroup;
			children = (
				${PRODUCT_REF_UUID} /* ${APP_NAME}.app */,
			);
			name = Products;
			sourceTree = \"<group>\";
		};
		${SOURCES_GROUP_UUID} /* Sources */ = {
			isa = PBXGroup;
			children = (${source_file_refs}
			);
			name = Sources;
			sourceTree = \"<group>\";
		};
		${HEADERS_GROUP_UUID} /* Headers */ = {
			isa = PBXGroup;
			children = (${header_file_refs}
			);
			name = Headers;
			sourceTree = \"<group>\";
		};
		${RESOURCES_GROUP_UUID} /* Resources */ = {
			isa = PBXGroup;
			children = (
				${INFOPLIST_UUID} /* Info.plist */,
			);
			name = Resources;
			sourceTree = \"<group>\";
		};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		${TARGET_UUID} /* ${APP_NAME} */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = ${BUILDCONFIG_LIST_UUID} /* Build configuration list for PBXNativeTarget "${APP_NAME}" */;
			buildPhases = (
				${SOURCES_BUILDPHASE_UUID} /* Sources */,
				${FRAMEWORKS_BUILDPHASE_UUID} /* Frameworks */,
				${RESOURCES_BUILDPHASE_UUID} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = ${APP_NAME};
			productName = ${APP_NAME};
			productReference = ${PRODUCT_REF_UUID} /* ${APP_NAME}.app */;
			productType = \"com.apple.product-type.application\";
		};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		${PROJECT_UUID} /* Project object */ = {
			isa = PBXProject;
			buildConfigurationList = ${BUILDCONFIG_LIST_UUID} /* Build configuration list for PBXProject "${PROJECT_NAME}" */;
			compatibilityVersion = \"${XCODE_VERSION}\";
			developmentRegion = English;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
			);
			mainGroup = ${MAINGROUP_UUID} /* Main */;
			productRefGroup = ${PRODUCTS_GROUP_UUID} /* Products */;
			projectDirPath = \"\";
			projectRoot = \"\";
			targets = (
				${TARGET_UUID} /* ${APP_NAME} */,
			);
		};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		${RESOURCES_BUILDPHASE_UUID} /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		${SOURCES_BUILDPHASE_UUID} /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (${sources_build_refs}
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		${BUILDCONFIG_DEBUG_UUID} /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ARCHS = "${ARCHS}";
				${ARC_SETTINGS}
				GCC_C_LANGUAGE_STANDARD = c99;
				GCC_GENERATE_DEBUGGING_SYMBOLS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = DEBUG=1;
				GCC_WARN_ABOUT_RETURN_TYPE = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				${HEADER_SEARCH_PATHS}
				INFOPLIST_FILE = Info.plist;
				${LIBRARY_SEARCH_PATHS}
				MACOSX_DEPLOYMENT_TARGET = ${SDK_VERSION};
				ONLY_ACTIVE_ARCH = YES;
				${OTHER_LDFLAGS}
				PRODUCT_NAME = ${APP_NAME};
				SDKROOT = macosx;
			};
			name = Debug;
		};
		${BUILDCONFIG_RELEASE_UUID} /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ARCHS = "${ARCHS}";
				${ARC_SETTINGS}
				GCC_C_LANGUAGE_STANDARD = c99;
				GCC_WARN_ABOUT_RETURN_TYPE = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				${HEADER_SEARCH_PATHS}
				INFOPLIST_FILE = Info.plist;
				${LIBRARY_SEARCH_PATHS}
				MACOSX_DEPLOYMENT_TARGET = ${SDK_VERSION};
				${OTHER_LDFLAGS}
				PRODUCT_NAME = ${APP_NAME};
				SDKROOT = macosx;
			};
			name = Release;
		};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		${BUILDCONFIG_LIST_UUID} /* Build configuration list */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				${BUILDCONFIG_DEBUG_UUID} /* Debug */,
				${BUILDCONFIG_RELEASE_UUID} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
/* End XCConfigurationList section */
	};
	rootObject = ${PROJECT_UUID} /* Project object */;
}
EOF

echo -e "${GREEN}✓ Generated ${XCODEPROJ_DIR}${NC}"
echo ""
echo "To open in Xcode:"
echo "  open ${XCODEPROJ_DIR}"
echo ""

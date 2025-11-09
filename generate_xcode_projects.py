#!/usr/bin/env python3
"""
Generate Xcode projects for ClaudeChat across multiple OS X/macOS versions.
This script creates Xcode project files with relative paths that work across different systems.
"""

import os
import uuid
import sys

def generate_uuid():
    """Generate a unique identifier for Xcode project items."""
    return ''.join(str(uuid.uuid4()).upper().split('-'))[:24]

class XcodeProject:
    """Generator for Xcode project files (.pbxproj)."""

    def __init__(self, project_name, target_os, deployment_target):
        self.project_name = project_name
        self.target_os = target_os
        self.deployment_target = deployment_target
        self.file_refs = {}
        self.build_files = {}
        self.source_files = []
        self.resource_files = []

    def add_source_file(self, filename, relative_path="../.."):
        """Add a source file to the project."""
        file_uuid = generate_uuid()
        build_uuid = generate_uuid()

        file_type = "sourcecode.c.objc" if filename.endswith('.m') else "sourcecode.c.c"
        if filename.endswith('.h'):
            file_type = "sourcecode.c.h"

        self.file_refs[file_uuid] = {
            'isa': 'PBXFileReference',
            'lastKnownFileType': file_type,
            'name': filename,
            'path': f'{relative_path}/{filename}',
            'sourceTree': '"<group>"'
        }

        if not filename.endswith('.h'):
            self.build_files[build_uuid] = {
                'isa': 'PBXBuildFile',
                'fileRef': file_uuid
            }
            self.source_files.append(build_uuid)

    def add_resource_file(self, filename, relative_path="../.."):
        """Add a resource file to the project."""
        file_uuid = generate_uuid()
        build_uuid = generate_uuid()

        file_type = "image.icns" if filename.endswith('.icns') else "text.plist.xml"

        self.file_refs[file_uuid] = {
            'isa': 'PBXFileReference',
            'lastKnownFileType': file_type,
            'name': filename,
            'path': f'{relative_path}/{filename}',
            'sourceTree': '"<group>"'
        }

        self.build_files[build_uuid] = {
            'isa': 'PBXBuildFile',
            'fileRef': file_uuid
        }
        self.resource_files.append(build_uuid)

    def generate(self):
        """Generate the complete .pbxproj file content."""
        project_uuid = generate_uuid()
        main_group_uuid = generate_uuid()
        source_group_uuid = generate_uuid()
        products_group_uuid = generate_uuid()
        target_uuid = generate_uuid()
        build_config_list_uuid = generate_uuid()
        debug_config_uuid = generate_uuid()
        release_config_uuid = generate_uuid()
        native_target_uuid = generate_uuid()
        sources_phase_uuid = generate_uuid()
        resources_phase_uuid = generate_uuid()
        frameworks_phase_uuid = generate_uuid()
        product_ref_uuid = generate_uuid()

        # Start building the pbxproj content
        lines = [
            "// !$*UTF8*$!",
            "{",
            "\tarchiveVersion = 1;",
            "\tclasses = {",
            "\t};",
            "\tobjectVersion = 46;",
            "\tobjects = {",
            "",
            "/* Begin PBXBuildFile section */"
        ]

        # Add build files
        for build_uuid, build_data in self.build_files.items():
            file_ref = build_data['fileRef']
            filename = self.file_refs[file_ref]['name']
            lines.append(f"\t\t{build_uuid} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref} /* {filename} */; }};")

        lines.append("/* End PBXBuildFile section */")
        lines.append("")
        lines.append("/* Begin PBXFileReference section */")

        # Add file references
        for file_uuid, file_data in self.file_refs.items():
            filename = file_data['name']
            file_type = file_data['lastKnownFileType']
            path = file_data['path']
            source_tree = file_data['sourceTree']
            lines.append(f"\t\t{file_uuid} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = {file_type}; name = {filename}; path = {path}; sourceTree = {source_tree}; }};")

        # Add product reference
        lines.append(f"\t\t{product_ref_uuid} /* {self.project_name}.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = {self.project_name}.app; sourceTree = BUILT_PRODUCTS_DIR; }};")

        lines.append("/* End PBXFileReference section */")
        lines.append("")

        # Add frameworks build phase
        lines.append("/* Begin PBXFrameworksBuildPhase section */")
        lines.append(f"\t\t{frameworks_phase_uuid} /* Frameworks */ = {{")
        lines.append("\t\t\tisa = PBXFrameworksBuildPhase;")
        lines.append("\t\t\tbuildActionMask = 2147483647;")
        lines.append("\t\t\tfiles = (")
        lines.append("\t\t\t);")
        lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
        lines.append("\t\t};")
        lines.append("/* End PBXFrameworksBuildPhase section */")
        lines.append("")

        # Add groups
        lines.append("/* Begin PBXGroup section */")
        lines.append(f"\t\t{main_group_uuid} = {{")
        lines.append("\t\t\tisa = PBXGroup;")
        lines.append("\t\t\tchildren = (")
        lines.append(f"\t\t\t\t{source_group_uuid} /* Source */,")
        lines.append(f"\t\t\t\t{products_group_uuid} /* Products */,")
        lines.append("\t\t\t);")
        lines.append('\t\t\tsourceTree = "<group>";')
        lines.append("\t\t};")

        lines.append(f"\t\t{source_group_uuid} /* Source */ = {{")
        lines.append("\t\t\tisa = PBXGroup;")
        lines.append("\t\t\tchildren = (")
        for file_uuid in self.file_refs.keys():
            filename = self.file_refs[file_uuid]['name']
            lines.append(f"\t\t\t\t{file_uuid} /* {filename} */,")
        lines.append("\t\t\t);")
        lines.append('\t\t\tname = Source;')
        lines.append('\t\t\tsourceTree = "<group>";')
        lines.append("\t\t};")

        lines.append(f"\t\t{products_group_uuid} /* Products */ = {{")
        lines.append("\t\t\tisa = PBXGroup;")
        lines.append("\t\t\tchildren = (")
        lines.append(f"\t\t\t\t{product_ref_uuid} /* {self.project_name}.app */,")
        lines.append("\t\t\t);")
        lines.append('\t\t\tname = Products;')
        lines.append('\t\t\tsourceTree = "<group>";')
        lines.append("\t\t};")
        lines.append("/* End PBXGroup section */")
        lines.append("")

        # Add native target
        lines.append("/* Begin PBXNativeTarget section */")
        lines.append(f"\t\t{native_target_uuid} /* {self.project_name} */ = {{")
        lines.append("\t\t\tisa = PBXNativeTarget;")
        lines.append(f"\t\t\tbuildConfigurationList = {build_config_list_uuid} /* Build configuration list for PBXNativeTarget \"{self.project_name}\" */;")
        lines.append("\t\t\tbuildPhases = (")
        lines.append(f"\t\t\t\t{sources_phase_uuid} /* Sources */,")
        lines.append(f"\t\t\t\t{frameworks_phase_uuid} /* Frameworks */,")
        lines.append(f"\t\t\t\t{resources_phase_uuid} /* Resources */,")
        lines.append("\t\t\t);")
        lines.append("\t\t\tbuildRules = (")
        lines.append("\t\t\t);")
        lines.append("\t\t\tdependencies = (")
        lines.append("\t\t\t);")
        lines.append(f'\t\t\tname = {self.project_name};')
        lines.append(f"\t\t\tproductName = {self.project_name};")
        lines.append(f"\t\t\tproductReference = {product_ref_uuid} /* {self.project_name}.app */;")
        lines.append('\t\t\tproductType = "com.apple.product-type.application";')
        lines.append("\t\t};")
        lines.append("/* End PBXNativeTarget section */")
        lines.append("")

        # Add project
        lines.append("/* Begin PBXProject section */")
        lines.append(f"\t\t{project_uuid} /* Project object */ = {{")
        lines.append("\t\t\tisa = PBXProject;")
        lines.append("\t\t\tattributes = {")
        lines.append('\t\t\t\tLastUpgradeCheck = 1200;')
        lines.append("\t\t\t};")
        lines.append(f"\t\t\tbuildConfigurationList = {build_config_list_uuid} /* Build configuration list for PBXProject \"{self.project_name}\" */;")
        lines.append('\t\t\tcompatibilityVersion = "Xcode 3.2";')
        lines.append('\t\t\tdevelopmentRegion = English;')
        lines.append('\t\t\thasScannedForEncodings = 0;')
        lines.append('\t\t\tknownRegions = (')
        lines.append('\t\t\t\ten,')
        lines.append('\t\t\t);')
        lines.append(f'\t\t\tmainGroup = {main_group_uuid};')
        lines.append(f'\t\t\tproductRefGroup = {products_group_uuid} /* Products */;')
        lines.append('\t\t\tprojectDirPath = "";')
        lines.append('\t\t\tprojectRoot = "";')
        lines.append('\t\t\ttargets = (')
        lines.append(f'\t\t\t\t{native_target_uuid} /* {self.project_name} */,')
        lines.append('\t\t\t);')
        lines.append("\t\t};")
        lines.append("/* End PBXProject section */")
        lines.append("")

        # Add resources build phase
        lines.append("/* Begin PBXResourcesBuildPhase section */")
        lines.append(f"\t\t{resources_phase_uuid} /* Resources */ = {{")
        lines.append("\t\t\tisa = PBXResourcesBuildPhase;")
        lines.append("\t\t\tbuildActionMask = 2147483647;")
        lines.append("\t\t\tfiles = (")
        for build_uuid in self.resource_files:
            lines.append(f"\t\t\t\t{build_uuid} /* Resource in Resources */,")
        lines.append("\t\t\t);")
        lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
        lines.append("\t\t};")
        lines.append("/* End PBXResourcesBuildPhase section */")
        lines.append("")

        # Add sources build phase
        lines.append("/* Begin PBXSourcesBuildPhase section */")
        lines.append(f"\t\t{sources_phase_uuid} /* Sources */ = {{")
        lines.append("\t\t\tisa = PBXSourcesBuildPhase;")
        lines.append("\t\t\tbuildActionMask = 2147483647;")
        lines.append("\t\t\tfiles = (")
        for build_uuid in self.source_files:
            lines.append(f"\t\t\t\t{build_uuid} /* Source file */,")
        lines.append("\t\t\t);")
        lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
        lines.append("\t\t};")
        lines.append("/* End PBXSourcesBuildPhase section */")
        lines.append("")

        # Add build configurations
        lines.append("/* Begin XCBuildConfiguration section */")
        lines.append(f"\t\t{debug_config_uuid} /* Debug */ = {{")
        lines.append("\t\t\tisa = XCBuildConfiguration;")
        lines.append("\t\t\tbuildSettings = {")
        lines.append('\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;')
        lines.append(f'\t\t\t\tMACOSX_DEPLOYMENT_TARGET = {self.deployment_target};')
        lines.append('\t\t\t\tCLANG_ENABLE_OBJC_ARC = NO;')
        lines.append('\t\t\t\tOTHER_CFLAGS = "-fno-objc-arc";')
        lines.append('\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";')
        lines.append('\t\t\t\tINFOPLIST_FILE = "../../Info.plist";')
        lines.append('\t\t\t\tICNS_FILE = ClaudeClassic;')
        lines.append("\t\t\t};")
        lines.append(f'\t\t\tname = Debug;')
        lines.append("\t\t};")

        lines.append(f"\t\t{release_config_uuid} /* Release */ = {{")
        lines.append("\t\t\tisa = XCBuildConfiguration;")
        lines.append("\t\t\tbuildSettings = {")
        lines.append('\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;')
        lines.append(f'\t\t\t\tMACOSX_DEPLOYMENT_TARGET = {self.deployment_target};')
        lines.append('\t\t\t\tCLANG_ENABLE_OBJC_ARC = NO;')
        lines.append('\t\t\t\tOTHER_CFLAGS = "-fno-objc-arc";')
        lines.append('\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";')
        lines.append('\t\t\t\tINFOPLIST_FILE = "../../Info.plist";')
        lines.append('\t\t\t\tICNS_FILE = ClaudeClassic;')
        lines.append("\t\t\t};")
        lines.append(f'\t\t\tname = Release;')
        lines.append("\t\t};")
        lines.append("/* End XCBuildConfiguration section */")
        lines.append("")

        # Add configuration list
        lines.append("/* Begin XCConfigurationList section */")
        lines.append(f"\t\t{build_config_list_uuid} /* Build configuration list for PBXNativeTarget \"{self.project_name}\" */ = {{")
        lines.append("\t\t\tisa = XCConfigurationList;")
        lines.append("\t\t\tbuildConfigurations = (")
        lines.append(f"\t\t\t\t{debug_config_uuid} /* Debug */,")
        lines.append(f"\t\t\t\t{release_config_uuid} /* Release */,")
        lines.append("\t\t\t);")
        lines.append("\t\t\tdefaultConfigurationIsVisible = 0;")
        lines.append('\t\t\tdefaultConfigurationName = Release;')
        lines.append("\t\t};")
        lines.append("/* End XCConfigurationList section */")

        lines.append("\t};")
        lines.append(f"\trootObject = {project_uuid} /* Project object */;")
        lines.append("}")

        return '\n'.join(lines)


def create_project_for_os(os_name, deployment_target, source_files):
    """Create Xcode project for a specific OS version."""

    project_name = "ClaudeChat"
    project_dir = f"xcode/{os_name}/{project_name}.xcodeproj"

    # Create project directory
    os.makedirs(project_dir, exist_ok=True)

    # Create project
    project = XcodeProject(project_name, os_name, deployment_target)

    # Add source files
    for src_file in source_files:
        project.add_source_file(src_file)

    # Add header files
    header_files = [
        'AppDelegate.h', 'ChatWindowController.h', 'ClaudeAPIManager.h',
        'ConversationManager.h', 'CodeBlockView.h', 'HTTPSClient.h',
        'NEDrawer.h', 'NEPadding.h', 'NESizingHelpers.h',
        'NSView+Essentials.h', 'NSObject+Associations.h', 'NSString+TextMeasure.h',
        'ThemeColors.h', 'SAFEArc.h', 'SystemInfoCollector.h',
        'NetworkManager.h', 'TigerCompat.h', 'ThemedView.h', 'yyjson.h'
    ]
    for hdr_file in header_files:
        project.add_source_file(hdr_file)

    # Add resources
    project.add_resource_file('ClaudeClassic.icns')
    project.add_resource_file('Info.plist')

    # Generate and write project file
    pbxproj_content = project.generate()
    pbxproj_path = os.path.join(project_dir, 'project.pbxproj')

    with open(pbxproj_path, 'w') as f:
        f.write(pbxproj_content)

    print(f"✓ Generated Xcode project: {project_dir}")


def main():
    """Generate all Xcode projects."""

    print("Generating Xcode projects for ClaudeChat...\n")

    # Tiger (OS X 10.4)
    tiger_sources = [
        'main.m', 'NEPadding.m', 'NSView+Essentials.m', 'NSObject+Associations.m',
        'AppDelegate.m', 'ChatWindowController.m', 'ClaudeAPIManager_Tiger.m',
        'NetworkManager_Tiger.m', 'HTTPSClient_OpenSSL.m', 'ThemeColors_Tiger.m',
        'ThemedView.m', 'ConversationManager.m', 'CodeBlockView.m',
        'SystemInfoCollector.m', 'NEDrawer.m', 'NSString+TextMeasure.m',
        'NESizingHelpers.m', 'yyjson.c'
    ]
    create_project_for_os("Tiger", "10.4", tiger_sources)

    # Snow Leopard (OS X 10.6)
    snowleopard_sources = [
        'main.m', 'NEPadding.m', 'NSView+Essentials.m', 'NSObject+Associations.m',
        'AppDelegate.m', 'ChatWindowController.m', 'ClaudeAPIManager_Tiger.m',
        'NetworkManager_Tiger.m', 'HTTPSClient_OpenSSL.m', 'ThemeColors.m',
        'ThemedView.m', 'ConversationManager.m', 'CodeBlockView.m',
        'SystemInfoCollector.m', 'NEDrawer.m', 'NSString+TextMeasure.m',
        'NESizingHelpers.m', 'yyjson.c'
    ]
    create_project_for_os("SnowLeopard", "10.6", snowleopard_sources)

    # macOS 26 (modern)
    macos26_sources = [
        'main.m', 'NEPadding.m', 'NSView+Essentials.m', 'NSObject+Associations.m',
        'AppDelegate.m', 'ChatWindowController.m', 'ClaudeAPIManager.m',
        'HTTPSClient.m', 'ThemeColors.m', 'ThemedView.m',
        'ConversationManager.m', 'CodeBlockView.m', 'SystemInfoCollector.m',
        'NEDrawer.m', 'NSString+TextMeasure.m', 'NESizingHelpers.m', 'yyjson.c'
    ]
    create_project_for_os("macOS26", "10.12", macos26_sources)

    print("\n✓ All Xcode projects generated successfully!")
    print("\nYou can now open these projects in Xcode:")
    print("  - xcode/Tiger/ClaudeChat.xcodeproj (OS X 10.4+)")
    print("  - xcode/SnowLeopard/ClaudeChat.xcodeproj (OS X 10.6+)")
    print("  - xcode/macOS26/ClaudeChat.xcodeproj (macOS 10.12+)")


if __name__ == '__main__':
    main()

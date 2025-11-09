#!/bin/bash
################################################################################
# Code Reformatting Tool
# Applies ClaudeChat style guide to Objective-C source files
#
# Usage: ./tools/reformat-code.sh <file.m>
#
# Note: This script handles mechanical formatting. Some manual cleanup may be
# needed for:
# - Variable declaration reorganization
# - Complex control flow
# - #pragma mark placement
################################################################################

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <file>"
  exit 1
fi

FILE="$1"

if [ ! -f "$FILE" ]; then
  echo "Error: File not found: $FILE"
  exit 1
fi

echo "Reformatting: $FILE"

# Create backup
cp "$FILE" "${FILE}.backup"

# Apply formatting with perl (more portable than sed for complex operations)
perl -i -pe '
  # Convert tabs to 2 spaces
  s/\t/  /g;

  # Remove trailing whitespace
  s/\s+$//;
' "$FILE"

echo "✓ Basic formatting applied"
echo "  - Converted tabs to spaces"
echo "  - Removed trailing whitespace"
echo ""
echo "Backup saved to: ${FILE}.backup"
echo ""
echo "Manual review needed for:"
echo "  - Method brace placement (should be on new line)"
echo "  - Blank lines between methods (should be 2)"
echo "  - Variable declarations (should be at top of method)"
echo "  - #pragma mark sections"
echo ""

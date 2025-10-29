#!/bin/bash
#
# find_unused_assets.sh
# Finds unused image assets in .xcassets directories
#
# This script searches for image assets in .xcassets directories
# and checks if they are referenced anywhere in the codebase.
#
# Usage:
#   ./ci_scripts/find_unused_assets.sh
#
# The script will:
#   - Scan all .xcassets directories in the project
#   - Extract all image asset names
#   - Search the codebase for references to each asset
#   - Report any assets that appear unused
#
# Exit codes:
#   0 - All assets are used
#   1 - Unused assets were found
#
# Note: Some assets may be loaded dynamically (e.g., via string interpolation
# or computed at runtime). Always verify before removing an asset.
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Change to the repository root
cd "$(dirname "$0")/.."

echo "🔍 Finding unused assets in .xcassets directories..."
echo ""

# Find all .xcassets directories (excluding OriginalAssets, Tests, Testers, Example, build directories, and DerivedData)
xcassets_dirs=$(find . -type d -name "*.xcassets" | grep -v ".build" | grep -v "DerivedData" | grep -v "OriginalAssets" | grep -v "/Tests/" | grep -v "/Testers/" | grep -v "/Example/")

if [ -z "$xcassets_dirs" ]; then
    echo "❌ No .xcassets directories found"
    exit 1
fi

# Arrays to store results
declare -a unused_assets=()
declare -a used_assets=()
total_assets=0

# Function to extract asset name from path
get_asset_name() {
    local path="$1"
    local parent_dir=$(dirname "$path")
    local name=$(basename "$parent_dir")
    # Remove .imageset extension
    name="${name%.imageset}"
    echo "$name"
}

# Function to check if an asset is used in the codebase
is_asset_used() {
    local asset_name="$1"

    # Special case: AccentColor is used via project.pbxproj
    if [ "$asset_name" == "AccentColor" ]; then
        return 0
    fi

    # Special case: bank_icon_* assets are used via string interpolation
    if [[ "$asset_name" == bank_icon_* ]]; then
        return 0
    fi

    # Search for various patterns that might reference this asset:
    # 1. UIImage(named: "asset_name")
    # 2. Image("asset_name")
    # 3. safeImageNamed("asset_name")
    # 4. Direct string reference: "asset_name"
    # 5. In storyboards/xibs
    # 6. Enum case references (e.g., .carousel_sepa)

    # First, try searching for the asset name with quotes
    if grep -r \
        --exclude-dir=".xcassets" \
        --exclude-dir="OriginalAssets" \
        --exclude="*.png" \
        --exclude="*.jpg" \
        --exclude="*.jpeg" \
        --exclude="*.pdf" \
        --exclude="CHANGELOG.md" \
        --exclude="find_unused_assets.sh" \
        --include="*.swift" \
        --include="*.m" \
        --include="*.h" \
        --include="*.xib" \
        --include="*.storyboard" \
        "\"$asset_name\"" . &> /dev/null; then
        return 0
    fi

    # Also check for enum case style references (e.g., .asset_name or case asset_name)
    if grep -r \
        --exclude-dir=".xcassets" \
        --exclude-dir="OriginalAssets" \
        --exclude="*.png" \
        --exclude="*.jpg" \
        --exclude="*.jpeg" \
        --exclude="*.pdf" \
        --exclude="CHANGELOG.md" \
        --exclude="find_unused_assets.sh" \
        --include="*.swift" \
        --include="*.m" \
        --include="*.h" \
        -E "\.$asset_name|case $asset_name" . &> /dev/null; then
        return 0
    fi

    return 1
}

# Process each .xcassets directory
while IFS= read -r xcassets_dir; do
    echo "📂 Checking: $xcassets_dir"

    # Find all imageset and colorset Contents.json files
    while IFS= read -r contents_json; do
        # Skip empty lines
        if [ -z "$contents_json" ]; then
            continue
        fi

        # Only process Contents.json files in .imageset directories
        if [[ "$contents_json" == *".imageset/Contents.json" ]]; then
            # Skip BECS assets (they are referenced in JSON files)
            if [[ "$contents_json" == *"/BECS/"* ]]; then
                continue
            fi

            asset_name=$(get_asset_name "$contents_json")
            total_assets=$((total_assets + 1))

            if is_asset_used "$asset_name"; then
                used_assets+=("$asset_name")
            else
                unused_assets+=("$asset_name|$contents_json")
            fi
        fi
    done < <(find "$xcassets_dir" -name "Contents.json")

done <<< "$xcassets_dirs"

echo ""
echo "============================================"
echo "Summary:"
echo "============================================"
echo "Total assets checked: $total_assets"
echo "Used assets: ${#used_assets[@]}"
echo "Unused assets: ${#unused_assets[@]}"
echo ""

if [ ${#unused_assets[@]} -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Potentially unused assets:${NC}"
    echo ""
    for asset_info in "${unused_assets[@]}"; do
        IFS='|' read -r asset_name asset_path <<< "$asset_info"
        echo -e "  ${RED}✗${NC} $asset_name"
        echo "    📍 $asset_path"
    done
    echo ""
    echo -e "${YELLOW}Note: Some assets may be loaded dynamically or via string interpolation.${NC}"
    echo -e "${YELLOW}Please verify before removing.${NC}"
    exit 1
else
    echo -e "${GREEN}✅ All assets appear to be used!${NC}"
    exit 0
fi

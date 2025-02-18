#!/bin/bash
# Set locale to avoid "illegal byte sequence" errors in sed
export LC_ALL=C

# This script replaces text within files and renames files/folders
# changing every occurrence of "StripeElements" to "StripeElements"

# --- Step 1: Replace text inside files ---
echo "Replacing text in all files..."
# Adjust the find command if you want to exclude more directories (e.g., node_modules)
find . -type f ! -path "./.git/*" -exec sed -i '' 's/StripeElements/StripeElements/g' {} +

# --- Step 2: Rename files and directories ---
echo "Renaming files and directories..."
# Use -depth so that the contents are processed before their parent directories.
find . -depth -name "*StripeElements*" | while IFS= read -r oldpath; do
    # Construct the new path by replacing the text in the base name
    newpath="$(dirname "$oldpath")/$(basename "$oldpath" | sed 's/StripeElements/StripeElements/g')"
    echo "Renaming: $oldpath -> $newpath"
    mv "$oldpath" "$newpath"
done

echo "Replacement operation completed."


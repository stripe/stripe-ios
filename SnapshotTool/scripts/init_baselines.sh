#!/bin/bash
set -euo pipefail

# init_baselines.sh
# One-time setup: creates the snapshot-baselines orphan branch
# from the existing Tests/ReferenceImages_64 directory.
#
# Run this once to bootstrap the system, then the CI workflows
# will maintain the baselines going forward.

REPO_ROOT=$(git rev-parse --show-toplevel)
REFERENCE_DIR="$REPO_ROOT/Tests/ReferenceImages_64"

if [ ! -d "$REFERENCE_DIR" ]; then
    echo "Error: $REFERENCE_DIR does not exist"
    exit 1
fi

echo "Creating orphan branch 'snapshot-baselines' from existing reference images..."
echo "Source: $REFERENCE_DIR ($(find "$REFERENCE_DIR" -name '*.png' | wc -l | xargs) images)"

# Create a temporary worktree for the orphan branch
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

git worktree add --detach "$TEMP_DIR"
cd "$TEMP_DIR"

# Create orphan branch
git checkout --orphan snapshot-baselines
git rm -rf . > /dev/null 2>&1 || true

# Copy reference images maintaining directory structure
cp -r "$REFERENCE_DIR"/* .

# Commit
git add -A
git commit -m "Initial snapshot baselines from Tests/ReferenceImages_64"

echo ""
echo "Orphan branch 'snapshot-baselines' created locally."
echo "To push: git push origin snapshot-baselines"
echo ""
echo "After pushing, you can remove the reference images from the main branch"
echo "since they'll be managed by CI going forward."

# Clean up worktree
cd "$REPO_ROOT"
git worktree remove "$TEMP_DIR"

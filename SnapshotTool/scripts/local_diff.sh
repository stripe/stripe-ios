#!/bin/bash
set -euo pipefail

# local_diff.sh
# Run this locally to see how your changes affect snapshots.
# Fetches the current baselines and generates a diff report you can open in your browser.
#
# Usage: ./SnapshotTool/scripts/local_diff.sh [test_target]
# Example: ./SnapshotTool/scripts/local_diff.sh StripePaymentSheetTests

REPO_ROOT=$(git rev-parse --show-toplevel)
SCRIPT_DIR="$REPO_ROOT/SnapshotTool/scripts"
TEST_TARGET="${1:-}"

echo "==> Fetching current baselines..."
git fetch origin snapshot-baselines --depth=1 2>/dev/null || {
    echo "Error: 'snapshot-baselines' branch not found. Run init_baselines.sh first."
    exit 1
}

BASELINE_DIR=$(mktemp -d)
trap "rm -rf $BASELINE_DIR" EXIT
git worktree add "$BASELINE_DIR" origin/snapshot-baselines --detach 2>/dev/null

echo "==> Running snapshot tests in record mode..."
RECORDED_DIR="$REPO_ROOT/Tests/ReferenceImages_64"

BUILD_CMD="xcodebuild test \
    -workspace Stripe.xcworkspace \
    -scheme StripeiOS \
    -destination 'platform=iOS Simulator,name=iPhone 12 mini'"

if [ -n "$TEST_TARGET" ]; then
    BUILD_CMD="$BUILD_CMD -only-testing:$TEST_TARGET"
fi

eval "STP_RECORD_SNAPSHOTS=1 $BUILD_CMD 2>&1 | xcbeautify" || true

echo "==> Generating diff report..."
REPORT="$REPO_ROOT/snapshot-report.html"
"$SCRIPT_DIR/generate_diff_report.sh" "$RECORDED_DIR" "$BASELINE_DIR" "$REPORT" || true

git worktree remove "$BASELINE_DIR" 2>/dev/null || true

if [ -f "$REPORT" ]; then
    echo "==> Opening report..."
    open "$REPORT"
else
    echo "==> No changes detected."
fi

#!/bin/bash

# Claude Code PreToolUse hook (see .claude/settings.json) that formats and lints
# modified files before `git commit`.
#
# Runs in the checkout the commit targets rather than $CLAUDE_PROJECT_DIR, so that
# commits made from a git worktree format, lint, and stage the worktree's files
# instead of the main checkout's.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
HOOK_CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

if ! echo "$COMMAND" | grep -E 'git(\s+-C\s+("[^"]+"|\S+))?\s+commit' > /dev/null 2>&1; then
    exit 0
fi

TARGET_DIR="${HOOK_CWD:-$CLAUDE_PROJECT_DIR}"

# Honor `git -C <path> commit` and a leading `cd <path> &&`.
GIT_C_DIR=$(echo "$COMMAND" | sed -nE 's/.*git[[:space:]]+-C[[:space:]]+("([^"]+)"|([^[:space:]]+))[[:space:]]+commit.*/\2\3/p' | head -n 1)
CD_DIR=$(echo "$COMMAND" | sed -nE 's/^[[:space:]]*cd[[:space:]]+("([^"]+)"|([^[:space:]&;]+)).*/\2\3/p' | head -n 1)
for DIR in "$CD_DIR" "$GIT_C_DIR"; do
    if [ -n "$DIR" ]; then
        case "$DIR" in
            /*) TARGET_DIR="$DIR" ;;
            *) TARGET_DIR="$TARGET_DIR/$DIR" ;;
        esac
    fi
done

REPO_ROOT=$(git -C "$TARGET_DIR" rev-parse --show-toplevel 2> /dev/null)
if [ -z "$REPO_ROOT" ]; then
    echo "❌ Could not find the git checkout for this commit (looked in $TARGET_DIR)." >&2
    exit 2
fi

echo "🔍 Running format and lint checks in $REPO_ROOT..."
cd "$REPO_ROOT" || exit 2
if ci_scripts/format_modified_files.sh && ci_scripts/lint_modified_files.sh; then
    if ! git diff --exit-code > /dev/null 2>&1; then
        echo '📝 Format made changes, auto-staging them...'
        git add -u
        echo '✅ Formatted files staged and ready to commit!'
    else
        echo '✅ Format and lint checks passed!'
    fi
else
    echo '❌ Format or lint check failed. Please fix the issues before committing.' >&2
    exit 2
fi

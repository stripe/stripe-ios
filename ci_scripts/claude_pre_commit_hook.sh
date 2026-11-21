#!/bin/bash

# Claude Code PreToolUse hook (see .claude/settings.json) that formats and lints modified files before `git commit`.
# The checks run in the repository being committed to, which may be a worktree other than $CLAUDE_PROJECT_DIR:
# the hook's working directory, changed by each `cd <dir>` before the commit and then by `git -C <dir> commit`.
# Paths containing spaces must be quoted.

input=$(cat)
command=$(jq -r '.tool_input.command // empty' <<<"$input")
directory=$(jq -r '.cwd // empty' <<<"$input")
directory=${directory:-$CLAUDE_PROJECT_DIR}

path_pattern="(\"[^\"]*\"|'[^']*'|[^;&|[:space:]]+)"
commit_pattern="git(([[:space:]]+-C[[:space:]]+$path_pattern)*)[[:space:]]+commit([[:space:]]|$)"
if ! [[ $command =~ $commit_pattern ]]; then
  exit 0
fi
commit_command=${BASH_REMATCH[0]}
git_options=${BASH_REMATCH[1]}

# Resolves `$1` against the current `$directory`, removing surrounding quotes.
function resolve() {
  local path=${1#[\"\']}
  path=${path%[\"\']}
  path=${path/#\~/$HOME}
  if [[ $path == /* ]]; then
    echo "$path"
  else
    echo "$directory/$path"
  fi
}

# Apply each `cd` before the commit, then each `-C`, in order.
while read -r path; do
  [ -n "$path" ] && directory=$(resolve "$path")
done < <(
  grep -oE "(^|[;&|[:space:]])cd[[:space:]]+$path_pattern" <<<"${command%%"$commit_command"*}" | sed -E 's/^[;&|[:space:]]*cd[[:space:]]+//'
  grep -oE "\-C[[:space:]]+$path_pattern" <<<"$git_options" | sed -E 's/^-C[[:space:]]+//'
)

if ! repository=$(git -C "$directory" rev-parse --show-toplevel 2>/dev/null) || [ ! -x "$repository/ci_scripts/format_modified_files.sh" ]; then
  # Not a commit to this repository, so there's nothing to check.
  exit 0
fi

cd "$repository" || exit 0
echo "🔍 Running format and lint checks in $repository..."
if ! output=$(ci_scripts/format_modified_files.sh 2>&1 && ci_scripts/lint_modified_files.sh 2>&1); then
  echo "$output" >&2
  echo "❌ Format or lint check failed in $repository. Please fix the issues before committing." >&2
  exit 2
fi
if ! git diff --exit-code >/dev/null 2>&1; then
  echo '📝 Format made changes, auto-staging them...'
  git add -u
  echo '✅ Formatted files staged and ready to commit!'
else
  echo '✅ Format and lint checks passed!'
fi

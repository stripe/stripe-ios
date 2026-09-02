#!/bin/bash

# To set as a local pre-commit hook:
#         ln -s "$(pwd)/ci_scripts/format_modified_files.sh" .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit

function suggest_no_verify() {
  sleep 0.01 # wait for git to print its error
  echo 'If you want to commit without formatting, use:'
  tput setaf 7 # white
  echo
  echo '    git commit --no-verify'
  echo
  tput sgr0 # reset
}

# Resolve the real ci_scripts directory (following symlinks, so this works when
# invoked as a .git/hooks/pre-commit symlink) and ensure the pinned SwiftLint
# version is installed, exporting $SWIFTLINT (RUN_MOBILESDK-5167).
source_path="${BASH_SOURCE[0]}"
while [ -h "$source_path" ]; do
  source_dir="$(cd -P "$(dirname "$source_path")" && pwd)"
  source_path="$(readlink "$source_path")"
  [[ $source_path != /* ]] && source_path="$source_dir/$source_path"
done
source "$(cd -P "$(dirname "$source_path")" && pwd)/ensure_swiftlint.sh"

IS_HOOK=false
if [ $(dirname "$0") == ".git/hooks" ]; then
  IS_HOOK=true
fi

START=$(date +%s)

if [ "$IS_HOOK" = true ]; then
  echo "Formatting before commit (use $(tput setaf 7)git commit --no-verify$(tput sgr0) to skip)."
  echo ""
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
count=0
if [ "$CURRENT_BRANCH" == "master" ]; then
  echo "Can't format on master branch"
  exit 1
else
  # Calculate the merge base between origin/master and HEAD.
  MERGE_BASE=$(git merge-base origin/master HEAD)
  while IFS= read -r file; do
    export SCRIPT_INPUT_FILE_$count="$file"
    count=$((count + 1))
  done < <(git diff --diff-filter=AM --name-only "$MERGE_BASE" | grep ".swift$")
fi

export SCRIPT_INPUT_FILE_COUNT=$count

if [ "$count" -ne 0 ]; then
  "$SWIFTLINT" --fix --use-script-input-files --config .swiftlint.yml
fi

EXIT_CODE=$?

END=$(date +%s)
echo ""
echo "Formatted in $(($END - $START))s."
if [ "$EXIT_CODE" == '0' ]; then
  echo 'Done formatting!'
elif [ "$IS_HOOK" = true ]; then
  suggest_no_verify &
fi
exit $EXIT_CODE

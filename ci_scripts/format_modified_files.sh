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

if ! command -v swiftlint &> /dev/null; then
  echo "swiftlint is not installed! Use:"
  tput setaf 7 # white
  echo
  echo '    brew install swiftlint'
  echo
  tput sgr0 # reset
  exit 1
fi

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
  swiftlint --fix --use-script-input-files --config .swiftlint.yml

  # Re-stage the formatted files
  for ((i=0; i<count; i++)); do
    file_var="SCRIPT_INPUT_FILE_$i"
    file_path="${!file_var}"
    if [ -f "$file_path" ]; then
      git add "$file_path"
    fi
  done
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

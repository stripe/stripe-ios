#!/bin/bash

# To set as a local pre-push hook:
#         ln -s "$(pwd)/ci_scripts/lint_modified_files.sh" .git/hooks/pre-push && chmod +x .git/hooks/pre-push

function suggest_no_verify() {
  sleep 0.01 # wait for git to print its error
  echo 'If you want to push without linting, use:'
  tput setaf 7 # white
  echo
  echo '    git push --no-verify'
  echo
  tput sgr0 # reset
}

if which swiftlint >/dev/null; then
  IS_HOOK=false
  if [ $(dirname $0) == ".git/hooks" ]; then
    IS_HOOK=true
  fi

  START=`date +%s`

  z40=0000000000000000000000000000000000000000

  if [ "$IS_HOOK" = true ]; then
    echo "Linting before pushing (use $(tput setaf 7)git push --no-verify$(tput sgr0) to skip)."
    echo ""
  fi

  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  count=0
  if [ "$CURRENT_BRANCH" == "master" ]; then
    echo "Can't lint on master branch"
    exit 1
  else
    while IFS= read -r file; do
      export SCRIPT_INPUT_FILE_$count="$file"
      count=$((count + 1))
    done < <(git diff --diff-filter=AM --name-only origin/master  | grep ".swift$")
  fi

  export SCRIPT_INPUT_FILE_COUNT=$count

  if [ "$count" -ne 0 ]; then
    swiftlint --strict --use-script-input-files --config .swiftlint.yml
  fi

  EXIT_CODE=$?

  END=`date +%s`
  echo ""
  echo "Linted in $(($END - $START))s."
  if [ "$EXIT_CODE" == '0' ]; then
    echo 'All lints passed.'
  elif [ "$IS_HOOK" = true ]; then
    suggest_no_verify &
  fi
  exit $EXIT_CODE
else
  echo "swiftlint is not installed! Use:"
  tput setaf 7 # white
  echo
  echo '    brew install swiftlint'
  echo
  tput sgr0 # reset
  exit 1
fi

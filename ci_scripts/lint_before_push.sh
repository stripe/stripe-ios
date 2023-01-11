#!/bin/bash

# To set as a local pre-push hook:
#         ln -s "$(pwd)/ci_scripts/lint_before_push.sh" .git/hooks/pre-push && chmod +x .git/hooks/pre-push

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

  START=`date +%s`

  z40=0000000000000000000000000000000000000000

  echo "Linting before pushing (use $(tput setaf 7)git push --no-verify$(tput sgr0) to skip)."
  echo ""

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
  if [ "$EXIT_CODE" != '0' ]; then
    suggest_no_verify &
  else
    echo 'All lints passed.'
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

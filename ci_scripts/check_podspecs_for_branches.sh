#!/bin/bash

# This script is used as part of the deployment process to ensure all our
# .podspec files use tags instead of branches in `s.source`.

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check all .podspec files
for podspec in ${script_dir}/../*.podspec
do
  # Ensure there is no `:branch` entry in s.source
  branch_search_result="$(cat $podspec | grep -e "s\\.source.*\\:branch")"
  if [ ! -z "${branch_search_result}" ]
  then
    echo "'$(basename $podspec)': Update \`s.source\` to use \`:tag => \"#{s.version}\"\` instead of \`:branch => ...\` before deploying." >&2
    exit 1
  fi

  # Ensure there is a `:tag => "#{s.version}"` entry in s.source
  tag_search_result="$(cat $podspec | grep -e "s\\.source.*\\:tag => \"#{s\\.version}\"")"
  if [ -z "${tag_search_result}" ]
  then
    echo "'$(basename $podspec)': Update \`s.source\` to use \`:tag => \"#{s.version}\"\` before deploying." >&2
    exit 1
  fi

done
echo "Done!"

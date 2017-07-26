#!/bin/bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Verify jazzy is installed
if ! command -v jazzy > /dev/null; then
  echo "ERROR: Please install jazzy before running build_documentation.sh:"
  echo "https://github.com/realm/jazzy#installation"
  exit 1
fi

# Verify jazzy is up to date
jazzy_version_local="$(gem search ^jazzy$ --local --no-verbose)"
jazzy_version_remote="$(gem search ^jazzy$ --remote --no-verbose)"

if [[ "${jazzy_version_local}" != "${jazzy_version_remote}" ]]; then
  echo "ERROR: Please update jazzy before running build_documentation.sh:"
  echo "\`gem update jazzy\`"
  exit 1
fi

# Clean destination `stripe-ios/docs/docs/` directory
echo "Cleaning stripe-ios/docs/docs/ directory..."
rm -rf "${script_dir}/../docs/docs/"

# Execute jazzy
echo "Executing jazzy..."
jazzy \
  --config "${script_dir}/../.jazzy.yaml" \
  --output "${script_dir}/../docs/docs"

# Verify jazzy exit code
jazzy_exit_code="$?"

if [[ "${jazzy_exit_code}" != 0 ]]; then
  echo "ERROR: Executing jazzy failed with status code: ${jazzy_exit_code}"
  exit 1
fi

echo "Successfully built documentation"

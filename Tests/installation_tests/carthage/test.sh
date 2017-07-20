#!/bin/bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install xcpretty
if ! command -v xcpretty > /dev/null; then
  echo "Installing xcpretty..."
  gem install xcpretty --no-ri --no-rdoc
fi

# Clean carthage artifacts
echo "Cleaning carthage artifacts..."

rm -f "${script_dir}/Cartfile"
rm -f "${script_dir}/Cartfile.resolved"
rm -rf "${script_dir}/Carthage"

# Generate new Cartfile
echo "Generating new Cartfile..."

git_repo="$(cd "${script_dir}/../../../" && pwd)"
git_hash="$(git rev-parse HEAD)"

echo "git \"${git_repo}\" \"${git_hash}\"" > "${script_dir}/Cartfile"

# Execute carthage bootstrap
echo "Executing carthage bootstrap..."

cd "${script_dir}"

carthage bootstrap --platform ios --configuration Debug --no-use-binaries

carthage_exit_code="$?"

if [[ "${carthage_exit_code}" != 0 ]]; then
  echo "ERROR: Executing carthage bootstrap failed with status code: ${carthage_exit_code}"
  exit 1
fi

# Execute xcodebuild
echo "Executing xcodebuild..."

xcodebuild build \
  -project "${script_dir}/CarthageTest.xcodeproj" \
  -scheme "CarthageTest" \
  -sdk "iphonesimulator" \
  -destination "platform=iOS Simulator,name=iPhone 6,OS=10.3.1" \
  | xcpretty

xcodebuild_exit_code="${PIPESTATUS[0]}"

if [[ "${xcodebuild_exit_code}" != 0 ]]; then
  echo "ERROR: Executing xcodebuild failed with status code: ${xcodebuild_exit_code}"
  exit 1
fi

echo "All good!"

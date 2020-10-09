#!/bin/bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function info {
  echo "[$(basename "${0}")] [INFO] ${1}"
}

function die {
  echo "[$(basename "${0}")] [ERROR] ${1}"
  exit 1
}

# Verify xcpretty is installed
if ! command -v xcpretty > /dev/null; then
  if [[ "${CI}" != "true" ]]; then
    die "Please install xcpretty: https://github.com/supermarin/xcpretty#installation"
  fi

  info "Installing xcpretty..."
  gem install xcpretty --no-document || die "Executing \`gem install xcpretty\` failed"
fi

# Clean carthage artifacts
info "Cleaning carthage artifacts..."

rm -f "${script_dir}/Cartfile"
rm -f "${script_dir}/Cartfile.resolved"
rm -rf "${script_dir}/Carthage"

# Generate new Cartfile
info "Generating new Cartfile..."

git_repo="$(cd "${script_dir}/../../../" && pwd)"
git_hash="$(git rev-parse HEAD)"

echo "git \"${git_repo}\" \"${git_hash}\"" > "${script_dir}/Cartfile"

# Execute carthage bootstrap
info "Executing carthage bootstrap..."

cd "${script_dir}" || die "Executing \`cd\` failed"

carthage bootstrap --platform ios --configuration Debug --no-use-binaries

carthage_exit_code="$?"

if [[ "${carthage_exit_code}" != 0 ]]; then
  die "Executing carthage bootstrap failed with status code: ${carthage_exit_code}"
fi

# Execute xcodebuild
info "Executing xcodebuild..."

xcodebuild clean build \
  -project "${script_dir}/CarthageTest.xcodeproj" \
  -scheme "CarthageTest" \
  -sdk "iphonesimulator" \
  -destination "platform=iOS Simulator,name=iPhone 6,OS=12.4" \
  | xcpretty

xcodebuild_exit_code="${PIPESTATUS[0]}"

if [[ "${xcodebuild_exit_code}" != 0 ]]; then
  die "Executing xcodebuild failed with status code: ${xcodebuild_exit_code}"
fi

info "All good!"

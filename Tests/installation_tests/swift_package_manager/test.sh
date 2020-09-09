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

# Switch to script directory
cd "${script_dir}" || die "Executing \`cd\` failed"

# Unzip the files.
# This is a hack: Carthage + Xcode 11 will fail if it sees an xcodeproj in our repo that
# isn't parseable by Xcode 12, even if that xcodeproj isn't referenced at all.
# To work around this, we hide the xcworkspace in a zip file.

unzip SPMTest.xcworkspace.zip

# Execute xcodebuild
info "Executing xcodebuild..."

xcodebuild clean build \
  -workspace "SPMTest.xcworkspace" \
  -scheme "SPMTest" \
  -sdk "iphonesimulator" \
  -destination "platform=iOS Simulator,name=iPhone 6,OS=11.4" \
  | xcpretty

xcodebuild_exit_code="${PIPESTATUS[0]}"

if [[ "${xcodebuild_exit_code}" != 0 ]]; then
  die "Executing xcodebuild failed with status code: ${xcodebuild_exit_code}"
fi

info "All good!"

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

# Verify cocoapods is installed
if ! command -v pod > /dev/null; then
  if [[ "${CI}" != "true" ]]; then
    die "Please install cocoapods: https://cocoapods.org"
  fi

  info "Installing cocoapods..."
  gem install cocoapods --no-document || die "Executing \`gem install cocoapods\` failed"
fi

# Verify cocoapods is up to date
cocoapods_version_local="$(pod --version | grep --only-matching --extended-regexp "[0-9\.]+")"
cocoapods_version_remote="$(gem search ^cocoapods$ --remote --no-verbose | grep --only-matching --extended-regexp "[0-9\.]+")"

if [[ "${cocoapods_version_local}" != "${cocoapods_version_remote}" ]]; then
 if [[ "${CI}" != "true" ]]; then
   die "Please update cocoapods: \`gem update cocoapods\`"
 fi

 info "Updating cocoapods..."
 gem update cocoapods --no-document || die "Executing \`gem update cocoapods\` failed"
fi

# Switch to script directory
cd "${script_dir}" || die "Executing \`cd\` failed"

# Clean cocoapods artifacts
info "Cleaning cocoapods artifacts..."

rm -rf "Pods"
rm -f "Podfile.lock"

# Perform cocoapods installation
info "Performing pod install..."

pod install --no-repo-update || die "Executing \`pod install\` failed"

# Execute xcodebuild
info "Executing xcodebuild..."

xcodebuild clean build \
  -workspace "CocoapodsTest.xcworkspace" \
  -scheme "CocoapodsTest" \
  -sdk "iphonesimulator" \
  -destination "platform=iOS Simulator,name=iPhone 8,OS=13.7" \
  | xcpretty

xcodebuild_exit_code="${PIPESTATUS[0]}"

if [[ "${xcodebuild_exit_code}" != 0 ]]; then
  die "Executing xcodebuild failed with status code: ${xcodebuild_exit_code}"
fi

info "All good!"

#!/bin/bash

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

# Install test dependencies
info "Installing test dependencies..."

carthage bootstrap --platform iOS --configuration Release --no-use-binaries --cache-builds --use-xcframeworks
carthage_exit_code="$?"

if [[ "${carthage_exit_code}" != 0 ]]; then
  die "Executing carthage failed with status code: ${carthage_exit_code}"
fi

# Execute localization tests (iPhone 8 @ iOS 13.7)
info "Executing localization tests (iPhone 8 @ iOS 13.7)..."

xcodebuild test \
  -workspace "Stripe.xcworkspace" \
  -scheme "LocalizationTester" \
  -configuration "Debug" \
  -sdk "iphonesimulator" \
  -destination "platform=iOS Simulator,name=iPhone 8,OS=13.7" \
  -derivedDataPath build-ci-tests \
  | xcpretty

exit_code="${PIPESTATUS[0]}"

if [[ "${exit_code}" != 0 ]]; then
  die "xcodebuild exited with non-zero status code: ${exit_code}"
fi

info "All good!"

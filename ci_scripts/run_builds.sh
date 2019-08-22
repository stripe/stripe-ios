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

# Execute sample app builds (iPhone 6, iOS 11.x)
info "Executing sample app builds (iPhone 6, iOS 11.x)..."

xcodebuild build \
  -workspace "Stripe.xcworkspace" \
  -scheme "Standard Integration" \
  -sdk "iphonesimulator" \
  -destination "platform=iOS Simulator,name=iPhone 7,OS=12.2" \
  | xcpretty

exit_code="${PIPESTATUS[0]}"

if [[ "${exit_code}" != 0 ]]; then
  die "xcodebuild exited with non-zero status code: ${exit_code}"
fi

xcodebuild build \
  -workspace "Stripe.xcworkspace" \
  -scheme "Custom Integration" \
  -sdk "iphonesimulator" \
  -destination "platform=iOS Simulator,name=iPhone 7,OS=12.2" \
  | xcpretty

exit_code="${PIPESTATUS[0]}"

if [[ "${exit_code}" != 0 ]]; then
  die "xcodebuild exited with non-zero status code: ${exit_code}"
fi

xcodebuild build \
  -workspace "Stripe.xcworkspace" \
  -scheme "UI Examples" \
  -sdk "iphonesimulator" \
  -destination "platform=iOS Simulator,name=iPhone 7,OS=12.2" \
  | xcpretty

exit_code="${PIPESTATUS[0]}"

if [[ "${exit_code}" != 0 ]]; then
  die "xcodebuild exited with non-zero status code: ${exit_code}"
fi

info "All good!"

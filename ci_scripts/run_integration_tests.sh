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

# Disable hardware keyboard
killall "Simulator"
defaults write com.apple.iphonesimulator ConnectHardwareKeyboard -bool false

# Execute tests (iPhone 11 @ iOS 13.7)
info "Executing tests (iPhone 11 @ iOS 13.7)..."

xcodebuild clean test \
  -workspace "Stripe.xcworkspace" \
  -scheme "Basic Integration" \
  -configuration "Debug" \
  -sdk "iphonesimulator" \
  -destination "platform=iOS Simulator,name=iPhone 11,OS=13.7" \
  | xcpretty

exit_code="${PIPESTATUS[0]}"

if [[ "${exit_code}" != 0 ]]; then
  die "xcodebuild exited with non-zero status code: ${exit_code}"
fi

# Execute tests (iPhone 12 @ iOS 14.2)
info "Executing tests (iPhone 12 @ iOS 14.2)..."

xcodebuild clean test \
  -workspace "Stripe.xcworkspace" \
  -scheme "PaymentSheet Example" \
  -configuration "Debug" \
  -sdk "iphonesimulator" \
  -destination "platform=iOS Simulator,name=iPhone 12,OS=latest" \
  | xcpretty

exit_code="${PIPESTATUS[0]}"

if [[ "${exit_code}" != 0 ]]; then
  die "xcodebuild exited with non-zero status code: ${exit_code}"
fi

info "All good!"

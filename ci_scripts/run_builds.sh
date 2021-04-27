#!/bin/bash

function info {
  echo "[$(basename "${0}")] [INFO] ${1}"
}

function die {
  echo "[$(basename "${0}")] [ERROR] ${1}"
  exit 1
}

# Execute sample app builds
info "Executing sample app builds (iPhone 8, iOS 13.7)..."

# Basic integration is tested in run_integration_tests.sh

xcodebuild build \
  -quiet \
  -workspace "Stripe.xcworkspace" \
  -scheme "Non-Card Payment Examples" \
  -sdk "iphonesimulator" \
  -destination "platform=iOS Simulator,name=iPhone 8,OS=13.7" \
  -derivedDataPath build-ci-tests

exit_code="${PIPESTATUS[0]}"

if [[ "${exit_code}" != 0 ]]; then
  die "xcodebuild exited with non-zero status code: ${exit_code}"
fi

xcodebuild build \
  -quiet \
  -workspace "Stripe.xcworkspace" \
  -scheme "UI Examples" \
  -sdk "iphonesimulator" \
  -destination "platform=iOS Simulator,name=iPhone 8,OS=13.7"

exit_code="${PIPESTATUS[0]}"

if [[ "${exit_code}" != 0 ]]; then
  die "xcodebuild exited with non-zero status code: ${exit_code}"
fi

info "All good!"

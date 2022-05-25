#!/bin/bash

function info {
  echo "[$(basename "${0}")] [INFO] ${1}"
}

function die {
  echo "[$(basename "${0}")] [ERROR] ${1}"
  exit 1
}

# Execute tests
info "Executing tests (iPhone 12 mini @ iOS 15.4)..."

xcodebuild clean test \
  -quiet \
  -project "Stripe3DS2/Stripe3DS2.xcodeproj" \
  -scheme "Stripe3DS2Tests" \
  -sdk "iphonesimulator" \
  -destination "platform=iOS Simulator,name=iPhone 12 mini,OS=latest"

exit_code="${PIPESTATUS[0]}"

if [[ "${exit_code}" != 0 ]]; then
  die "xcodebuild exited with non-zero status code: ${exit_code}"
fi

info "All good!"


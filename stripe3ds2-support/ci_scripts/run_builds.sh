#!/bin/bash

function info {
  echo "[$(basename "${0}")] [INFO] ${1}"
}

function die {
  echo "[$(basename "${0}")] [ERROR] ${1}"
  exit 1
}

# Execute builds
info "Executing build (iPhone 12 mini, iOS 15.4)..."

xcodebuild build \
  -quiet \
  -project "Stripe3DS2/Stripe3DS2.xcodeproj" \
  -scheme "Stripe3DS2" \
  -sdk "iphonesimulator" \
  -destination "platform=iOS Simulator,name=iPhone 12 mini,OS=15.4"

exit_code="${PIPESTATUS[0]}"

if [[ "${exit_code}" != 0 ]]; then
  die "xcodebuild exited with non-zero status code: ${exit_code}"
fi

info "All good!"


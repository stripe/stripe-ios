#!/bin/bash

function info {
  echo "[$(basename "${0}")] [INFO] ${1}"
}

function die {
  echo "[$(basename "${0}")] [ERROR] ${1}"
  exit 1
}

if [[ $# -eq 2 ]]; then
    TEST_DEVICE=$1
    TEST_VERSION=$2
else
    TEST_DEVICE="iPhone 12 mini"
    TEST_VERSION="16.4"
fi

# Execute builds
info "Executing build (${TEST_DEVICE}, iOS ${TEST_VERSION})..."

xcodebuild build \
  -quiet \
  -project "Stripe3DS2/Stripe3DS2.xcodeproj" \
  -scheme "Stripe3DS2" \
  -sdk "iphonesimulator" \
  -destination "platform=iOS Simulator,name=${TEST_DEVICE},OS=${TEST_VERSION}"

exit_code="${PIPESTATUS[0]}"

if [[ "${exit_code}" != 0 ]]; then
  die "xcodebuild exited with non-zero status code: ${exit_code}"
fi

info "All good!"


#!/bin/bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function info {
  echo "[$(basename "${0}")] [INFO] ${1}"
}

function die {
  echo "[$(basename "${0}")] [ERROR] ${1}"
  exit 1
}

# Switch to script directory
cd "${script_dir}" || die "Executing \`cd\` failed"

# Execute xcodebuild
info "Executing xcodebuild..."

xcodebuild clean build \
  -quiet \
  -workspace "SPMTest.xcworkspace" \
  -scheme "SPMTest" \
  -sdk "iphonesimulator" \
  -destination "platform=iOS Simulator,name=iPhone 8,OS=13.7"

xcodebuild_exit_code="${PIPESTATUS[0]}"

if [[ "${xcodebuild_exit_code}" != 0 ]]; then
  die "Executing xcodebuild failed with status code: ${xcodebuild_exit_code}"
fi

info "All good!"

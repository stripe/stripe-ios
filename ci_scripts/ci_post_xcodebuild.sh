#!/bin/bash
set -euo pipefail

# Runs in Xcode Cloud after `xcodebuild`
# See https://developer.apple.com/documentation/xcode/writing-custom-build-scripts

script_dir="$(cd "$(dirname "$0")" && pwd)"

if [[ "${STRIPE_XCODE_CLOUD_CI:-0}" == "1" ]]; then
    # Keep diagnostics in the hook log; Xcode Cloud retains the native xcresult.
    if [[ "${CI_XCODEBUILD_ACTION:-}" == "test-without-building" && -d "${CI_RESULT_BUNDLE_PATH:-}" ]]; then
        xcrun xcresulttool get test-results summary --path "$CI_RESULT_BUNDLE_PATH" || true
    fi
elif [[ "${CI_XCODEBUILD_ACTION:-}" == "archive" ]]; then
    cd "$script_dir"
    sh ./xcode_cloud_test_flight_notes.sh
fi

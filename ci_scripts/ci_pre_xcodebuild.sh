#!/bin/bash
set -euo pipefail

[[ "${STRIPE_XCODE_CLOUD_CI:-0}" == "1" ]] || exit 0
script_dir="$(cd "$(dirname "$0")" && pwd)"

# Xcode Cloud runs this phase on a separate worker without the source checkout.
if [[ "${CI_XCODEBUILD_ACTION:-}" == "test-without-building" ]]; then
    python3 "$script_dir/xcode_cloud/prepare.py" test

    # Use the destination chosen by Xcode Cloud, never an arbitrary booted device.
    device="${CI_TEST_DESTINATION_UDID:?Missing Xcode Cloud test destination}"
    xcrun simctl boot "$device" 2>/dev/null || true
    xcrun simctl bootstatus "$device" -b
    xcrun simctl spawn "$device" defaults write com.apple.keyboard.preferences DidShowContinuousPathIntroduction -bool true
    xcrun simctl spawn "$device" defaults write com.apple.keyboard.preferences DidShowGestureKeyboardIntroduction -bool true
fi

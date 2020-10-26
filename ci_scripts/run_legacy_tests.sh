#!/bin/bash

# TODO(Swift): Remove this after Carthage is fixed for Xcode 12
root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
source "${root_dir}/ci_scripts/hack-carthage-xcode-12.sh"

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

carthage bootstrap --platform iOS --configuration Release --no-use-binaries
carthage_exit_code="$?"

if [[ "${carthage_exit_code}" != 0 ]]; then
  die "Executing carthage failed with status code: ${carthage_exit_code}"
fi

# Execute tests on legacy devices (iPhone 6 @ iOS 10.x, iPhone 6 @ iOS 9.x, iPhone 4s @ iOS 9.x)
# - Skips snapshot tests because they're recorded for the iPhone 6 on the newest iOS version only
# - Not sure why tests STPImageLibraryTest fail on older iOS versions
# - Set `ONLY_ACTIVE_ARCH=NO` to build both 32-bit and 64-bit products
info "Executing tests on legacy device $1"

xcodebuild clean test \
  -workspace "Stripe.xcworkspace" \
  -scheme "StripeiOS" \
  -configuration "Debug" \
  -sdk "iphonesimulator" \
  -destination "$1" \
  -skip-testing:"StripeiOS Tests/STPAddCardViewControllerLocalizationTests" \
  -skip-testing:"StripeiOS Tests/STPPaymentOptionsViewControllerLocalizationTests" \
  -skip-testing:"StripeiOS Tests/STPShippingAddressViewControllerLocalizationTests" \
  -skip-testing:"StripeiOS Tests/STPShippingMethodsViewControllerLocalizationTests" \
  -skip-testing:"StripeiOS Tests/STPAUBECSDebitFormViewSnapshotTests" \
  -skip-testing:"StripeiOS Tests/STPPaymentContextSnapshotTests" \
  -skip-testing:"StripeiOS Tests/STPSTPViewWithSeparatorSnapshotTests" \
  -skip-testing:"StripeiOS Tests/STPLabeledFormTextFieldViewSnapshotTests" \
  -skip-testing:"StripeiOS Tests/STPLabeledMultiFormTextFieldViewSnapshotTests" \
  ONLY_ACTIVE_ARCH=NO \
  | xcpretty

exit_code="${PIPESTATUS[0]}"

if [[ "${exit_code}" != 0 ]]; then
  die "xcodebuild exited with non-zero status code: ${exit_code}"
fi

info "All good!"

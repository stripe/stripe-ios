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
  gem install xcpretty --no-ri --no-rdoc || die "Executing \`gem install xcpretty\` failed"
fi

# Install test dependencies
info "Installing test dependencies..."

carthage bootstrap --platform iOS --configuration Release --no-use-binaries
carthage_exit_code="$?"

if [[ "${carthage_exit_code}" != 0 ]]; then
  die "Executing carthage failed with status code: ${carthage_exit_code}"
fi

# Execute tests (iPhone 6 @ iOS 11.2)
info "Executing tests (iPhone 6 @ iOS 11.2)..."

xcodebuild clean test \
  -workspace "Stripe.xcworkspace" \
  -scheme "StripeiOS" \
  -configuration "Debug" \
  -sdk "iphonesimulator" \
  -destination "platform=iOS Simulator,name=iPhone 6,OS=11.2" \
  | xcpretty

exit_code="${PIPESTATUS[0]}"

if [[ "${exit_code}" != 0 ]]; then
  die "xcodebuild exited with non-zero status code: ${exit_code}"
fi

# Execute tests on legacy devices (iPhone 6 @ iOS 10.x, iPhone 6 @ iOS 9.x, iPhone 4s @ iOS 9.x)
# - Skips snapshot tests because they're recorded for the iPhone 6 on the newest iOS version only
# - Not sure why tests STPImageLibraryTest fail on older iOS versions
# - Set `ONLY_ACTIVE_ARCH=NO` to build both 32-bit and 64-bit products
info "Executing tests on legacy devices (iPhone 6 @ iOS 10.x, iPhone 6 @ iOS 9.x, iPhone 4s @ iOS 9.x)..."

xcodebuild clean test \
  -workspace "Stripe.xcworkspace" \
  -scheme "StripeiOS" \
  -configuration "Debug" \
  -sdk "iphonesimulator" \
  -destination "platform=iOS Simulator,name=iPhone 6,OS=10.3.1" \
  -destination "platform=iOS Simulator,name=iPhone 6,OS=9.3" \
  -destination "platform=iOS Simulator,name=iPhone 4s,OS=9.3" \
  -skip-testing:"StripeiOS Tests/STPAddCardViewControllerLocalizationTests" \
  -skip-testing:"StripeiOS Tests/STPPaymentMethodsViewControllerLocalizationTests" \
  -skip-testing:"StripeiOS Tests/STPShippingAddressViewControllerLocalizationTests" \
  -skip-testing:"StripeiOS Tests/STPShippingMethodsViewControllerLocalizationTests" \
  -skip-testing:"StripeiOS Tests/STPImageLibraryTest" \
  ONLY_ACTIVE_ARCH=NO \
  | xcpretty

exit_code="${PIPESTATUS[0]}"

if [[ "${exit_code}" != 0 ]]; then
  die "xcodebuild exited with non-zero status code: ${exit_code}"
fi

info "All good!"

#!/bin/bash

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"

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

# Verify Xcode 13.0 or later is selected
if ! xcodebuild -version | grep -q 'Xcode 11' &> /dev/null; then
  die "Please xcode-select a copy of Xcode 11."
fi

# Clean build directory
build_dir="${root_dir}/build"

info "Cleaning build directory..."

rm -rf "${build_dir}"
mkdir "${build_dir}"

# Compile and package dynamic framework
info "Compiling and packaging dynamic framework..."

cd "${root_dir}" || die "Executing \`cd\` failed"

set +ex

xcodebuild clean archive \
  -workspace "Stripe.xcworkspace" \
  -destination="iOS" \
  -scheme "StripeiOS" \
  -configuration "Release" \
  -archivePath "${build_dir}/Stripe-iOS.xcarchive" \
  -sdk iphoneos \
  SYMROOT="${build_dir}/framework-ios" \
  OBJROOT="${build_dir}/framework-ios" \
  SUPPORTS_MACCATALYST=NO \
  BUILD_LIBRARIES_FOR_DISTRIBUTION=YES \
  SKIP_INSTALL=NO \
  | xcpretty


exit_code="${PIPESTATUS[0]}"
if [[ "${exit_code}" != 0 ]]; then
  die "xcodebuild exited with non-zero status code: ${exit_code}"
fi


xcodebuild clean archive \
  -workspace "Stripe.xcworkspace" \
  -scheme "StripeiOS" \
  -destination="iOS Simulator" \
  -configuration "Release" \
  -archivePath "${build_dir}/Stripe-sim.xcarchive" \
  -sdk iphonesimulator \
  SYMROOT="${build_dir}/framework-sim" \
  OBJROOT="${build_dir}/framework-sim" \
  SUPPORTS_MACCATALYST=NO \
  BUILD_LIBRARIES_FOR_DISTRIBUTION=YES \
  SKIP_INSTALL=NO \
  | xcpretty


exit_code="${PIPESTATUS[0]}"
if [[ "${exit_code}" != 0 ]]; then
  die "xcodebuild exited with non-zero status code: ${exit_code}"
fi

# Once Xcode 12 is out, uncomment this section so we start building a Mac slice in our distributed .xcframework again.
# Until then, our recommended strategy for Catalyst users will be Xcode 12 + Swift Package Manager.
# 
# xcodebuild clean archive \
#   -workspace "Stripe.xcworkspace" \
#   -scheme "StripeiOS" \
#   -configuration "Release" \
#   -archivePath "${build_dir}/Stripe-mac.xcarchive" \
#   -sdk macosx \
#   SYMROOT="${build_dir}/framework-mac" \
#   OBJROOT="${build_dir}/framework-mac" \
#   SUPPORTS_MACCATALYST=YES \
#   BUILD_LIBRARIES_FOR_DISTRIBUTION=YES \
#   SKIP_INSTALL=NO \
#   | xcpretty
# exit_code="${PIPESTATUS[0]}"
# if [[ "${exit_code}" != 0 ]]; then
#   die "xcodebuild exited with non-zero status code: ${exit_code}"
# fi

set -ex
codesign_identity=$(security find-identity -v -p codesigning | grep Y28TH9SHX7 | grep -o -E '\w{40}' | head -n 1)
if [ -z "$codesign_identity" ]; then
  echo "Stripe Apple Distribution code signing certificate not found, Stripe.xcframework will not be built."
  echo "Install one from Xcode Settings -> Accounts -> Manage Certificates."
else
  codesign -f --deep -s "$codesign_identity" "${build_dir}/Stripe-iOS.xcarchive/Products/Library/Frameworks/Stripe.framework"
  codesign -f --deep -s "$codesign_identity" "${build_dir}/Stripe-sim.xcarchive/Products/Library/Frameworks/Stripe.framework"

  xcodebuild -create-xcframework \
  -framework "${build_dir}/Stripe-iOS.xcarchive/Products/Library/Frameworks/Stripe.framework" \
  -framework "${build_dir}/Stripe-sim.xcarchive/Products/Library/Frameworks/Stripe.framework" \
  -output "${build_dir}/Stripe.xcframework"

  codesign -f --deep -s "$codesign_identity" "${build_dir}/Stripe.xcframework"

  ditto \
    -ck \
    --rsrc \
    --sequesterRsrc \
    --keepParent \
    "${build_dir}/Stripe.xcframework" \
    "${build_dir}/Stripe.xcframework.zip"
fi

carthage build \
  --no-skip-current \
  --platform "iOS" \
  --configuration "Release"

ditto \
  -ck \
  --rsrc \
  --sequesterRsrc \
  --keepParent \
  "${root_dir}/Carthage/Build/iOS/Stripe.framework" \
  "${root_dir}/Carthage/Build/iOS/Stripe.framework.zip"

mv "${root_dir}/Carthage/Build/iOS/Stripe.framework.zip" "${build_dir}"
set +ex

info "All good!"

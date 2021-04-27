#!/bin/bash

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"

function info {
  echo "[$(basename "${0}")] [INFO] ${1}"
}

function die {
  echo "[$(basename "${0}")] [ERROR] ${1}"
  exit 1
}

# Clean build directory
build_dir="${root_dir}/build"

info "Cleaning build directory..."

rm -rf "${build_dir}"
mkdir "${build_dir}"

# Compile and package dynamic framework
info "Compiling and packaging dynamic framework..."

cd "${root_dir}" || die "Executing \`cd\` failed"

set +ex

# Build Stripe3DS2
info "Building Stripe3DS2..."

"${root_dir}/stripe3ds2-support/ci_scripts/build_dynamic_xcframework.sh"

exit_code="${PIPESTATUS[0]}"
if [[ "${exit_code}" != 0 ]]; then
  die "Stripe3DS2 build exited with non-zero status code: ${exit_code}"
fi

xcodebuild clean archive \
  -quiet \
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
  SKIP_INSTALL=NO


exit_code="${PIPESTATUS[0]}"
if [[ "${exit_code}" != 0 ]]; then
  die "xcodebuild exited with non-zero status code: ${exit_code}"
fi


xcodebuild clean archive \
  -quiet \
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
  SKIP_INSTALL=NO


exit_code="${PIPESTATUS[0]}"
if [[ "${exit_code}" != 0 ]]; then
  die "xcodebuild exited with non-zero status code: ${exit_code}"
fi

# Once Xcode 12 is out, uncomment this section so we start building a Mac slice in our distributed .xcframework again.
# Until then, our recommended strategy for Catalyst users will be Xcode 12 + Swift Package Manager.
xcodebuild clean archive \
  -quiet \
  -workspace "Stripe.xcworkspace" \
  -scheme "StripeiOS" \
  -configuration "Release" \
  -archivePath "${build_dir}/Stripe-mac.xcarchive" \
  -sdk macosx \
  SYMROOT="${build_dir}/framework-mac" \
  OBJROOT="${build_dir}/framework-mac" \
  SUPPORTS_MACCATALYST=YES \
  BUILD_LIBRARIES_FOR_DISTRIBUTION=YES \
  SKIP_INSTALL=NO
exit_code="${PIPESTATUS[0]}"
if [[ "${exit_code}" != 0 ]]; then
  die "xcodebuild exited with non-zero status code: ${exit_code}"
fi

set -ex

codesign_identity=$(security find-identity -v -p codesigning | grep Y28TH9SHX7 | grep -o -E '\w{40}' | head -n 1)
if [ -z "$codesign_identity" ]; then
  echo "Stripe Apple Distribution code signing certificate not found, Stripe.xcframework will not be signed."
  echo "Install one from Xcode Settings -> Accounts -> Manage Certificates."
else
  codesign -f --deep -s "$codesign_identity" "${build_dir}/Stripe-iOS.xcarchive/Products/Library/Frameworks/Stripe.framework"
  codesign -f --deep -s "$codesign_identity" "${build_dir}/Stripe-sim.xcarchive/Products/Library/Frameworks/Stripe.framework"
  codesign -f --deep -s "$codesign_identity" "${build_dir}/Stripe-mac.xcarchive/Products/Library/Frameworks/Stripe.framework"
fi

xcodebuild -create-xcframework \
-framework "${build_dir}/Stripe-iOS.xcarchive/Products/Library/Frameworks/Stripe.framework" \
-framework "${build_dir}/Stripe-sim.xcarchive/Products/Library/Frameworks/Stripe.framework" \
-framework "${build_dir}/Stripe-mac.xcarchive/Products/Library/Frameworks/Stripe.framework" \
-output "${build_dir}/Stripe.xcframework"

if [ -n "$codesign_identity" ]; then
  codesign -f --deep -s "$codesign_identity" "${build_dir}/Stripe.xcframework"
fi
  
ditto \
  -ck \
  --rsrc \
  --sequesterRsrc \
  --keepParent \
  "${build_dir}/Stripe.xcframework" \
  "${build_dir}/Stripe.xcframework.zip"

mv "${build_dir}/../build-3ds2/Stripe3DS2.xcframework.zip" "${build_dir}/Stripe3DS2.xcframework.zip"

set +ex

info "All good!"

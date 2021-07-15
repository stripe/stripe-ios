#!/bin/bash

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"

function info {
  echo "[$(basename "${0}")] [INFO] ${1}"
}

function die {
  echo "[$(basename "${0}")] [ERROR] ${1}"
  exit 1
}

# Clean build directory
build_dir="${root_dir}/build-3ds2"

info "Cleaning build directory..."

rm -rf "${build_dir}"
mkdir "${build_dir}"

# Compile and package dynamic framework

info "Compiling dynamic framework..."

cd "${root_dir}" || die "Executing \`cd\` failed"

set -ex

xcodebuild clean build \
  -quiet \
  -project "Stripe3DS2/Stripe3DS2.xcodeproj" \
  -scheme "Stripe3DS2" \
  -sdk "iphonesimulator" \
  -configuration Release \
  CONFIGURATION_BUILD_DIR="${build_dir}/sim" \
  OTHER_CFLAGS="-fembed-bitcode"

exit_code="${PIPESTATUS[0]}"

if [[ "${exit_code}" != 0 ]]; then
  die "xcodebuild exited with non-zero status code: ${exit_code}"
fi

xcodebuild clean build \
  -quiet \
  -project "Stripe3DS2/Stripe3DS2.xcodeproj" \
  -scheme "Stripe3DS2" \
  -sdk "iphoneos" \
  -configuration Release \
  CONFIGURATION_BUILD_DIR="${build_dir}/ios" \
  OTHER_CFLAGS="-fembed-bitcode"

exit_code="${PIPESTATUS[0]}"

if [[ "${exit_code}" != 0 ]]; then
  die "xcodebuild exited with non-zero status code: ${exit_code}"
fi

xcodebuild clean build \
  -quiet \
  -project "Stripe3DS2/Stripe3DS2.xcodeproj" \
  -scheme "Stripe3DS2" \
  -sdk "iphoneos" \
  -destination 'platform=macOS,variant=Mac Catalyst' \
  -configuration Release \
  CONFIGURATION_BUILD_DIR="${build_dir}/catalyst" \
  OTHER_CFLAGS="-fembed-bitcode"

exit_code="${PIPESTATUS[0]}"

if [[ "${exit_code}" != 0 ]]; then
  die "xcodebuild exited with non-zero status code: ${exit_code}"
fi

codesign_identity=$(security find-identity -v -p codesigning | grep Y28TH9SHX7 | grep -o -E '\w{40}' | head -n 1)
if [ -z "$codesign_identity" ]; then
  echo "Stripe Apple Distribution code signing certificate not found, Stripe3DS2.xcframework will not be signed."
  echo "Install one from Xcode Settings -> Accounts -> Manage Certificates."
else
  codesign -f --deep -s "$codesign_identity" "${build_dir}/catalyst/Stripe3DS2.framework"
  codesign -f --deep -s "$codesign_identity" "${build_dir}/ios/Stripe3DS2.framework"
  codesign -f --deep -s "$codesign_identity" "${build_dir}/sim/Stripe3DS2.framework"
fi

xcodebuild -create-xcframework -framework "${build_dir}/ios/Stripe3DS2.framework" -framework "${build_dir}/catalyst/Stripe3DS2.framework" -framework "${build_dir}/sim/Stripe3DS2.framework" -output "${build_dir}/Stripe3DS2.xcframework"

if [ -n "$codesign_identity" ]; then
  codesign -f --deep -s "$codesign_identity" "${build_dir}/Stripe3DS2.xcframework"
fi

set +ex

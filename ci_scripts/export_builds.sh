#!/bin/bash

# Options:
#   --only-static: Only compile the static framework target

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"

# Parse arguments
only_static=0

while [[ $# -gt 0 ]]; do
  parameter="$1"

  case "${parameter}" in
  --only-static)
    only_static=1
    ;;
  *)
    echo "ERROR: Unknown option: ${parameter}"
    exit 1
    ;;
  esac

  shift
done

# Verify xcpretty is installed
if ! command -v xcpretty > /dev/null; then
  echo "ERROR: Please install xcpretty before running export_builds.sh:"
  echo "https://github.com/supermarin/xcpretty#installation"
  exit 1
fi

# Clean build directory
build_dir="${root_dir}/build"

echo "Cleaning build directory..."

rm -rf "${build_dir}"
mkdir "${build_dir}"

# Compile and package dynamic framework
if [[ "${only_static}" == 0 ]]; then
  echo "Compiling and packaging dynamic framework..."

  cd "${root_dir}"

  set -ex

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
fi

# Compile static framework
echo "Compiling static framework..."

cd "${root_dir}"

xcodebuild clean build \
  -workspace "Stripe.xcworkspace" \
  -scheme "StripeiOSStaticFramework" \
  -configuration "Release" \
  OBJROOT="${build_dir}" \
  SYMROOT="${build_dir}" \
  | xcpretty

exit_code="${PIPESTATUS[0]}"

if [[ "${exit_code}" != 0 ]]; then
  echo "ERROR: xcodebuild exited with non-zero status code: ${exit_code}"
  exit 1
fi

# Package static framework
echo "Packaging static framework..."

set -ex

# - Use iphonesimulator output as base which contains all architecture slices anyway
cd "${build_dir}/Release-iphonesimulator"

lipo "Stripe.framework/Stripe" \
  -verify_arch "armv7" "arm64" "i386" "x86_64"

# - Strip any simulator fields from Info.plist to pass app store submission
plutil -remove "DTSDKName" "Stripe.bundle/Info.plist"
plutil -remove "DTPlatformName" "Stripe.bundle/Info.plist"
plutil -remove "CFBundleSupportedPlatforms" "Stripe.bundle/Info.plist"

# - Include bundle contents inside framework directory
mv "Stripe.bundle" "Stripe.framework"

# - Zip framework directory
ditto \
  -ck \
  --rsrc \
  --sequesterRsrc \
  --keepParent \
  "Stripe.framework" \
  "StripeiOS-Static.zip"

cp "StripeiOS-Static.zip" "${build_dir}"

set +ex

echo "All good!"

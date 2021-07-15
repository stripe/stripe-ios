#!/bin/bash

# JSON list of frameworks to export.
# - scheme: The scheme name in Stripe.xcworkspace
# - framework_name: The name of the framework that will be built (e.g. Stripe.xcframework)
#
# NOTE: Stripe3DS2 is built separately and should not be included in this list.
frameworks_to_archive='[
  {
    "scheme": "StripeiOS",
    "framework_name": "Stripe"
  },
  {
    "scheme": "StripeCore",
    "framework_name": "StripeCore"
  },
  {
    "scheme": "StripeIdentity",
    "framework_name": "StripeIdentity"
  }
]'

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

# Build Stripe3DS2
info "Building Stripe3DS2..."

"${root_dir}/stripe3ds2-support/ci_scripts/build_dynamic_xcframework.sh"

exit_code="${PIPESTATUS[0]}"
if [[ "${exit_code}" != 0 ]]; then
  die "Stripe3DS2 build exited with non-zero status code: ${exit_code}"
fi

frameworks_to_archive_arr=($(echo "${frameworks_to_archive}" | jq -c ".[]"))
for framework_json in ${frameworks_to_archive_arr[@]}
do
  set +ex

  scheme=$(echo "${framework_json}" | jq -r ".scheme")
  framework_name=$(echo "${framework_json}" | jq -r ".framework_name")

  info "Building ${scheme}..."

  # Build for iOS
  xcodebuild clean archive \
    -quiet \
    -workspace "Stripe.xcworkspace" \
    -destination="iOS" \
    -scheme "${scheme}" \
    -configuration "Release" \
    -archivePath "${build_dir}/${framework_name}-iOS.xcarchive" \
    -sdk iphoneos \
    SYMROOT="${build_dir}/${framework_name}-framework-ios" \
    OBJROOT="${build_dir}/${framework_name}-framework-ios" \
    SUPPORTS_MACCATALYST=NO \
    BUILD_LIBRARIES_FOR_DISTRIBUTION=YES \
    SKIP_INSTALL=NO

    exit_code="${PIPESTATUS[0]}"
    if [[ "${exit_code}" != 0 ]]; then
      die "xcodebuild exited with non-zero status code: ${exit_code}"
    fi

    # Build for Simulator
    xcodebuild clean archive \
      -quiet \
      -workspace "Stripe.xcworkspace" \
      -scheme "${scheme}" \
      -destination="iOS Simulator" \
      -configuration "Release" \
      -archivePath "${build_dir}/${framework_name}-sim.xcarchive" \
      -sdk iphonesimulator \
      SYMROOT="${build_dir}/${framework_name}-framework-sim" \
      OBJROOT="${build_dir}/${framework_name}-framework-sim" \
      SUPPORTS_MACCATALYST=NO \
      BUILD_LIBRARIES_FOR_DISTRIBUTION=YES \
      SKIP_INSTALL=NO


    exit_code="${PIPESTATUS[0]}"
    if [[ "${exit_code}" != 0 ]]; then
      die "xcodebuild exited with non-zero status code: ${exit_code}"
    fi

    # Build for MacOS
    xcodebuild clean archive \
      -quiet \
      -workspace "Stripe.xcworkspace" \
      -scheme "${scheme}" \
      -configuration "Release" \
      -archivePath "${build_dir}/${framework_name}-mac.xcarchive" \
      -sdk macosx \
      SYMROOT="${build_dir}/${framework_name}-framework-mac" \
      OBJROOT="${build_dir}/${framework_name}-framework-mac" \
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
      echo "Stripe Apple Distribution code signing certificate not found, "${framework_name}".xcframework will not be signed."
      echo "Install one from Xcode Settings -> Accounts -> Manage Certificates."
    else
      codesign -f --deep -s "$codesign_identity" "${build_dir}/${framework_name}-iOS.xcarchive/Products/Library/Frameworks/${framework_name}.framework"
      codesign -f --deep -s "$codesign_identity" "${build_dir}/${framework_name}-sim.xcarchive/Products/Library/Frameworks/${framework_name}.framework"
      codesign -f --deep -s "$codesign_identity" "${build_dir}/${framework_name}-mac.xcarchive/Products/Library/Frameworks/${framework_name}.framework"
    fi

    xcodebuild -create-xcframework \
    -framework "${build_dir}/${framework_name}-iOS.xcarchive/Products/Library/Frameworks/${framework_name}.framework" \
    -framework "${build_dir}/${framework_name}-sim.xcarchive/Products/Library/Frameworks/${framework_name}.framework" \
    -framework "${build_dir}/${framework_name}-mac.xcarchive/Products/Library/Frameworks/${framework_name}.framework" \
    -output "${build_dir}/${framework_name}.xcframework"

    if [ -n "$codesign_identity" ]; then
      codesign -f --deep -s "$codesign_identity" "${build_dir}/${framework_name}.xcframework"
    fi
done

mv "${build_dir}/../build-3ds2/Stripe3DS2.xcframework" "${build_dir}/"
cd "${build_dir}"

zip \
  -r \
  "Stripe.xcframework.zip" \
  *.xcframework

set +ex

info "All good!"

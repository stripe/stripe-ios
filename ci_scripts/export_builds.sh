#!/bin/bash

# Options:
#   --only-static: Only compile the static framework target

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
is_catalina=true
if [[ $(sw_vers -productVersion) == 10.14.* ]]; then
  # this'll break on 10.13-, but it's a lot easier to read than a real version number comparison
  is_catalina=false
fi

function info {
  echo "[$(basename "${0}")] [INFO] ${1}"
}

function die {
  echo "[$(basename "${0}")] [ERROR] ${1}"
  exit 1
}

# Parse arguments
only_static=0

while [[ $# -gt 0 ]]; do
  parameter="${1}"

  case "${parameter}" in
  --only-static)
    only_static=1
    ;;
  *)
    die "Unknown option: ${parameter}"
    ;;
  esac

  shift
done

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
if [[ "${only_static}" == 0 ]]; then
  info "Compiling and packaging dynamic framework..."

  cd "${root_dir}" || die "Executing \`cd\` failed"

  
  ln -s -f libStripe3DS2-ios.a "${root_dir}/InternalFrameworks/libStripe3DS2.a"

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
  
  if [[ $is_catalina == true ]]; then
	  ln -s -f libStripe3DS2-mac.a "${root_dir}/InternalFrameworks/libStripe3DS2.a"

	  xcodebuild clean archive \
	    -workspace "Stripe.xcworkspace" \
	    -scheme "StripeiOS" \
	    -configuration "Release" \
	    -archivePath "${build_dir}/Stripe-mac.xcarchive" \
	    -sdk macosx \
	    SYMROOT="${build_dir}/framework-mac" \
	    OBJROOT="${build_dir}/framework-mac" \
	    SUPPORTS_MACCATALYST=YES \
	    BUILD_LIBRARIES_FOR_DISTRIBUTION=YES \
	    SKIP_INSTALL=NO \
	    | xcpretty

	  ln -s -f libStripe3DS2-ios.a "${root_dir}/InternalFrameworks/libStripe3DS2.a"

	  exit_code="${PIPESTATUS[0]}"
	  if [[ "${exit_code}" != 0 ]]; then
	    die "xcodebuild exited with non-zero status code: ${exit_code}"
	  fi
  fi

  set -ex
  codesign_identity=$(security find-identity -v -p codesigning | grep Y28TH9SHX7 | grep -o -E '\w{40}' | head -n 1)
  if [ -z "$codesign_identity" ]; then
    echo "Stripe Apple Distribution code signing certificate not found, Stripe.xcframework will not be built."
    echo "Install one from Xcode Settings -> Accounts -> Manage Certificates."
  else
    codesign -f --deep -s "$codesign_identity" "${build_dir}/Stripe-iOS.xcarchive/Products/Library/Frameworks/Stripe.framework"
    codesign -f --deep -s "$codesign_identity" "${build_dir}/Stripe-sim.xcarchive/Products/Library/Frameworks/Stripe.framework"
    if [[ $is_catalina == true ]]; then
      codesign -f --deep -s "$codesign_identity" "${build_dir}/Stripe-mac.xcarchive/Products/Library/Frameworks/Stripe.framework"
    fi

    if [[ $is_catalina == true ]]; then
      xcodebuild -create-xcframework \
      -framework "${build_dir}/Stripe-iOS.xcarchive/Products/Library/Frameworks/Stripe.framework" \
      -framework "${build_dir}/Stripe-sim.xcarchive/Products/Library/Frameworks/Stripe.framework" \
      -framework "${build_dir}/Stripe-mac.xcarchive/Products/Library/Frameworks/Stripe.framework" \
      -output "${build_dir}/Stripe.xcframework"
    else
      xcodebuild -create-xcframework \
      -framework "${build_dir}/Stripe-iOS.xcarchive/Products/Library/Frameworks/Stripe.framework" \
      -framework "${build_dir}/Stripe-sim.xcarchive/Products/Library/Frameworks/Stripe.framework" \
      -output "${build_dir}/Stripe.xcframework"
    fi

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

fi

# Compile static framework
info "Compiling static framework..."

build_dir="${root_dir}/build-static"
info "Cleaning build directory..."

rm -rf "${build_dir}"

cd "${root_dir}" || die "Executing \`cd\` failed"
echo "${build_dir}"

xcodebuild clean build \
  -workspace "Stripe.xcworkspace" \
  -scheme "StripeiOSStaticFramework" \
  -configuration "Release" \
  OBJROOT="${build_dir}" \
  SYMROOT="${build_dir}" \
  SUPPORTS_MACCATALYST=NO \
  | xcpretty


exit_code="${PIPESTATUS[0]}"

if [[ "${exit_code}" != 0 ]]; then
  die "xcodebuild exited with non-zero status code: ${exit_code}"
fi

# Package static framework
info "Packaging static framework..."

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

info "All good!"

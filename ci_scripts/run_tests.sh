#!/bin/bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# Verify carthage is installed
if ! command -v carthage > /dev/null; then
  if [[ "${CI}" != "true" ]]; then
    die "Please install carthage: https://github.com/Carthage/Carthage#installing-carthage"
  fi

  info "Installing carthage..."
  brew install carthage || die "Executing \`brew install carthage\` failed"
fi

# Execute carthage bootstrap
info "Executing carthage bootstrap..."

cd "${script_dir}/.." || die "Executing \`cd\` failed"

carthage bootstrap --platform ios --cache-builds

if [[ "$?" != 0 ]]; then
  die "Executing carthage bootstrap exited with a non-zero status code"
fi

# Execute carthage bootstrap for example apps
info "Executing carthage bootstrap for example apps..."

cd "${script_dir}/../Example" || die "Executing \`cd\` failed"

carthage bootstrap --platform ios --cache-builds

if [[ "$?" != 0 ]]; then
  die "Executing carthage bootstrap for example apps exited with a non-zero status code"
fi

# Determine xcodebuild simulator destinations
destinations=(
  -destination "platform=iOS Simulator,name=iPhone 6,OS=8.4"
  -destination "platform=iOS Simulator,name=iPhone 6,OS=9.3"
  -destination "platform=iOS Simulator,name=iPhone 6,OS=10.3.1"
)

if xcodebuild -version | grep -q "Xcode 9"; then
  destinations+=("-destination")
  destinations+=("platform=iOS Simulator,name=iPhone 6,OS=11.0")
fi

# Execute xcodebuild for test target
info "Executing xcodebuild for test target..."

cd "${script_dir}/.." || die "Executing \`cd\` failed"

xcodebuild clean build-for-testing \
  -workspace "Stripe.xcworkspace" \
  -scheme "StripeiOS" \
  -configuration "Debug" \
  -sdk "iphonesimulator" \
  | xcpretty

xcodebuild_exit_code="${PIPESTATUS[0]}"

if [[ "${xcodebuild_exit_code}" != 0 ]]; then
  die "Executing xcodebuild failed with status code: ${xcodebuild_exit_code}"
fi

xcodebuild test-without-building \
  -workspace "Stripe.xcworkspace" \
  -scheme "StripeiOS" \
  -configuration "Debug" \
  -sdk "iphonesimulator" \
  "${destinations[@]}"
  # Multiple destination output not compatible with xcpretty

xcodebuild_exit_code="$?"

if [[ "${xcodebuild_exit_code}" != 0 ]]; then
  die "Executing xcodebuild failed with status code: ${xcodebuild_exit_code}"
fi

# Execute xcodebuild for example apps
info "Executing xcodebuild for example app targets..."

cd "${script_dir}/.." || die "Executing \`cd\` failed"

xcodebuild clean build \
  -workspace Stripe.xcworkspace \
  -scheme "UI Examples" \
  -sdk iphonesimulator \
  | xcpretty

xcodebuild_exit_code="${PIPESTATUS[0]}"

if [[ "${xcodebuild_exit_code}" != 0 ]]; then
  die "Executing xcodebuild failed with status code: ${xcodebuild_exit_code}"
fi

xcodebuild clean build \
  -workspace Stripe.xcworkspace \
  -scheme "Standard Integration (Swift)" \
  -sdk iphonesimulator \
  | xcpretty

xcodebuild_exit_code="${PIPESTATUS[0]}"

if [[ "${xcodebuild_exit_code}" != 0 ]]; then
  die "Executing xcodebuild failed with status code: ${xcodebuild_exit_code}"
fi

xcodebuild clean build \
  -workspace Stripe.xcworkspace \
  -scheme "Custom Integration (ObjC)" \
  -sdk iphonesimulator \
  | xcpretty

xcodebuild_exit_code="${PIPESTATUS[0]}"

if [[ "${xcodebuild_exit_code}" != 0 ]]; then
  die "Executing xcodebuild failed with status code: ${xcodebuild_exit_code}"
fi

info "All good!"

#!/usr/bin/env bash
# Checks that the `Identity` package trait resolves the Identity dependency.
#
#   with_objc  uses default traits, which enable Identity  -> must resolve it
#   with_swift links StripeIdentity and sets the trait     -> must resolve it
#
# This branch enables Identity by default while preserving explicit opt-in.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IDENTITY_PACKAGE="identity-ios-mediapipe"

resolved_packages() {
  local project_dir="$1"
  local derived_data
  derived_data="$(mktemp -d)"

  xcodebuild \
    -workspace "${ROOT}/Tests/installation_tests/swift_package_manager/${project_dir}/SPMTest.xcworkspace" \
    -scheme SPMTest \
    -destination 'generic/platform=iOS' \
    -derivedDataPath "${derived_data}" \
    -resolvePackageDependencies >/dev/null

  ls "${derived_data}/SourcePackages/checkouts" 2>/dev/null || true
}

echo "Checking that an app using default traits resolves the Identity dependency..."
if ! resolved_packages with_objc | grep -qx "${IDENTITY_PACKAGE}"; then
  echo "error: with_objc did not resolve '${IDENTITY_PACKAGE}' with Identity enabled by default." >&2
  exit 1
fi
echo "  ok"

echo "Checking that an Identity app with an explicit trait resolves it..."
if ! resolved_packages with_swift | grep -qx "${IDENTITY_PACKAGE}"; then
  echo "error: with_swift did not resolve '${IDENTITY_PACKAGE}' with the Identity trait on." >&2
  exit 1
fi
echo "  ok"

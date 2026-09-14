#!/usr/bin/env bash
# Checks that the `Identity` package trait controls the Identity dependency.
#
#   with_objc  links no Identity product and sets no trait  -> must NOT resolve it
#   with_swift links StripeIdentity and sets the trait      -> must resolve it
#
# Without this, someone could make the Identity dependency unconditional again
# and every Swift Package Manager consumer would silently fetch it.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IDENTITY_PACKAGE="stripe-mediapipe"

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

echo "Checking that a payments-only app does not resolve the Identity dependency..."
if resolved_packages with_objc | grep -qx "${IDENTITY_PACKAGE}"; then
  echo "error: with_objc resolved '${IDENTITY_PACKAGE}' with the Identity trait off." >&2
  echo "The Identity dependency must stay behind .when(traits: [\"Identity\"])." >&2
  exit 1
fi
echo "  ok"

echo "Checking that an Identity app does resolve it..."
if ! resolved_packages with_swift | grep -qx "${IDENTITY_PACKAGE}"; then
  echo "error: with_swift did not resolve '${IDENTITY_PACKAGE}' with the Identity trait on." >&2
  exit 1
fi
echo "  ok"

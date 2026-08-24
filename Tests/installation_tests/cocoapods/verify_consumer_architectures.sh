#!/bin/bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/../../.." && pwd)"
fixture_dir="${script_dir}/with_frameworks_swift"
test_dir="$(mktemp -d)"
architecture_setting='EXCLUDED_ARCHS[sdk=iphonesimulator*] = x86_64'

trap 'rm -rf "${test_dir}"' EXIT

function die {
  echo "[$(basename "${0}")] [ERROR] ${1}"
  exit 1
}

function verify_setting {
  local target="${1}"
  local expected="${2}"

  for configuration in debug release; do
    local xcconfig="${test_dir}/Pods/Target Support Files/Pods-${target}/Pods-${target}.${configuration}.xcconfig"

    [[ -f "${xcconfig}" ]] || die "Missing generated xcconfig: ${xcconfig}"

    if [[ "${expected}" == "present" ]]; then
      grep -Fq "${architecture_setting}" "${xcconfig}" || die "${target} ${configuration} does not exclude x86_64"
    elif grep -Fq "${architecture_setting}" "${xcconfig}"; then
      die "${target} ${configuration} unexpectedly excludes x86_64"
    fi
  done
}

cp -R "${fixture_dir}/CocoapodsTest.xcodeproj" "${test_dir}/"

cat > "${test_dir}/Podfile" <<EOF
project 'CocoapodsTest.xcodeproj'
use_frameworks!

abstract_target 'LocalPodspecs' do
  platform :ios, '15.0'
  # Resolve unpublished release versions locally without adding these pods to an asserted target.
  pod 'StripeApplePay', path: '${repo_root}'
  pod 'StripeCameraCore', path: '${repo_root}'
  pod 'StripeCore', path: '${repo_root}'
  pod 'StripeFinancialConnectionsLite', path: '${repo_root}'
  pod 'StripeIdentity', path: '${repo_root}'
  pod 'StripePaymentSheet', path: '${repo_root}'
  pod 'StripePayments', path: '${repo_root}'
  pod 'StripePaymentsUI', path: '${repo_root}'
  pod 'StripeUICore', path: '${repo_root}'
end

target 'CocoapodsTest' do
  platform :ios, '15.0'
  pod 'StripeIdentity', path: '${repo_root}'
end

target 'CocoapodsTestTests' do
  platform :ios, '15.0'
  # Keep CryptoOnramp isolated so Identity is resolved only through its dependency graph.
  pod 'StripeCryptoOnramp', path: '${repo_root}'
end

target 'TestExtension' do
  platform :ios, '15.0'
  pod 'StripeCore', path: '${repo_root}'
end
EOF

(
  cd "${test_dir}"
  pod install --no-repo-update
)

verify_setting 'CocoapodsTest' 'present'
verify_setting 'CocoapodsTestTests' 'present'
verify_setting 'TestExtension' 'absent'

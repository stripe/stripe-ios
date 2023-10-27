#!/bin/bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function info {
  echo "[$(basename "${0}")] [INFO] ${1}"
}

function die {
  echo "[$(basename "${0}")] [ERROR] ${1}"
  exit 1
}

# Commit generated xcode project files.
git add Stripe.xcworkspace -f &&
  git add Stripe*/*.xcodeproj -f &&
  git add Example/**/*.xcodeproj -f &&
  git add Testers/**/*.xcodeproj -f &&
  git add -u &&
  git commit -m "Commit xcode project files temporarily"

# Clean carthage artifacts
info "Cleaning carthage artifacts..."

xcodebuild -scheme CarthageTest -project "${script_dir}/CarthageTest.xcodeproj" clean
rm -f "${script_dir}/Cartfile"
rm -f "${script_dir}/Cartfile.resolved"
rm -rf "${script_dir}/Carthage"

# Generate new Cartfile
info "Generating new Cartfile..."

git_repo="$(cd "${script_dir}/../../../" && pwd)"
git_hash="$(git rev-parse HEAD)"

echo "git \"${git_repo}\" \"${git_hash}\"" > "${script_dir}/Cartfile"

# Execute carthage bootstrap
info "Executing carthage bootstrap..."

cd "${script_dir}" || die "Executing \`cd\` failed"

carthage bootstrap --platform ios --no-use-binaries --cache-builds --use-xcframeworks

carthage_exit_code="$?"

# Undo the temporarily committed xcode project files.
git reset HEAD~

if [[ "${carthage_exit_code}" != 0 ]]; then
  die "Executing carthage bootstrap failed with status code: ${carthage_exit_code}"
fi

info "All good!"

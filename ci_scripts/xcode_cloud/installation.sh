#!/bin/bash
set -euo pipefail

# These compile the app, extension and test targets without requiring a runtime
# on the build worker. Run behavioral installation tests as native Test actions.
for variant in without_frameworks_objc with_frameworks_objc with_frameworks_swift; do
    project_dir="Tests/installation_tests/cocoapods/$variant"
    # Use the locked CocoaPods gem; setup.sh can upgrade the global installation.
    (cd "$project_dir" && bundle exec pod install --no-repo-update)
    xcodebuild build-for-testing -workspace "$project_dir/CocoapodsTest.xcworkspace" \
        -scheme CocoapodsTest -destination 'generic/platform=iOS Simulator' \
        -derivedDataPath "build/xcode-cloud-installation/$variant" \
        CODE_SIGNING_ALLOWED=NO SWIFT_SUPPRESS_WARNINGS=YES SWIFT_TREAT_WARNINGS_AS_ERRORS=NO
done

for variant in with_objc with_swift; do
    xcodebuild build-for-testing \
        -workspace "Tests/installation_tests/swift_package_manager/$variant/SPMTest.xcworkspace" \
        -scheme SPMTest -destination 'generic/platform=iOS Simulator' \
        -derivedDataPath "build/xcode-cloud-installation/spm-$variant" \
        CODE_SIGNING_ALLOWED=NO SWIFT_SUPPRESS_WARNINGS=YES SWIFT_TREAT_WARNINGS_AS_ERRORS=NO
done
./ci_scripts/check_spm_identity_trait.sh

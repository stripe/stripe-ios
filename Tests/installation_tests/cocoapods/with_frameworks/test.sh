#!/bin/sh

# This causes the script to fail if any subscript fails
set -e
set -o pipefail

echo "Checking test CocoaPods app (with frameworks)..."
cd $(dirname $0)

gem install xcpretty --no-ri --no-rdoc
gem update cocoapods --no-ri --no-rdoc

rm -rf Pods
rm -f Podfile.lock
pod install --no-repo-update && xcodebuild build -workspace CocoapodsTest.xcworkspace -scheme CocoapodsTest -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 6,OS=latest' | xcpretty -c

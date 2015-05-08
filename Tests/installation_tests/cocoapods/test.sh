#!/bin/sh

echo "Checking test Cocoapods app..."
cd $(dirname $0)
rm -rf Pods
rm Podfile.lock
pod install --no-repo-update && set -o pipefail && xctool build -workspace CocoapodsTest.xcworkspace -scheme CocoapodsTest -sdk iphonesimulator

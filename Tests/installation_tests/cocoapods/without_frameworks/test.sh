#!/bin/sh

echo "Checking test CocoaPods app..."
cd $(dirname $0)

rm -rf Pods
rm -f Podfile.lock
pod install --no-repo-update && xctool build -workspace CocoapodsTest.xcworkspace -scheme CocoapodsTest -sdk iphonesimulator

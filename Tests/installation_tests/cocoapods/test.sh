#!/bin/sh

echo "Checking test Cocoapods app..."
cd $(dirname $0)
pod install && set -o pipefail && xcodebuild build -workspace CocoapodsTest.xcworkspace -scheme CocoapodsTest -sdk iphonesimulator -configuration Release | xcpretty -c

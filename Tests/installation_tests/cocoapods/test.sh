#!/bin/sh

echo "Checking test Cocoapods app..."
cd $(dirname $0)
pod install && set -o pipefail && xcodebuild build -workspace CocoapodsTest.xcworkspace -scheme CocoapodsTest -sdk iphonesimulator -configuration Release ONLY_ACTIVE_ARCH=NO ARCHS=x86_64 | xcpretty -c

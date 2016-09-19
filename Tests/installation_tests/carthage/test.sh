#!/bin/sh

# This causes the script to fail if any subscript fails
set -e
set -o pipefail

echo "Checking test Carthage app..."

gem install xcpretty --no-ri --no-rdoc

TESTDIR="$(cd $(dirname $0); pwd)"
cd $TESTDIR

GIT_REPO=`cd "../../.."; pwd`
cd $TESTDIR

GIT_BRANCH=${TRAVIS_COMMIT-`git branch | sed -n '/\* /s///p'`}

rm -f "$TESTDIR/Cartfile*"
echo "git \"$GIT_REPO\" \"$GIT_BRANCH\"" > "$TESTDIR/Cartfile"

carthage bootstrap --platform ios --configuration Debug --no-use-binaries

xcodebuild build -project "${TESTDIR}/CarthageTest.xcodeproj" -scheme CarthageTest -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 6,OS=latest' | xcpretty -c

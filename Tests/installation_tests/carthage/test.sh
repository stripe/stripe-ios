#!/bin/sh

echo "Checking test Carthage app..."

carthage version

TESTDIR="$(cd $(dirname $0); pwd)"
cd $TESTDIR

GIT_REPO=`cd "../../.."; pwd`
cd $TESTDIR

GIT_BRANCH=${TRAVIS_COMMIT-`git branch | sed -n '/\* /s///p'`}

rm -f "$TESTDIR/Cartfile*"
echo "git \"$GIT_REPO\" \"$GIT_BRANCH\"" > "$TESTDIR/Cartfile"

carthage bootstrap --platform ios --configuration Debug --no-use-binaries --verbose CODE_SIGN_IDENTITY=""

xctool build -project "$TESTDIR/CarthageTest.xcodeproj" -scheme CarthageTest -sdk iphonesimulator

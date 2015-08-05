#!/bin/sh

echo "Checking test Carthage app (with frameworks)..."

TESTDIR="$(cd $(dirname $0); pwd)"
echo $TESTDIR
cd $TESTDIR

GIT_REPO=`cd "../../.."; pwd`
cd $TESTDIR

GIT_BRANCH=${TRAVIS_COMMIT-`git branch | sed -n '/\* /s///p'`}

rm -f "$TESTDIR/Cartfile*"
echo "git \"$GIT_REPO\" \"$GIT_BRANCH\"" > "$TESTDIR/Cartfile"

carthage update

xctool build -project "$TESTDIR/CarthageTest.xcodeproj" -scheme CarthageTest -sdk iphonesimulator

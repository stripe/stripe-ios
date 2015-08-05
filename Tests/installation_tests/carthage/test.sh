#!/bin/sh

echo "Checking test Carthage app (with frameworks)..."

TESTDIR="$(cd $(dirname $0); pwd)"

cd $(dirname $0)

export FAUXPAS_SKIP=true

GIT_REPO=`cd "../../.."; pwd`
cd -

GIT_BRANCH=`git branch | sed -n '/\* /s///p'`

rm -f Cartfile*
echo "git \"$GIT_REPO\" \"$GIT_BRANCH\"" > Cartfile

carthage update

xctool build -project "$TESTDIR/CarthageTest.xcodeproj" -scheme CarthageTest -sdk iphonesimulator

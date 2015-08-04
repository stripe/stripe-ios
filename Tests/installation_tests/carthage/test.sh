#!/bin/sh

echo "Checking test Carthage app (with frameworks)..."
cd $(dirname $0)

brew install carthage

GIT_REPO=`cd "../../.."; pwd`
cd -

GIT_BRANCH=`git branch | sed -n '/\* /s///p'`

rm -f Cartfile*
echo "git \"$GIT_REPO\" \"$GIT_BRANCH\"" > Cartfile

carthage update

xctool build -project CarthageTest.xcodeproj -target CarthageTest -sdk iphonesimulator

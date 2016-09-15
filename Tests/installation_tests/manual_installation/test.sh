#!/bin/sh

# This causes the script to fail if any subscript fails
set -e
set -o pipefail

echo "Checking test manual installation app..."

gem install xcpretty --no-ri --no-rdoc

PROJECTDIR="$(cd $(dirname $0)/../../..; pwd)"
TESTDIR="$(cd $(dirname $0); pwd)"
BUILDDIR=$PROJECTDIR/build
FRAMEWORKDIR=$TESTDIR/ManualInstallationTest/Frameworks

sh $PROJECTDIR/ci_scripts/export_builds.sh --only-static

sh $PROJECTDIR/ci_scripts/validate_zip.sh $BUILDDIR/StripeiOS-Static.zip

rm -rf $FRAMEWORKDIR
mkdir $FRAMEWORKDIR
cp $BUILDDIR/StripeiOS-Static.zip $FRAMEWORKDIR
ditto -xk $FRAMEWORKDIR/StripeiOS-Static.zip $FRAMEWORKDIR

xcodebuild test -project "${TESTDIR}/ManualInstallationTest.xcodeproj" -scheme ManualInstallationTest -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 6,OS=latest' | xcpretty -c

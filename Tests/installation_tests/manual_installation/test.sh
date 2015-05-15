#!/bin/sh

echo "Checking test manual installation app..."

PROJECTDIR="$(cd $(dirname $0)/../../..; pwd)"
BUILDDIR="$(cd $(dirname $0); pwd)/build"

rm -rf $BUILDDIR
mkdir $BUILDDIR

xcodebuild build -workspace "${PROJECTDIR}/Stripe.xcworkspace" -scheme StripeiOSStaticFramework -configuration Release OBJROOT=$BUILDDIR SYMROOT=$BUILDDIR | xcpretty -c

rm -rf ./ManualInstallationTest/Frameworks/Stripe.framework
mv $BUILDDIR/Release-iphonesimulator/Stripe.framework ./ManualInstallationTest/Frameworks

set -o pipefail && xcodebuild build -project ManualInstallationTest.xcodeproj/ | xcpretty -c
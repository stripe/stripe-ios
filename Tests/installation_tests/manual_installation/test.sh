#!/bin/sh

echo "Checking test manual installation app..."

PROJECTDIR="$(cd $(dirname $0)/../../..; pwd)"
BUILDDIR="$(cd $(dirname $0); pwd)/build"

rm -rf $BUILDDIR
mkdir $BUILDDIR

xcodebuild build -workspace "${PROJECTDIR}/Stripe.xcworkspace" -scheme StripeiOSStaticFramework -configuration Release OBJROOT=$BUILDDIR SYMROOT=$BUILDDIR -sdk iphonesimulator | xcpretty -c

rm -rf ./ManualInstallationTest/Frameworks/Stripe.framework
mv $BUILDDIR/Release-iphonesimulator/Stripe.framework ./ManualInstallationTest/Frameworks

xctool build -project ManualInstallationTest.xcodeproj -scheme ManualInstallationTest -sdk iphonesimulator

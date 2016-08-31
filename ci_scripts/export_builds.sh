#!/bin/bash
# Options: --only-static: only build the static framework target

if [[ $# -gt 0 ]]
then
	ONLY_STATIC=1
else
	ONLY_STATIC=0
fi

PROJECTDIR="$(cd $(dirname $0)/..; pwd)"
BUILDDIR="${PROJECTDIR}/build"
CARTHAGEDIR="${PROJECTDIR}/Carthage/Build/iOS"
rm -rf $BUILDDIR
mkdir $BUILDDIR
cd $PROJECTDIR

# Dynamic framework
if [ $ONLY_STATIC = 0 ]
then
	echo "building dynamic framework..."
	carthage build --no-skip-current --platform iOS --configuration Release
	cd $CARTHAGEDIR
	ditto -ck --rsrc --sequesterRsrc --keepParent Stripe.framework Stripe.framework.zip
	mv Stripe.framework.zip $BUILDDIR
	cd -
fi

# Static framework
echo "building static framework..."
xcodebuild build -workspace Stripe.xcworkspace -scheme StripeiOSStaticFramework -configuration Release OBJROOT=$BUILDDIR SYMROOT=$BUILDDIR | xcpretty -c
cd $BUILDDIR/Release-iphonesimulator
plutil -remove DTSDKName Stripe.bundle/Info.plist
plutil -remove DTPlatformName Stripe.bundle/Info.plist
plutil -remove CFBundleSupportedPlatforms Stripe.bundle/Info.plist
mv Stripe.bundle Stripe.framework
ditto -ck --rsrc --sequesterRsrc --keepParent Stripe.framework StripeiOS-Static.zip
rm -rf Stripe.framework
rm -rf Stripe.bundle
cp StripeiOS-Static.zip $BUILDDIR
cd -

PROJECTDIR="$(cd $(dirname $0)/..; pwd)"
BUILDDIR="${PROJECTDIR}/build"
rm -rf $BUILDDIR
mkdir $BUILDDIR
cd $PROJECTDIR

# Dynamic framework
xcodebuild build -workspace Stripe.xcworkspace -scheme StripeiOS -configuration Release OBJROOT=$BUILDDIR SYMROOT=$BUILDDIR | xcpretty -c
cd $BUILDDIR/Release-iphoneos
ditto -ck --rsrc --sequesterRsrc --keepParent Stripe.framework Stripe.framework.zip
rm -rf Stripe.framework
cp Stripe.framework.zip $BUILDDIR
cd -

# Static framework
xcodebuild build -workspace Stripe.xcworkspace -scheme StripeiOSStaticFramework -configuration Release OBJROOT=$BUILDDIR SYMROOT=$BUILDDIR | xcpretty -c
cd $BUILDDIR/Release-iphonesimulator
mv Stripe.bundle Stripe.framework
ditto -ck --rsrc --sequesterRsrc --keepParent Stripe.framework StripeiOS-Static.zip
rm -rf Stripe.framework
rm -rf Stripe.bundle
cp StripeiOS-Static.zip $BUILDDIR
cd -

PROJECTDIR="$(cd $(dirname $0)/..; pwd)"
BUILDDIR="${PROJECTDIR}/build"
CARTHAGEDIR="${PROJECTDIR}/Carthage/Build/iOS"
rm -rf $BUILDDIR
mkdir $BUILDDIR
cd $PROJECTDIR

# Dynamic framework
carthage build --no-skip-current --platform iOS --configuration Release
cd $CARTHAGEDIR
ditto -ck --rsrc --sequesterRsrc --keepParent Stripe.framework Stripe.framework.zip
mv Stripe.framework.zip $BUILDDIR
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

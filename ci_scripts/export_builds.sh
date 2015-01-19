BUILDDIR="${PWD}/build"

xcodebuild build -workspace Stripe.xcworkspace -scheme StripeOSX -configuration Release OBJROOT=$BUILDDIR SYMROOT=$BUILDDIR | xcpretty -c
cd $BUILDDIR/Release
mkdir StripeOSX
mv StripeOSX.framework StripeOSX
ditto -ck --rsrc --sequesterRsrc --keepParent StripeOSX StripeOSX.zip
cp StripeOSX.zip $BUILDDIR
cd -

xcodebuild build -workspace Stripe.xcworkspace -scheme StripeiOSStaticFramework -configuration Release OBJROOT=$BUILDDIR SYMROOT=$BUILDDIR | xcpretty -c
cd $PWD/build/Release-iphonesimulator
mkdir StripeiOS
mv Stripe.framework StripeiOS
ditto -ck --rsrc --sequesterRsrc --keepParent StripeiOS StripeiOS.zip
cp StripeiOS.zip $BUILDDIR
cd -

xcodebuild build -workspace Stripe.xcworkspace -scheme StripeiOSStaticFrameworkWithoutApplePay -configuration Release OBJROOT=$BUILDDIR SYMROOT=$BUILDDIR | xcpretty -c
cd $PWD/build/Release-iphonesimulator
mkdir StripeiOS-WithoutApplePay
mv Stripe.framework StripeiOS-WithoutApplePay
ditto -ck --rsrc --sequesterRsrc --keepParent StripeiOS-WithoutApplePay StripeiOS-WithoutApplePay.zip
cp StripeiOS-WithoutApplePay.zip $BUILDDIR
cd -

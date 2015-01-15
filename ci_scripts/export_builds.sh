BUILDDIR="${PWD}/build"

xcodebuild build -workspace Stripe.xcworkspace -scheme StripeOSX -configuration Release OBJROOT=$BUILDDIR SYMROOT=$BUILDDIR | xcpretty -c
cd $BUILDDIR/Release
zip -r StripeOSX.zip Stripe.framework
cp StripeOSX.zip $BUILDDIR
cd -

xcodebuild build -workspace Stripe.xcworkspace -scheme StripeiOSStaticFramework -configuration Release OBJROOT=$BUILDDIR SYMROOT=$BUILDDIR | xcpretty -c
cd $PWD/build/Release-iphonesimulator
zip -r StripeiOS.zip Stripe.framework
cp StripeiOS.zip $BUILDDIR
cd -

xcodebuild build -workspace Stripe.xcworkspace -scheme StripeiOSStaticFrameworkWithoutApplePay -configuration Release OBJROOT=$BUILDDIR SYMROOT=$BUILDDIR | xcpretty -c
cd $PWD/build/Release-iphonesimulator
zip -r StripeiOS-WithoutApplePay.zip Stripe.framework
cp StripeiOS-WithoutApplePay.zip $BUILDDIR
cd -

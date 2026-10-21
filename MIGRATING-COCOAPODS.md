# Migrate the Stripe iOS SDK off CocoaPods

Our last CocoaPods release of the Stripe iOS SDK, 26.15.0, shipped October 19, 2026. Going forward, we'll publish new features and fixes only through Swift Package Manager and XCFrameworks, because [CocoaPods trunk becomes read-only](https://blog.cocoapods.org/CocoaPods-Specs-Repo/) on December 2, 2026.

Your app will keep working, but it won't receive SDK updates unless you switch to Swift Package Manager (recommended) or add the XCFrameworks manually.

## Remove the Stripe pod

Whichever option you choose, start by removing the Stripe pod.

1. Delete the `pod Stripe…` lines from your `Podfile` for each Stripe module you use.
2. Run `pod install`.

If Stripe is your only pod, you can remove CocoaPods entirely. Commit your changes first, then run `pod deintegrate`, delete the `Podfile`, `Podfile.lock`, and `.xcworkspace` files, and open your project with the `.xcodeproj` file.

## Switch to Swift Package Manager

1. In Xcode, go to **File > Add Package Dependencies**.
2. Enter `https://github.com/stripe/stripe-ios-spm` as the repository URL.
3. Select the latest version from our [releases page](https://github.com/stripe/stripe-ios/releases).
4. Add the modules you use to [your app’s target](https://developer.apple.com/documentation/swift_packages/adding_package_dependencies_to_your_app).

## Or add the frameworks manually

1. Download `Stripe.xcframework.zip` for the latest release from our [GitHub releases page](https://github.com/stripe/stripe-ios/releases/latest) and unzip it.
2. Drag each framework you use, such as `StripePaymentSheet.xcframework`, into **Frameworks, Libraries, and Embedded Content** in your target's **General** settings. Select **Copy items if needed**.
3. Add any other frameworks listed in the [manual linking guide](https://github.com/stripe/stripe-ios/blob/master/StripePaymentSheet/README.md#manual-linking).

To upgrade manually in the future, repeat these steps with the new release.

## FAQ

### Q: When did Stripe stop publishing the iOS SDK through CocoaPods?

Our last CocoaPods release, 26.15.0, shipped October 19, 2026. Going forward, we'll publish new features and fixes only through Swift Package Manager and XCFrameworks.

### Q: What about the Flutter SDK?

Update to the latest version of the Stripe Flutter SDK and enable Swift Package Manager support in Flutter.

### Q: What about the React Native SDK?

The Stripe React Native SDK has built-in support for Swift Package Manager. To make sure your React Native app is ready, follow the [migration guide](https://github.com/stripe/stripe-react-native/blob/master/MIGRATING.md#ios-swift-package-manager-dependency-resolution-and-dynamic-linking).

### Q: Will my app stop working?

No, your app will continue to work with whichever version of the SDK you've already integrated. That said, we strongly recommend migrating away from CocoaPods, as we won't be able to deliver fixes if the SDK stops working with a future iOS or Xcode release. Through Swift Package Manager and XCFrameworks, we will continue shipping new features, improvements, and fixes.

### Q: Will my CI stop working for older branches of my app?

At this time, CocoaPods intends to maintain a read-only copy of the Specs repo for the foreseeable future. Older versions of the SDK will continue to be accessible to CI until CocoaPods shuts down.

### Q: Swift Package Manager is much slower than CocoaPods when downloading the Stripe iOS SDK. Is there a way to improve the performance?

Use our Swift Package Manager mirror at <https://github.com/stripe/stripe-ios-spm>. This mirror only contains the files needed to build the Stripe SDK, and is significantly smaller than the main repository.

### I have a question that wasn't answered here.

Please [file an issue on GitHub](https://github.com/stripe/stripe-ios/issues).

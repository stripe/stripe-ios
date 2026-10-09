
# Migrating from CocoaPods

On December 2, 2026, [CocoaPods Trunk will become read-only](https://blog.cocoapods.org/CocoaPods-Specs-Repo/). Your app will continue to work, but after October 26 Stripe will ship future features and fixes exclusively through Swift Package Manager and XCFrameworks. To continue to receive the latest updates for the Stripe iOS SDK, switch to Swift Package Manager or manually embed the Stripe XCFrameworks.

## Removing CocoaPods

We recommend fully removing CocoaPods from your project. To do so:

1. Run `pod deintegrate` in your project directory.
2. Delete the `Podfile`, `Podfile.lock`, and `.xcworkspace` files.
3. Open your project using the `.xcodeproj` file directly.

To keep CocoaPods and only remove the Stripe pod:

1. Delete the `pod Stripe…` lines from your `Podfile` for each Stripe module your project uses.
2. Run `pod install` to update your project.

## Switching to Swift Package Manager

We recommend adding the Stripe iOS SDK to your project through Swift Package Manager since it provides faster and simpler setup and upgrades.

1. In Xcode, go to **File > Add Package Dependencies**.
2. Enter `https://github.com/stripe/stripe-ios-spm` as the repository URL.
3. Select the latest version number from our [releases page](https://github.com/stripe/stripe-ios/releases).
4. Add the modules you use to [your app’s target](https://developer.apple.com/documentation/swift_packages/adding_package_dependencies_to_your_app).

## Switching to manual frameworks

Alternatively, you can add the Stripe iOS SDK to your project by manually adding the prebuilt frameworks.

1. Go to our [GitHub releases page](https://github.com/stripe/stripe-ios/releases/latest), download the `Stripe.xcframework.zip` for the latest release, and unzip it.
2. Drag `StripePaymentSheet.xcframework` (or the framework of your choice) to the **Frameworks, Libraries, and Embedded Content** section of the **General** settings in your Xcode project. Make sure to select **Copy items if needed**.
3. Repeat step 2 for all required frameworks listed in the [manual linking guide](https://github.com/stripe/stripe-ios/blob/master/StripePaymentSheet/README.md#manual-linking).
4. To upgrade to a new release in the future, repeat steps 1–3.

## FAQ

### Q: When will Stripe stop publishing the iOS SDK through CocoaPods?

We plan to ship our final CocoaPods release on October 26. This gives us time before the CocoaPods trunk goes read-only in case fixes for critical issues are necessary.

### Q: What about the Flutter SDK?

Update to the latest version of the Stripe Flutter SDK and enable Swift Package Manager support in Flutter.

### Q: What about the React Native SDK?

The Stripe React Native SDK has built-in support for Swift Package Manager. To make sure your React Native app is ready, follow the migration guide.

### Q: Will my app stop working?

No, your app will continue to work with whichever version of the SDK you've already integrated. That said, we strongly recommend migrating away from CocoaPods, as we won't be able to deliver fixes if the SDK stops working with a future iOS or Xcode release. Through Swift Package Manager, we will continue shipping new features, improvements, and fixes.

### Q: Will my CI stop working for older branches of my app?

At this time, CocoaPods intends to maintain a read-only copy of the Specs repo for the foreseeable future. Older versions of the SDK will continue to be accessible to CI until CocoaPods shuts down.

### Q: Swift Package Manager is much slower than CocoaPods when downloading the Stripe iOS SDK. Is there a way to improve the performance?

Use our Swift Package Manager mirror at <https://github.com/stripe/stripe-ios-spm>. This mirror only contains the files needed to build the Stripe SDK, and is significantly smaller than the main repository.

### I have a question that wasn't answered here.

Please file an issue or reach out to Stripe Support.
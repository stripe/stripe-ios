# Stripe iOS SDK

[![Travis](https://img.shields.io/travis/stripe/stripe-ios/master.svg?style=flat)](https://travis-ci.org/stripe/stripe-ios)
[![CocoaPods](https://img.shields.io/cocoapods/v/Stripe.svg?style=flat)](http://cocoapods.org/?q=author%3Astripe%20name%3Astripe)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods](https://img.shields.io/cocoapods/l/Stripe.svg?style=flat)](https://github.com/stripe/stripe-ios/blob/master/LICENSE)
[![CocoaPods](https://img.shields.io/cocoapods/p/Stripe.svg?style=flat)](https://github.com/stripe/stripe-ios#)

The Stripe iOS SDK makes it quick and easy to build an excellent payment experience in your iOS app. We provide powerful and customizable UI screens and elements that can be used out-of-the-box to collect your users' payment details. We also expose the low-level APIs that power those UIs so that you can build fully custom experiences. See our [iOS Integration Guide](https://stripe.com/docs/mobile/ios) to get started!

> Note: We've greatly simplified the integration for `STPPaymentContext` in [v11.0.0](https://github.com/stripe/stripe-ios/releases/v11.0.0). If you integrated `STPPaymentContext` prior to this and you're interested in migrating, please see our [migration guide](https://github.com/stripe/stripe-ios/blob/master/MIGRATING.md#migration-from-versions--1100).

### Features

**Simplified Security**: We make it simple for you to collect sensitive data such as credit card numbers by [tokenizing payment information](https://stripe.com/docs/quickstart#collecting-payment-information). This means the sensitive data is sent directly to Stripe instead of passing through your server. For more information, please see our [Integration Security Guide](https://stripe.com/docs/security).

**Apple Pay**: We provide a seamless integration with Apple Pay that will allow your customers to pay using payment methods from their Wallet. For more information, please see our [Apple Pay](https://stripe.com/apple-pay) page. We also have a tutorial for our [Apple Pay Utilities](https://stripe.com/docs/mobile/ios/custom#apple-pay).

**Native UI**: We provide out-of-the-box native screens and elements so that you can get started quickly without having to think about designing the right interfaces. See our [Standard Integration Guide](https://stripe.com/docs/mobile/ios/standard) for the most hands off approach. Please see our [Custom Integration Guide](https://stripe.com/docs/mobile/ios/custom) if you want a little more control.

**Card Scanning**: We support card scanning capabilities using card.io. See our [Card IO](#card-io) section.

## Releases

We recommend that you install the Stripe iOS SDK using a package manager such as [Cocoapods or Carthage](https://stripe.com/docs/mobile/ios#getting-started). If you prefer to link the library manually, please use a version from our [releases](https://github.com/stripe/stripe-ios/releases) page because we consider the master branch to be unstable.

If you're reading this on GitHub.com, please make sure you are looking at the [tagged version](https://github.com/stripe/stripe-ios/tags) that corresponds to the release you have installed. Otherwise, the instructions and example code may be mismatched with your copy. You can read the latest tagged version of this README and browse the associated code on GitHub using
[this link](https://github.com/stripe/stripe-ios/tree/v15.0.0).

## Requirements

The Stripe iOS SDK is compatible with apps supporting iOS 9 and above and requires Xcode 9 to build from source.

## Getting Started

### Integration

Please see our [iOS Integration Guide](https://stripe.com/docs/mobile/ios) which explains everything from SDK installation, to tokenizing payment information, to Apple Pay integration, and more. For more fine-grained documentation for all of the classes and methods, please see our full [Stripe iOS SDK Reference](http://stripe.github.io/stripe-ios/docs/index.html).

### Examples

There are 3 example apps included in the repository:

- [**UI Examples** Example/UI Examples/README.md ](/Example/UI%20Examples/README.md)
- [**Standard Integration (Swift)** Example/Standard Integration (Swift)/README.md](/Example/Standard%20Integration%20%28Swift%29/README.md)
- [**Custom Integration (ObjC)** Example/Custom Integration (Swift)/README.md](/Example/Custom%20Integration%20%28ObjC%29/README.md)

## Card IO

To add card scanning capabilities to our prebuilt UI components, you can simply [install card.io](https://github.com/card-io/card.io-iOS-SDK#setup) alongside our SDK. You'll also need to set `NSCameraUsageDescription` in your application's plist, and provide a reason for accessing the camera (e.g. "To scan cards").

To try this out, you can run `./install_cardio.rb`, which will download and install card.io in Standard Integration (Swift). Now, when you run the example app on a device, you'll see a "Scan Card" button when adding a new card.

## Contributing

We welcome contributions of any kind including new features, bug fixes, and documentation improvements. Please first open an issue describing what you want to build if it is a major change so that we can discuss how to move forward. Otherwise, go ahead and open a pull request for minor changes such as typo fixes and one liners.

### Running Tests

1. Install Carthage (if you have homebrew installed, `brew install carthage`)
2. From the root of the repo, install test dependencies by running `carthage bootstrap --platform ios --configuration Release --no-use-binaries`
3. Open Stripe.xcworkspace
4. Choose the "StripeiOS" scheme with the iPhone 6, iOS 11.2 simulator (required for snapshot tests to pass)
5. Run Product -> Test

## Migrating from Older Versions

See [MIGRATING.md](https://github.com/stripe/stripe-ios/blob/master/MIGRATING.md)

# Stripe iOS SDK

[![Travis](https://img.shields.io/travis/stripe/stripe-ios/master.svg?style=flat)](https://travis-ci.org/stripe/stripe-ios)
[![CocoaPods](https://img.shields.io/cocoapods/v/Stripe.svg?style=flat)](http://cocoapods.org/?q=author%3Astripe%20name%3Astripe)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License](https://img.shields.io/cocoapods/l/Stripe.svg?style=flat)](https://github.com/stripe/stripe-ios/blob/master/LICENSE)
[![Platform](https://img.shields.io/cocoapods/p/Stripe.svg?style=flat)](https://github.com/stripe/stripe-ios#)

The Stripe iOS SDK makes it quick and easy to build an excellent payment experience in your iOS app. We provide powerful and customizable UI screens and elements that can be used out-of-the-box to collect your users' payment details. We also expose the low-level APIs that power those UIs so that you can build fully custom experiences.

Get started with our [📚 integration guides](https://stripe.com/docs/payments/accept-a-payment?platform=ios) and [example projects](#examples), or [📘 browse the SDK reference](https://stripe.dev/stripe-ios/docs/index.html).

> Updating to a newer version of the SDK? See our [migration guide](https://github.com/stripe/stripe-ios/blob/master/MIGRATING.md) and [changelog](https://github.com/stripe/stripe-ios/blob/master/CHANGELOG.md).

Table of contents
=================

<!--ts-->
   * [Features](#features)
   * [Releases](#releases)
   * [Requirements](#requirements)
   * [Getting Started](#getting-started)
      * [Integration](#integration)
      * [Examples](#examples)
   * [Card scanning](#card-scanning-beta)
   * [Contributing](#contributing)
   * [Migrating](#migrating-from-older-versions)
<!--te-->

## Features

**Simplified Security**: We make it simple for you to collect sensitive data such as credit card numbers and remain [PCI compliant](https://stripe.com/docs/security#pci-dss-guidelines). This means the sensitive data is sent directly to Stripe instead of passing through your server. For more information, see our [Integration Security Guide](https://stripe.com/docs/security).

**Apple Pay**: We provide a [seamless integration with Apple Pay](https://stripe.com/docs/apple-pay).

**SCA-Ready**: The SDK automatically performs native [3D Secure authentication](https://stripe.com/docs/payments/3d-secure) if needed to comply with [Strong Customer Authentication](https://stripe.com/docs/strong-customer-authentication) regulation in Europe.

**Stripe API**: We provide [low-level APIs](https://stripe.dev/stripe-ios/docs/Classes/STPAPIClient.html) that correspond to objects and methods in the Stripe API. You can build your own entirely custom UI on top of this layer, while still taking advantage of utilities like [STPCardValidator](https://stripe.dev/stripe-ios/docs/Classes/STPCardValidator.html) to validate your user’s input.

**Native UI**: We provide native screens and elements to collect payment details. For example, [PaymentSheet](https://stripe.com/docs/payments/accept-a-payment?platform=ios) is a prebuilt UI that combines all the steps required to pay - collecting payment details, billing details, and confirming the payment  - into a single sheet that displays on top of your app.

**Card scanning**: We support card scanning on iOS 13 and higher. See our [Card scanning](#card-scanning-beta) section.

## Releases

We support Cocoapods, Carthage, and Swift Package Manager. If you link the library manually, use a version from our [releases](https://github.com/stripe/stripe-ios/releases) page. Make sure to embed both `Stripe.xcframework` and `Stripe3DS2.xcframework`.

If you're reading this on GitHub.com, please make sure you are looking at the [tagged version](https://github.com/stripe/stripe-ios/tags) that corresponds to the release you have installed. Otherwise, the instructions and example code may be mismatched with your copy. You can read the latest tagged version of this README and browse the associated code on GitHub using
[this link](https://github.com/stripe/stripe-ios/tree/21.6.0).

## Requirements

The Stripe iOS SDK requires Xcode 11 or later and is compatible with apps targeting iOS 11 or above. We support Catalyst on macOS 10.15 or later.

For iOS 10 support, please use [v19.4.0](https://github.com/stripe/stripe-ios/tree/v19.4.0). If you need to support iOS 9, use [v17.0.2](https://github.com/stripe/stripe-ios/tree/v17.0.2).

## Getting Started

### Integration

Get started with our [📚 integration guides](https://stripe.com/docs/payments/accept-a-payment?platform=ios) and [example projects](#examples), or [📘 browse the SDK reference](https://stripe.dev/stripe-ios/docs/index.html) for fine-grained documentation of all the classes and methods in the SDK.

### Examples

- [Prebuilt UI](https://github.com/stripe/stripe-ios/tree/21.6.0/Example/PaymentSheet%20Example)
  - This example demonstrates how to build a payment flow using our prebuilt UI component integration [`PaymentSheet`](https://stripe.dev/stripe-ios/docs/Classes/PaymentSheet.html).
- [Non-Card Payment Examples](https://github.com/stripe/stripe-ios/tree/21.6.0/Example/Non-Card%20Payment%20Examples)
  - This example demonstrates how to use `STPAPIClient` to manually accept various non-card payment methods.

## Card scanning 

Our new [PaymentSheet](https://stripe.com/docs/payments/accept-a-payment?platform=ios) UI offers built-in card scanning. To enable card scanning, you'll need to set `NSCameraUsageDescription` in your application's plist, and provide a reason for accessing the camera (e.g. "To scan cards"). Card scanning is supported on devices with iOS 13 or higher.

You can demo this feature in our [PaymentSheet example app](https://github.com/stripe/stripe-ios/tree/21.6.0/Example/PaymentSheet%20Example). When you run the example app on a device, you'll see a "Scan Card" button when adding a new card.

## Contributing

We welcome contributions of any kind including new features, bug fixes, and documentation improvements. Please first open an issue describing what you want to build if it is a major change so that we can discuss how to move forward. Otherwise, go ahead and open a pull request for minor changes such as typo fixes and one liners.

### Running Tests

1. Install Carthage 0.37 or later (if you have homebrew installed, `brew install carthage`)
2. From the root of the repo, run `bundle install && bundle exec fastlane main_tests`. This will install the test dependencies and run the tests.
3. Once you have run this once, you can also run the tests in Xcode from the `StripeiOS` target in `Stripe.xcworkspace`. Make sure to use the iPhone 8, iOS 13.7 simulator so the snapshot tests will pass.

## Migrating from Older Versions

See [MIGRATING.md](https://github.com/stripe/stripe-ios/blob/master/MIGRATING.md)

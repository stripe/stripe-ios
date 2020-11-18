# Stripe iOS SDK

[![Travis](https://img.shields.io/travis/stripe/stripe-ios/master.svg?style=flat)](https://travis-ci.org/stripe/stripe-ios)
[![CocoaPods](https://img.shields.io/cocoapods/v/Stripe.svg?style=flat)](http://cocoapods.org/?q=author%3Astripe%20name%3Astripe)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License](https://img.shields.io/cocoapods/l/Stripe.svg?style=flat)](https://github.com/stripe/stripe-ios/blob/master/LICENSE)
[![Platform](https://img.shields.io/cocoapods/p/Stripe.svg?style=flat)](https://github.com/stripe/stripe-ios#)

The Stripe iOS SDK makes it quick and easy to build an excellent payment experience in your iOS app. We provide powerful and customizable UI screens and elements that can be used out-of-the-box to collect your users' payment details. We also expose the low-level APIs that power those UIs so that you can build fully custom experiences. 

Get started with our [📚 integration guides](https://stripe.com/docs/payments) and [example projects](#examples), or [📘 browse the SDK reference](https://stripe.dev/stripe-ios/docs/index.html).

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

**Native UI**: We provide native screens and elements to collect payment and shipping details. For example, [STPPaymentCardTextField](https://stripe.dev/stripe-ios/docs/Classes/STPPaymentCardTextField.html) is a UIView that collects and validates card details:

<p align="center">
<img src="https://raw.githubusercontent.com/stripe/stripe-ios/11d293baa9b753234816367a5bbdc4ac5ad04af6/card-field.gif" width="300" height="56" alt="STPPaymentCardTextField" align="center">
</p>

You can use these individually, or take all of the prebuilt UI in one flow by following the [Basic Integration guide](https://stripe.com/docs/mobile/ios/basic).

<p align="center">
<img src="https://raw.githubusercontent.com/stripe/stripe-ios/11d293baa9b753234816367a5bbdc4ac5ad04af6/add-card-vc.png" width="200" alt="STPAddCardViewController" hspace="20"><img src="https://raw.githubusercontent.com/stripe/stripe-ios/11d293baa9b753234816367a5bbdc4ac5ad04af6/payment-options.png" width="200" alt="STPPaymentOptionsViewController" hspace="20"><img src="https://raw.githubusercontent.com/stripe/stripe-ios/11d293baa9b753234816367a5bbdc4ac5ad04af6/shipping-address.png" width="200" alt="STPShippingAddressViewController" hspace="20">
</p>

From left to right: [STPAddCardViewController](https://stripe.dev/stripe-ios/docs/Classes/STPAddCardViewController.html), [STPPaymentOptionsViewController](https://stripe.dev/stripe-ios/docs/Classes/STPPaymentOptionsViewController.html), [STPShippingAddressViewController](https://stripe.dev/stripe-ios/docs/Classes/STPShippingAddressViewController.html)

**Card scanning**: We support card scanning on iOS 13 and higher. See our [Card scanning](#card-scanning-beta) section.

## Releases

We support Cocoapods and Swift Package Manager. If you link the library manually, use a version from our [releases](https://github.com/stripe/stripe-ios/releases) page.

If you're reading this on GitHub.com, please make sure you are looking at the [tagged version](https://github.com/stripe/stripe-ios/tags) that corresponds to the release you have installed. Otherwise, the instructions and example code may be mismatched with your copy. You can read the latest tagged version of this README and browse the associated code on GitHub using
[this link](https://github.com/stripe/stripe-ios/tree/20.1.1).

## Requirements

The Stripe iOS SDK requires Xcode 12.2 or later and is compatible with apps targeting iOS 11 or above. We support Catalyst on macOS 10.15 or later.

If you need to compile your app using Xcode 11.7, please use [v20.1.1](https://github.com/stripe/stripe-ios/tree/v20.1.1). For iOS 10 support, please use [v19.4.0](https://github.com/stripe/stripe-ios/tree/v19.4.0). If you need to support iOS 9, use [v17.0.2](https://github.com/stripe/stripe-ios/tree/v17.0.2).

## Getting Started

### Integration

Get started with our [📚 integration guides](https://stripe.com/docs/payments) and [example projects](#examples), or [📘 browse the SDK reference](https://stripe.dev/stripe-ios/docs/index.html) for fine-grained documentation of all the classes and methods in the SDK.

### Examples

There are 3 example apps included in the repository:

- [UI Examples](https://github.com/stripe/stripe-ios/tree/20.1.1/Example/UI%20Examples).
  - This example lets you quickly try out the SDK's prebuilt UI components using a mock backend—just build and run!
- [Basic Integration](https://github.com/stripe/stripe-ios/tree/20.1.1/Example/Basic%20Integration)
  - This example demonstrates how to build a payment flow using our prebuilt UI component integration (`STPPaymentContext`).
- [Non-Card Payment Examples](https://github.com/stripe/stripe-ios/tree/20.1.1/Example/Non-Card%20Payment%20Examples)
  - This example demonstrates how to use `STPAPIClient` to accept various non-card payment methods.

Check out [stripe-samples](https://github.com/stripe-samples/) for more, including:

- [Accepting a card payment](https://github.com/stripe-samples/accept-a-card-payment) (PaymentIntents API)
- [Saving a card without payment](https://github.com/stripe-samples/mobile-saving-card-without-payment) (SetupIntents API)
- [Accepting a card payment](https://github.com/stripe-samples/card-payment-charges-api) (Charges API)


## Card scanning (Beta)

To add card scanning capabilities to our prebuilt UI components, set the `cardScanningEnabled` option on your `STPPaymentConfiguration`. You'll also need to set `NSCameraUsageDescription` in your application's plist, and provide a reason for accessing the camera (e.g. "To scan cards"). Card scanning is supported on devices with iOS 13 or higher.

<p align="center">
<img src="https://user-images.githubusercontent.com/52758633/92628867-4d040200-f282-11ea-95d2-023d9a461d25.gif" width="222" height="458" alt="Card Scanning Demo" align="center">
</p>

Demo this in our [Basic Integration example app](https://github.com/stripe/stripe-ios/tree/20.1.1/Example/Basic%20Integration). When you run the example app on a device, you'll see a "Scan Card" button when adding a new card.

This feature is currently in beta. Please file bugs on our [GitHub issues page](https://github.com/stripe/stripe-ios/issues).

## Contributing

We welcome contributions of any kind including new features, bug fixes, and documentation improvements. Please first open an issue describing what you want to build if it is a major change so that we can discuss how to move forward. Otherwise, go ahead and open a pull request for minor changes such as typo fixes and one liners.

### Running Tests

1. Install Carthage (if you have homebrew installed, `brew install carthage`)
2. From the root of the repo, install test dependencies by running `carthage bootstrap --platform ios --configuration Release --no-use-binaries` (If you're using Xcode 12, you'll need to run `setup-carthage-for-xcode-12.sh` instead. This will be removed once Carthage adds support for Xcode 12.)
3. Open Stripe.xcworkspace
4. Choose the "StripeiOS" scheme with the iPhone 8, iOS 13.7 simulator (required for snapshot tests to pass)
5. Run Product -> Test

## Migrating from Older Versions

See [MIGRATING.md](https://github.com/stripe/stripe-ios/blob/master/MIGRATING.md)

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
   * [Card IO](#card-io)
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

**Card Scanning**: We support card scanning capabilities using card.io. See our [Card IO](#card-io) section.

## Releases

We recommend installing the Stripe iOS SDK using a package manager such as Cocoapods or Carthage. If you link the library manually, use a version from our [releases](https://github.com/stripe/stripe-ios/releases) page.

If you're reading this on GitHub.com, please make sure you are looking at the [tagged version](https://github.com/stripe/stripe-ios/tags) that corresponds to the release you have installed. Otherwise, the instructions and example code may be mismatched with your copy. You can read the latest tagged version of this README and browse the associated code on GitHub using
[this link](https://github.com/stripe/stripe-ios/tree/v19.3.0).

## Requirements

The Stripe iOS SDK requires Xcode 10.1 or later and is compatible with apps targeting iOS 10 or above. Please use [v17.0.2](https://github.com/stripe/stripe-ios/tree/v17.0.2) if you need to support iOS 9.

## Getting Started

### Integration


Get started with our [📚 integration guides](https://stripe.com/docs/payments) and [example projects](#examples), or [📘 browse the SDK reference](https://stripe.dev/stripe-ios/docs/index.html) for fine-grained documentation of all the classes and methods in the SDK.

### Examples

There are 3 example apps included in the repository:

- [UI Examples](https://github.com/stripe/stripe-ios/tree/v19.3.0/Example/UI%20Examples).
  - This example lets you quickly try out the SDK's prebuilt UI components using a mock backend—just build and run!
- [Basic Integration](https://github.com/stripe/stripe-ios/tree/v19.3.0/Example/Basic%20Integration)
  - This example demonstrates how to build a payment flow using our prebuilt UI component integration (`STPPaymentContext`).
- [Non-Card Payment Examples](https://github.com/stripe/stripe-ios/tree/v19.3.0/Example/Non-Card%20Payment%20Examples)
  - This example demonstrates how to use `STPAPIClient` to accept various non-card payment methods.

Check out [stripe-samples](https://github.com/stripe-samples/) for more, including:

- [Accepting a card payment](https://github.com/stripe-samples/accept-a-card-payment) (PaymentIntents API)
- [Saving a card without payment](https://github.com/stripe-samples/mobile-saving-card-without-payment) (SetupIntents API)
- [Accepting a card payment](https://github.com/stripe-samples/card-payment-charges-api) (Charges API)


## Card IO

To add card scanning capabilities to our prebuilt UI components, [install card.io](https://github.com/card-io/card.io-iOS-SDK#setup) alongside our SDK. You'll also need to set `NSCameraUsageDescription` in your application's plist, and provide a reason for accessing the camera (e.g. "To scan cards").

Demo this in our [Basic Integration example app](https://github.com/stripe/stripe-ios/tree/v19.3.0/Example/Basic&20Integration) by running `./install_cardio.rb`, which will download and install card.io in the project. Now, when you run the example app on a device, you'll see a "Scan Card" button when adding a new card.

## Contributing

We welcome contributions of any kind including new features, bug fixes, and documentation improvements. Please first open an issue describing what you want to build if it is a major change so that we can discuss how to move forward. Otherwise, go ahead and open a pull request for minor changes such as typo fixes and one liners.

### Running Tests

1. Install Carthage (if you have homebrew installed, `brew install carthage`)
2. From the root of the repo, install test dependencies by running `carthage bootstrap --platform ios --configuration Release --no-use-binaries`
3. Open Stripe.xcworkspace
4. Choose the "StripeiOS" scheme with the iPhone 7, iOS 12.2 simulator (required for snapshot tests to pass)
5. Run Product -> Test

## Migrating from Older Versions

See [MIGRATING.md](https://github.com/stripe/stripe-ios/blob/master/MIGRATING.md)

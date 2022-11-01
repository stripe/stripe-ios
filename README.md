# Stripe iOS SDK

[![Travis](https://img.shields.io/travis/stripe/stripe-ios/master.svg?style=flat)](https://travis-ci.org/stripe/stripe-ios)
[![CocoaPods](https://img.shields.io/cocoapods/v/Stripe.svg?style=flat)](http://cocoapods.org/?q=author%3Astripe%20name%3Astripe)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License](https://img.shields.io/cocoapods/l/Stripe.svg?style=flat)](https://github.com/stripe/stripe-ios/blob/master/LICENSE)
[![Platform](https://img.shields.io/cocoapods/p/Stripe.svg?style=flat)](https://github.com/stripe/stripe-ios#)

The Stripe iOS SDK makes it quick and easy to build an excellent payment experience in your iOS app. We provide powerful and customizable UI screens and elements that can be used out-of-the-box to collect your users' payment details. We also expose the low-level APIs that power those UIs so that you can build fully custom experiences.

Get started with our [📚 integration guides](https://stripe.com/docs/payments/accept-a-payment?platform=ios) and [example projects](#examples), or [📘 browse the SDK reference](https://stripe.dev/stripe-ios/docs/index.html).

Learn about our [Stripe Identity iOS SDK](StripeIdentity/README.md) to verify the identity of your users on iOS.

> Updating to a newer version of the SDK? See our [migration guide](https://github.com/stripe/stripe-ios/blob/master/MIGRATING.md) and [changelog](https://github.com/stripe/stripe-ios/blob/master/CHANGELOG.md).

Table of contents
=================

<!--ts-->
   * [Features](#features)
   * [Releases](#releases)
   * [Requirements](#requirements)
   * [Getting started](#getting-started)
      * [Integration](#integration)
      * [Examples](#examples)
   * [Card scanning](#card-scanning)
   * [Contributing](#contributing)
   * [Migrating](#migrating-from-older-versions)
   * [Licenses](#licenses)

<!--te-->

## Features

**Simplified security**: We make it simple for you to collect sensitive data such as credit card numbers and remain [PCI compliant](https://stripe.com/docs/security#pci-dss-guidelines). This means the sensitive data is sent directly to Stripe instead of passing through your server. For more information, see our [integration security guide](https://stripe.com/docs/security).

**Apple Pay**: [StripeApplePay](StripeApplePay/README.md) provides a [seamless integration with Apple Pay](https://stripe.com/docs/apple-pay).

**SCA-ready**: The SDK automatically performs native [3D Secure authentication](https://stripe.com/docs/payments/3d-secure) if needed to comply with [Strong Customer Authentication](https://stripe.com/docs/strong-customer-authentication) regulation in Europe.

**Native UI**: We provide native screens and elements to collect payment details. For example, [PaymentSheet](https://stripe.com/docs/payments/accept-a-payment?platform=ios) is a prebuilt UI that combines all the steps required to pay - collecting payment details, billing details, and confirming the payment - into a single sheet that displays on top of your app.

<img src="https://user-images.githubusercontent.com/89988962/153276097-9b3369a0-e732-45c4-96ec-ff9d48ad0fb6.png" alt="PaymentSheet" align="center"/>

**Stripe API**: [StripePayments](StripePayments/README.md) provides [low-level APIs](https://stripe.dev/stripe-ios/docs/Classes/STPAPIClient.html) that correspond to objects and methods in the Stripe API. You can build your own entirely custom UI on top of this layer, while still taking advantage of utilities like [STPCardValidator](https://stripe.dev/stripe-ios/docs/Classes/STPCardValidator.html) to validate your user’s input.

**Card scanning**: We support card scanning on iOS 13 and higher. See our [Card scanning](#card-scanning) section.

**App Clips**: The `StripeApplePay` module provides a [lightweight SDK for offering Apple Pay in an App Clip](https://stripe.com/docs/apple-pay#app-clips).

**Localized**: We support the following localizations: Bulgarian, Catalan, Chinese (Hong Kong), Chinese (Simplified), Chinese (Traditional), Croatian, Czech, Danish, Dutch, English (US), English (United Kingdom), Estonian, Filipino, Finnish, French, French (Canada), German, Greek, Hungarian, Indonesian, Italian, Japanese, Korean, Latvian, Lithuanian, Malay, Maltese, Norwegian Bokmål, Norwegian Nynorsk (Norway), Polish, Portuguese, Portuguese (Brazil), Romanian, Russian, Slovak, Slovenian, Spanish, Spanish (Latin America), Swedish, Turkish, Thai and Vietnamese.

#### Recommended usage

If you're selling digital products or services that will be consumed within your app, (e.g. subscriptions, in-game currencies, game levels, access to premium content, or unlocking a full version), you must use Apple's in-app purchase APIs. See the [App Store review guidelines](https://developer.apple.com/app-store/review/guidelines/#payments) for more information. For all other scenarios you can use this SDK to process payments via Stripe.

#### Privacy

The Stripe iOS SDK collects data to help us improve our products and prevent fraud. This data is never used for advertising and is not rented, sold, or given to advertisers. Our full privacy policy is available at [https://stripe.com/privacy](https://stripe.com/privacy).

For help with Apple's App Privacy Details form in App Store Connect, visit [Stripe iOS SDK Privacy Details](https://support.stripe.com/questions/stripe-ios-sdk-privacy-details).

## Modules
|Module|Description|Compressed|Uncompressed|
|------|-----------|----------|------------|
|StripePaymentSheet|Stripe's [prebuilt payment UI](https://stripe.com/docs/payments/accept-a-payment?platform=ios&ui=payment-sheet).|2.7MB|6.3MB|
|Stripe|Contains all the below frameworks, plus [Issuing](https://stripe.com/docs/issuing/cards/digital-wallets?platform=iOS) and [Basic Integration](/docs/mobile/ios/basic).|2.3MB|5.1MB|
|StripeApplePay|[Apple Pay support](/docs/apple-pay), including `STPApplePayContext`.|0.4MB|1.0MB|
|StripePayments|Bindings for the Stripe Payments API.|1.0MB|2.6MB|
|StripePaymentsUI|Bindings for the Stripe Payments API, [STPPaymentCardTextField](https://stripe.com/docs/payments/accept-a-payment?platform=ios&ui=custom), STPCardFormView, and other UI elements.|1.7MB|3.9MB|

## Releases

We support Cocoapods, Carthage, and Swift Package Manager.

If you link the library manually, use a version from our [releases](https://github.com/stripe/stripe-ios/releases) page and make sure to embed <ins>all</ins> of the required frameworks.

For the `Stripe` module, link the following frameworks:
- `Stripe.xcframework`
- `Stripe3DS2.xcframework`
- `StripeApplePay.xcframework`
- `StripePayments.xcframework`
- `StripePaymentsUI.xcframework`
- `StripeCore.xcframework`
- `StripeUICore.xcframework`

For other modules, follow the instructions below:
- [StripePaymentSheet](StripePaymentSheet/README.md#manual-linking)
- [StripePayments](StripePayments/README.md#manual-linking)
- [StripePaymentsUI](StripePaymentsUI/README.md#manual-linking)
- [StripeApplePay](StripeApplePay/README.md#manual-linking)
- [StripeIdentity](StripeIdentity/README.md#manual-linking)

If you're reading this on GitHub.com, please make sure you are looking at the [tagged version](https://github.com/stripe/stripe-ios/tags) that corresponds to the release you have installed. Otherwise, the instructions and example code may be mismatched with your copy.

## Requirements

The Stripe iOS SDK requires Xcode 13.2.1 or later and is compatible with apps targeting iOS 13 or above. We support Catalyst on macOS 10.16 or later.

For iOS 12 support, please use [v22.8.4](https://github.com/stripe/stripe-ios/tree/v22.8.4). For iOS 11 support, please use [v21.13.0](https://github.com/stripe/stripe-ios/tree/v21.13.0). For iOS 10, please use [v19.4.0](https://github.com/stripe/stripe-ios/tree/v19.4.0). If you need to support iOS 9, use [v17.0.2](https://github.com/stripe/stripe-ios/tree/v17.0.2).

Requirements for the **Stripe Identity iOS SDK** can be found [here](StripeIdentity/README.md#requirements).

## Getting started

### Integration

Get started with our [📚 integration guides](https://stripe.com/docs/payments/accept-a-payment?platform=ios) and [example projects](/Example), or [📘 browse the SDK reference](https://stripe.dev/stripe-ios/docs/index.html) for fine-grained documentation of all the classes and methods in the SDK.

### Examples

- [Prebuilt UI](Example/PaymentSheet%20Example) (Recommended)
  - This example demonstrates how to build a payment flow using [`PaymentSheet`](https://stripe.com/docs/payments/accept-a-payment?platform=ios), an embeddable native UI component that lets you accept [10+ payment methods](https://stripe.com/docs/payments/payment-methods/integration-options#payment-method-product-support) with a single integration.

- [Non-Card Payment Examples](Example/Non-Card%20Payment%20Examples)
  - This example demonstrates how to manually accept various payment methods using the Stripe API.

## Card scanning

[PaymentSheet](https://stripe.com/docs/payments/accept-a-payment?platform=ios) offers built-in card scanning. To enable card scanning, you'll need to set `NSCameraUsageDescription` in your application's plist, and provide a reason for accessing the camera (e.g. "To scan cards"). Card scanning is supported on devices with iOS 13 or higher.

You can demo this feature in our [PaymentSheet example app](Example/PaymentSheet%20Example). When you run the example app on a device, you'll see a "Scan Card" button when adding a new card.

## Contributing

We welcome contributions of any kind including new features, bug fixes, and documentation improvements. Please first open an issue describing what you want to build if it is a major change so that we can discuss how to move forward. Otherwise, go ahead and open a pull request for minor changes such as typo fixes and one liners.

### Running tests

1. Install Carthage 0.37 or later (if you have homebrew installed, `brew install carthage`)
2. From the root of the repo, run `bundle install && bundle exec fastlane stripeios_tests`. This will install the test dependencies and run the tests.
3. Once you have run this once, you can also run the tests in Xcode from the `StripeiOS` target in `Stripe.xcworkspace`. Make sure to use the iPhone 12 mini, iOS 15.4 simulator so the snapshot tests will pass.

## Migrating from older versions

See [MIGRATING.md](https://github.com/stripe/stripe-ios/blob/master/MIGRATING.md)

## Licenses

- [Stripe iOS SDK License](LICENSE)

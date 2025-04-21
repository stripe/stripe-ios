# <img src="../readme-images/Connect.svg" width="40" /> Stripe Connect iOS SDK

Use Connect embedded components to add connected account dashboard functionality to your app. The Stripe Connect iOS SDK and supporting API allow you to grant your users access to Stripe products directly in your dashboard.

> **Private preview**
>
> Access to the StripeConnect iOS SDK is currently invite only and is limited to only certain connected account types. To request an invitation and get the latest information on supported account types, see our [iOS integration guide](https://docs.stripe.com/connect/get-started-connect-embedded-components?platform=ios).

## Table of contents
<!-- NOTE: Use case-sensitive anchor links for docc compatibility -->
<!--ts-->
* [Supported components](#Supported-components)
* [Requirements](#Requirements)
* [Getting started](#Getting-started)
   * [Integration](#Integration)
   * [Example](Example)
* [Manual linking](#Manual-linking)

<!--te-->

## Supported components

The following Connect embedded components are supported in the iOS SDK:

* [**Account onboarding**](https://docs.stripe.com/connect/supported-embedded-components/account-onboarding?platform=ios): Show a localized onboarding form that validates data.
* [**Payouts**](https://docs.stripe.com/connect/supported-embedded-components/payouts?platform=ios): Show payout information and allow your users to perform payouts.

## Requirements

The `StripeConnect` module is compatible with apps targeting iOS 15.0 or above.

## Getting started

### Integration

Get started with Connect embedded components [📚 iOS integration guide](https://docs.stripe.com/connect/get-started-connect-embedded-components?platform=ios) and [example project](../Example/StripeConnectExample), or [📘 browse the SDK reference](https://stripe.dev/stripe-ios/stripe-connect/index.html) for fine-grained documentation of all the classes and methods in the SDK.

The Connect SDK requires access to the device's camera to capture identity documents. To enable your app to request camera permissions, set `NSCameraUsageDescription` in your app's plist and provide a reason for accessing the camera (e.g. "This app uses the camera to take a picture of your identity documents").

### Example
[StripeConnect Example](../Example/StripeConnectExample) – This example demonstrates how to integrate connect embedded components in your app.

## Manual linking

If you link the Stripe Connect library manually, use a version from our [releases](https://github.com/stripe/stripe-ios/releases) page and make sure to embed <ins>all</ins> of the following frameworks:
- `StripeConnect.xcframework`
- `StripeCore.xcframework`
- `StripeFinancialConnections.xcframework`
- `StripeUICore.xcframework`

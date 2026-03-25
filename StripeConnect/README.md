# <img src="../readme-images/Connect.svg" width="40" /> Stripe Connect iOS SDK

Use Connect embedded components to add connected account dashboard functionality to your app. The Stripe Connect iOS SDK and supporting API allow you to grant your users access to Stripe products directly in your dashboard.

## Table of contents

<!-- NOTE: Use case-sensitive anchor links for docc compatibility -->
<!--ts-->

- [Supported components](#Supported-components)
- [Requirements](#Requirements)
- [Getting started](#Getting-started)
  - [Integration](#Integration)
  - [Example](#Example)
- [Manual linking](#Manual-linking)

<!--te-->

## Supported components

The following Connect embedded component is supported in the iOS SDK:

- [**Account onboarding**](https://docs.stripe.com/connect/supported-embedded-components/account-onboarding?platform=ios): Show a localized onboarding form that validates data.
- [**Payments**](https://docs.stripe.com/connect/supported-embedded-components/payments?platform=ios): Shows payments and allows users to view payment details and manage disputes.
- [**Payouts**](https://docs.stripe.com/connect/supported-embedded-components/payouts?platform=ios): Shows payouts and allows your users to perform payouts.

## Requirements

The `StripeConnect` module is compatible with apps targeting iOS 15.0 or above.

## Getting started

### Integration

Get started with Connect embedded components [📚 iOS integration guide](https://docs.stripe.com/connect/get-started-connect-embedded-components?platform=ios) and [example project](../Example/StripeConnectExample), or [📘 browse the SDK reference](https://stripe.dev/stripe-ios/stripe-connect/index.html) for fine-grained documentation of all the classes and methods in the SDK.

#### Camera permission requirement

The Connect SDK requires you to add `NSCameraUsageDescription` to your app's Info.plist, even if you only use components that don't access the camera (such as Payments). However, the SDK will **not** prompt users for camera permissions unless it needs to access the camera (e.g., for identity verification during account onboarding). If your app only uses Payments components, users will never be prompted for camera access.

To satisfy this requirement, add `NSCameraUsageDescription` to your Info.plist with an appropriate message, such as: "This app may use the camera to verify identity documents during account setup."

### Example

[StripeConnect Example](../Example/StripeConnectExample) – This example demonstrates how to integrate connect embedded components in your app.

## Manual linking

If you link the Stripe Connect library manually, use a version from our [releases](https://github.com/stripe/stripe-ios/releases) page and make sure to embed <ins>all</ins> of the following frameworks:

- `StripeConnect.xcframework`
- `StripeCore.xcframework`
- `StripeFinancialConnections.xcframework`
- `StripeUICore.xcframework`

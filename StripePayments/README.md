# StripePayments iOS SDK module

The StripePayments module contains bindings for the Stripe Payments API.

If you need to accept card payments, we advise using the [StripePaymentSheet](../StripePaymentSheet/README.md) or [StripePaymentsUI](../StripePaymentsUI/README.md) module. For more information, visit our [integration security guide](https://stripe.com/docs/security/guide).

## Table of contents

<!--ts-->
* [Requirements](#requirements)
* [Getting started](#getting-started)
   * [Integration](#integration)
   * [Example](#example)
* [Manual linking](#manual-linking)

<!--te-->

### Requirements

The StripePayments module is compatible with apps targeting iOS 13.0 or above.

### Getting started

#### Integration

Get started with our [📚 integration guides](https://stripe.com/docs/payments/payment-methods/overview) and [example projects](/Example), or [📘 browse the SDK reference](https://stripe.dev/stripe-ios/stripe-payments/index.html) for fine-grained documentation of all the classes and methods in the SDK.

#### Example

- [Non-Card Payment Examples](/Example/Non-Card%20Payment%20Examples)
  - This example demonstrates how to manually accept various payment methods using the Stripe API.

## Manual linking

If you link this library manually, use a version from our [releases](https://github.com/stripe/stripe-ios/releases) page and make sure to embed <ins>all</ins> of the following frameworks:
- `StripeCore.xcframework`
- `Stripe3DS2.xcframework`
- `StripePayments.xcframework`

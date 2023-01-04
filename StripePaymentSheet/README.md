# StripePaymentSheet iOS SDK module

PaymentSheet is a prebuilt UI that combines all the steps required to pay - collecting payment details, billing details, and confirming the payment - into a single sheet that displays on top of your app.

## Table of contents

<!--ts-->
* [Features](#features)
* [Requirements](#requirements)
* [Getting started](#getting-started)
   * [Integration](#integration)
   * [Example](#example)
* [Manual linking](#manual-linking)

<!--te-->

## Requirements

The StripePaymentSheet module is compatible with apps targeting iOS 13.0 or above.

## Getting started

### Integration

Get started with our [📚 integration guides](https://stripe.com/docs/payments/accept-a-payment?platform=ios&ui=payment-sheet) and [example projects](/Example), or [📘 browse the SDK reference](https://stripe.dev/stripe-ios/stripe-paymentsheet/index.html) for fine-grained documentation of all the classes and methods in the SDK.

### Example

- [Prebuilt UI](Example/PaymentSheet%20Example)
  - This example demonstrates how to build a payment flow using [`PaymentSheet`](https://stripe.com/docs/payments/accept-a-payment?platform=ios), an embeddable native UI component that lets you accept [10+ payment methods](https://stripe.com/docs/payments/payment-methods/integration-options#payment-method-product-support) with a single integration.

## Manual linking

If you link this library manually, use a version from our [releases](https://github.com/stripe/stripe-ios/releases) page and make sure to embed <ins>all</ins> of the following frameworks:
- `StripeCore.xcframework`
- `StripeUICore.xcframework`
- `Stripe3DS2.xcframework`
- `StripePayments.xcframework`
- `StripePaymentsUI.xcframework`
- `StripeApplePay.xcframework`
- `StripePaymentSheet.xcframework`

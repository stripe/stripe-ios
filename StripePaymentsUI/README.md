# StripePaymentsUI iOS SDK module

The StripePaymentsUI module contains UI elements and API bindings for building a custom payment flow using Stripe.

It contains:

* [STPPaymentCardTextField](https://stripe.dev/stripe-ios/stripe-payments-ui/Classes/STPPaymentCardTextField.html), a single-line interface for users to input their credit card details.
* [STPCardFormView](https://stripe.dev/stripe-ios/stripe-payments-ui/Classes/STPCardFormView.html), a multi-line interface for users to input their credit card details.
* [STPAUBECSDebitFormView](https://stripe.dev/stripe-ios/stripe-payments-ui/Classes/STPAUBECSDebitFormView.html), a UIControl that contains all of the necessary fields and legal text for collecting AU BECS Debit payments.

## Table of contents

<!--ts-->
* [Requirements](#requirements)
* [Getting started](#getting-started)
   * [Integration](#integration)
   * [Example](#example)
* [Manual linking](#manual-linking)

<!--te-->

## Requirements

The StripePaymentsUI module is compatible with apps targeting iOS 13.0 or above.

## Getting started

### Integration

Get started with our [📚 integration guides](https://stripe.com/docs/payments/accept-a-payment?platform=ios&ui=custom) and [example projects](/Example), or [📘 browse the SDK reference](https://stripe.dev/stripe-ios/stripe-payments-ui/index.html) for fine-grained documentation of all the classes and methods in the SDK.

### Example

- [Accept a Payment Example](https://github.com/stripe-samples/accept-a-payment/tree/main/custom-payment-flow/client/ios-swiftui)
   – This example demonstrates how to collect payment information on iOS using `STPPaymentCardTextField`.

## Manual linking

If you link this library manually, use a version from our [releases](https://github.com/stripe/stripe-ios/releases) page and make sure to embed <ins>all</ins> of the following frameworks:
- `StripeCore.xcframework`
- `StripeUICore.xcframework`
- `Stripe3DS2.xcframework`
- `StripePayments.xcframework`
- `StripePaymentsUI.xcframework`

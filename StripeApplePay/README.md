# Stripe Apple Pay iOS SDK

StripeApplePay is a lightweight Apple Pay SDK intended for building App Clips or other size-constrained apps.

## Table of contents
<!-- NOTE: Use case-sensitive anchor links for docc compatibility -->
<!--ts-->
- [Stripe Apple Pay iOS SDK](#Stripe-Apple-Pay-iOS-SDK)
- [Table of contents](#Table-of-contents)
  - [Requirements](#Requirements)
  - [Getting started](#Getting-started)
    - [Integration](#Integration)
    - [Example](#Example)
  - [Manual linking](#Manual-linking)

<!--te-->

## Requirements

The Stripe Apple Pay SDK is compatible with apps targeting iOS 13.0 or above.

## Getting started

### Integration

Get started with our [📚 Apple Pay integration guide](https://stripe.com/docs/apple-pay?platform=ios) and [example project](../Example/AppClipExample), or [📘 browse the SDK reference](https://stripe.dev/stripe-ios/stripe-applepay/index.html) for fine-grained documentation of all the classes and methods in the SDK.

### Example

[AppClipExample](../Example/AppClipExample) – This example demonstrates how to offer Apple Pay in an App Clip.

## Manual linking

If you link this library manually, use a version from our [releases](https://github.com/stripe/stripe-ios/releases) page and make sure to embed <ins>all</ins> of the following frameworks:
- `StripeCore.xcframework`
- `StripeApplePay.xcframework`

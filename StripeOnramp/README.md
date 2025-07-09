# Stripe Onramp iOS SDK

StripeOnramp provides [description of onramp functionality - crypto onramp, fiat-to-crypto conversion, etc.].

## Table of contents
<!-- NOTE: Use case-sensitive anchor links for docc compatibility -->
<!--ts-->
* [Features](#Features)
* [Requirements](#Requirements)
* [Getting started](#Getting-started)
   * [Integration](#Integration)
   * [Example](#Example)
* [Manual linking](#Manual-linking)

<!--te-->

## Features

**[Feature 1]**: [Description of key feature]

**[Feature 2]**: [Description of key feature]

**Prebuilt UI**: We provide prebuilt UI components that combine all the steps required for [onramp functionality] into a single sheet that displays on top of your app.

## Requirements

The Stripe Onramp iOS SDK is compatible with apps targeting iOS 13.0 or above.

## Getting started

### Integration

Get started with our [📚 integration guide](https://stripe.com/docs/[onramp-docs-path]) and [example project](../Example/OnrampExample), or [📘 browse the SDK reference](https://stripe.dev/stripe-ios/stripe-onramp/index.html) for fine-grained documentation of all the classes and methods in the SDK.

### Example

[Onramp Example](../Example/OnrampExample) – This example demonstrates how to integrate onramp functionality in your app.

## Manual linking

If you link the Stripe Onramp library manually, use a version from our [releases](https://github.com/stripe/stripe-ios/releases) page and make sure to embed <ins>all</ins> of the following frameworks:
- `StripeOnramp.xcframework`
- `StripeCore.xcframework`

<img src="../readme-images/Identity-light-80x80.png" width="40" /> Stripe Identity iOS SDK (Beta)
======

The Stripe Identity iOS SDK makes it quick and easy to verify your user's identity in your iOS app. We provide a prebuilt UI to collect your user's ID documents, match photo ID with selfies, and validate ID numbers.

> 🧪 The Identity iOS SDK is in active development. If you have any feedback or questions, please [contact us](mailto:support+identity@stripe.com).

# Table of contents

<!--ts-->
* [Features](#features)
* [Requirements](#requirements)
* [Getting started](#getting-started)
   * [Integration](#integration)
   * [Example](#example)
* [Manual linking](#manual-linking)

<!--te-->

## Features

**Simplified security**: We've made it simple for you to securely collect your user's personally identifiable information (PII) such as identity document images. Sensitive PII data is sent directly to Stripe Identity instead of passing through your server. For more information, see our [integration security guide](https://stripe.com/docs/security).

**Automatic document capture**: We automatically capture images of the front and back of government-issued photo ID to ensure a clear and readable image.

**Selfie matching**: We capture photos of your user's face and review it to confirm that the photo ID belongs to them. For more information, see our guide on [adding selfie checks](https://stripe.com/docs/identity/selfie).

**Identity information collection**: We collect name, date of birth, and government ID number to validate that it is real.

**Prebuilt UI**: We provide [`IdentityVerificationSheet`](https://stripe.dev/stripe-ios/stripe-identity/Classes/IdentityVerificationSheet.html), a prebuilt UI that combines all the steps required to collect ID documents, selfies, and ID numbers into a single sheet that displays on top of your app.

**Automated verification**: Stripe Identity's automated verification technology looks for patterns to help determine if an ID document is real or fake and uses distinctive physiological characteristics of faces to match your users' selfies to photos on their ID document. Collected identity information is checked against a global set of databases to confirm that it exists. Learn more about the [verification checks supported by Stripe Identity](https://stripe.com/docs/identity/verification-checks), [accessing verification results](https://stripe.com/docs/identity/access-verification-results), or our integration guide on [handling verification outcomes](https://stripe.com/docs/identity/handle-verification-outcomes).

## Requirements

The Stripe Identity iOS SDK is compatible with apps targeting iOS 14.3 or above.

## Getting started

### Integration

Get started with Stripe Identity's [📚 iOS integration guide](https://stripe.com/docs/identity/verify-identity-documents?platform=ios) and [example project](../Example/IdentityVerification%20Example), or [📘 browse the SDK reference](https://stripe.dev/stripe-ios/stripe-identity/index.html) for fine-grained documentation of all the classes and methods in the SDK.

### Example

[Identity Verification Example](../Example/IdentityVerification%20Example) – This example demonstrates how to capture your users' ID documents on iOS and securely send them to Stripe Identity for identity verification.

## Manual linking

If you link the Stripe Identity library manually, use a version from our [releases](https://github.com/stripe/stripe-ios/releases) page and make sure to embed <ins>all</ins> of the following frameworks:
- `StripeIdentity.xcframework`
- `StripeCore.xcframework`

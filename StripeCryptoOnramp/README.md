# Stripe Crypto Onramp iOS SDK

StripeCryptoOnramp helps you build a headless crypto onramp flow in your iOS app to allow your customers to securely purchase and exchange cryptocurrencies. It provides a coordinator that manages Link authentication, know your customer (KYC) and identity verification, payment method collection, and checkout handling while leaving your app in control of most of the surrounding UI and navigation.

> This SDK is currently in *private preview*. Learn more and request access via the [Stripe docs](https://docs.stripe.com/crypto/onramp/embedded-components).

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

**Headless coordinator**: Use `CryptoOnrampCoordinator` to orchestrate an onramp flow with minimal Stripe-provided UI.

**Link authentication**:
- Check if an email has a Link account with `hasLinkAccount(with:)`
- Register new users with `registerLinkUser(email:fullName:phone:country:)`
- Authenticate existing users with `authenticateUser(from:)`
- Authorize a Link auth intent with `authorize(linkAuthIntentId:from:)`
- Support seamless sign-in for returning users with `authenticateUserWithToken(_:)`

**KYC and identity verification**:
- Submit KYC information with `attachKYCInfo(info:)` and confirm it with `verifyKYCInfo(updatedAddress:from:)`
- Present identification document verification using `verifyIdentity(from:)`

**Wallets and payment methods**:
- Register crypto wallet addresses with `registerWalletAddress(walletAddress:network:)`
- Collect payment methods via Link (card, bank account) or Apple Pay with `collectPaymentMethod(type:from:)`
- Create crypto payment tokens with `createCryptoPaymentToken()`

**Checkout handling**: 
- Complete purchases for an onramp session with `performCheckout(onrampSessionId:authenticationContext:onrampSessionClientSecretProvider:)`.

## Requirements

The StripeCryptoOnramp iOS SDK is compatible with apps targeting iOS 13.0 or above.

## Getting started

### Integration

Get started with Embedded components onramp [📚 iOS integration guide](https://docs.stripe.com/crypto/onramp/embedded-components) and [example project](../Example/CryptoOnramp%20Example), or [📘 browse the SDK reference](https://stripe.dev/stripe-ios/stripecryptoonramp/documentation/stripecryptoonramp) for fine-grained documentation of all the classes and methods in the SDK.

This SDK requires access to the device's camera to capture identity documents. To enable your app to request camera permissions, set `NSCameraUsageDescription` in your app's plist and provide a reason for accessing the camera (e.g. "This app uses the camera to take a picture of your identity documents").



### Example

[Crypto Onramp Example](../Example/CryptoOnramp%20Example) – This example demonstrates an end-to-end headless onramp flow (Link authentication, KYC and identity verification, wallet selection, payment method collection, and checkout) using a demo backend.

## Manual linking

If you link the Stripe Crypto Onramp library manually, use a version from our [releases](https://github.com/stripe/stripe-ios/releases) page and make sure to embed <ins>all</ins> of the following frameworks:
- `Stripe.xcframework`
- `Stripe3DS2.xcframework`
- `StripeApplePay.xcframework`
- `StripeCameraCore.xcframework`
- `StripeCore.xcframework`
- `StripeCryptoOnramp.xcframework`
- `StripeFinancialConnections.xcframework`
- `StripeIdentity.xcframework`
- `StripePayments.xcframework`
- `StripePaymentSheet.xcframework`
- `StripePaymentsUI.xcframework`
- `StripeUICore.xcframework`

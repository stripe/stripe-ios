# Stripe Crypto Onramp iOS SDK

StripeCryptoOnramp helps you build a headless crypto onramp flow in your iOS app to allow your customers to securely purchase and exchange cryptocurrencies. It provides a coordinator that manages Link authentication, know your customer (KYC) and identity verification, payment method collection, and checkout handling while leaving your app in control of most of the surrounding UI and navigation.

> [!IMPORTANT]
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

**Headless coordinator**: 
- Use `CryptoOnrampCoordinator` to orchestrate an onramp flow with minimal Stripe-provided UI

**Link authentication**:
- Check if an email has a Link account with `hasLinkAccount(with:)`
- Register new users with `registerLinkUser(email:fullName:phone:country:)`
- Authorize a Link auth intent with `authorize(linkAuthIntentId:from:)`
- Support seamless sign-in for returning users with `authenticateUserWithToken(_:)`

**KYC and identity verification**:
- Present required partner terms of service with `presentTermsOfServiceIfNeeded(from:)` during onboarding after Link authentication
- Submit KYC information with `attachKYCInfo(info:)` and confirm it with `verifyKYCInfo(updatedAddress:from:)`
- Present identification document verification using `verifyIdentity(from:)`

**Wallets and payment methods**:
- Register and delete crypto wallets with `registerWalletAddress(walletAddress:network:)` and `deleteWalletAddress(walletId:)`
- Collect payment methods via Link (card, bank account) or Apple Pay with `collectPaymentMethod(type:from:)`. To receive partial `KycInfo` from Apple Pay, configure the provided `PKPaymentRequest` to request Apple Pay billing `.name` and/or `.postalAddress`.
- Create crypto payment tokens with `createCryptoPaymentToken()`, or opt in to paired card or bank-account details with `createCryptoPaymentTokenWithDetails()`

After successful payment-method collection and authentication, you can read metadata before creating an onramp session:

```swift
let result = try await coordinator.createCryptoPaymentTokenWithDetails()
let token = result.cryptoPaymentToken
let card = result.cardDetails
let bankAccount = result.bankAccountDetails
let isExplicitDebit = card?.funding == .debit
// Send the token and paired card or bank-account summary to your backend here.
// Your backend can choose voluntary fee responsibility before creating the session.
// Display the server-calculated session quote before checkout.
```

The result describes the same payment source used to create the token, even if the selection changes while either payment-method or token creation is in flight. Apple Pay and Link card selections (including directly entered debit cards) populate `cardDetails` when available. Link bank-account/ACH selections populate `bankAccountDetails` with the account's last four digits and leave `cardDetails` nil. ACH is not a debit card and has no card funding or brand. Unknown payment types and unavailable metadata leave the corresponding details nil.

Missing or unrecognized card funding maps to `.other`; missing last four digits remain `nil`. Only `.debit` qualifies for a strict debit-card-only subsidy policy: `.credit`, `.prepaid`, `.other`, bank accounts, and absent details do not. Funding does not prove card ownership, and last four digits may describe a wallet-tokenized number rather than the physical card.

A supported ACH selection can follow a separate merchant bank-payment subsidy rule. Bank last four digits do not establish mandate validity, settlement speed, ownership, or payment success.

The SDK already holds structured metadata at selection time. Returning it with the token is a consistency and compatibility choice, not a requirement to wait for funding information to become available. Token creation pairs the summary with the created or shared PaymentMethod after account-routing validation. The collection result shape remains unchanged.

The merchant chooses its voluntary subsidy policy; the server-calculated session quote remains authoritative. Client-provided metadata is not a substitute for backend validation of Stripe-enforced eligibility. Do not add card or bank-account summaries to analytics. This opt-in API does not add network calls or change the demo backend. Existing `createCryptoPaymentToken()` integrations continue returning a string.

Both token methods apply the same authentication and KYC-region validation described below.

If the customer's KYC region (country of residence) changes after Apple Pay was collected before authentication, `createCryptoPaymentToken()` throws `PaymentMethodKYCRegionChangedError` (`payment_method_kyc_region_changed`). The region used during collection may have come from `countryHint` or a default and differ from the customer's authenticated KYC region. Collect Apple Pay again with `collectPaymentMethod(type: .applePay(paymentRequest:), from:)`, then call `createCryptoPaymentToken()` only after collection succeeds. To avoid this, ensure `countryHint` matches the customer's KYC region before collecting Apple Pay pre-authentication, or authenticate the customer first and then collect Apple Pay. Cancellation preserves the previous selection, which remains subject to validation; the SDK does not reopen Apple Pay automatically.

**Checkout handling**: 
- Present required partner terms and conditions with `presentTermsAndConditionsIfNeeded(from:)` before checkout
- Complete purchases for an onramp session with `performCheckout(onrampSessionId:authenticationContext:onrampSessionClientSecretProvider:)`.

**Theming**:
- The minimal Stripe-provided UI supports light customization via `LinkAppearance`
- Customize component colors, button properties, and light / dark interface styles

## Requirements

The StripeCryptoOnramp iOS SDK is compatible with apps targeting iOS 15.0 or above.

## Getting started

### Integration

Get started with Embedded components onramp [📚 iOS integration guide](https://docs.stripe.com/crypto/onramp/embedded-components) and [example project](../Example/CryptoOnramp%20Example), or [📘 browse the SDK reference](https://stripe.dev/stripe-ios/stripecryptoonramp/documentation/stripecryptoonramp) for fine-grained documentation of all the classes and methods in the SDK.

This SDK requires access to the device's camera to capture identity documents. To enable your app to request camera permissions, set `NSCameraUsageDescription` in your app's plist and provide a reason for accessing the camera (e.g. "This app uses the camera to take a picture of your identity documents").

### Example

[CryptoOnramp Example](../Example/CryptoOnramp%20Example) – This example demonstrates an end-to-end headless onramp flow (Link authentication, KYC and identity verification, wallet selection, payment method collection, and checkout) using a demo backend.

## Manual linking

If you link the StripeCryptoOnramp library manually, use a version from our [releases](https://github.com/stripe/stripe-ios/releases) page and make sure to embed <ins>all</ins> of the following frameworks:
- `Stripe.xcframework`
- `Stripe3DS2.xcframework`
- `StripeApplePay.xcframework`
- `StripeCameraCore.xcframework`
- `StripeCore.xcframework`
- `StripeCryptoOnramp.xcframework`
- `StripeFinancialConnections.xcframework`
- `StripeIdentity.xcframework`
- `StripeIssuing.xcframework`
- `StripePayments.xcframework`
- `StripePaymentSheet.xcframework`
- `StripePaymentsUI.xcframework`
- `StripeUICore.xcframework`

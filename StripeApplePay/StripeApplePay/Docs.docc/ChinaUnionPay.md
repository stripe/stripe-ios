# Accept China UnionPay with Apple Pay

Enable China UnionPay for one-time Apple Pay payments after your Stripe account is enabled for the network.

```swift
StripeAPI.additionalEnabledApplePayNetworks = [.chinaUnionPay]
```

Set this before initializing PaymentSheet or building an Apple Pay payment request. Include any other additional networks your integration enables in the same array.

China UnionPay Apple Pay does not support SetupIntents, zero-total requests, recurring payments, automatic reloads, or setting up future off-session payments. Off-session payments happen when the customer is absent; recurring and other merchant-initiated transactions (MITs) charge a previously saved payment method. Use another payment method for these flows.

## PaymentSheet and Checkout

Stripe excludes China UnionPay from setup-only flows and payments whose effective card `setup_future_usage` is `off_session`. A per-card setting takes precedence over the top-level setting. Stripe also excludes the network from zero-total or explicit PassKit recurring, automatic reload, or deferred requests.

PaymentSheet applies these restrictions after your payment request customization handler. Deferred intent integrations must describe the intended setup or future usage accurately in `PaymentSheet.IntentConfiguration`.

## Custom Apple Pay integrations

`StripeAPI.paymentRequest(withMerchantIdentifier:country:currency:)` builds a request with China UnionPay and the required EMV capability when the network is enabled. It does not receive a PaymentIntent or SetupIntent and cannot determine whether your payment will set up future usage.

`STPApplePayContext` excludes China UnionPay when the final request has a zero total or explicit recurring, automatic reload, or deferred payment fields. It receives your intent client secret after the customer authorizes Apple Pay. If you use it for another setup-only or future off-session flow, remove China UnionPay before creating the context:

```swift
// For a SetupIntent or a payment that sets up recurring or future off-session use:
paymentRequest.supportedNetworks.removeAll { $0 == .chinaUnionPay }

let context = STPApplePayContext(paymentRequest: paymentRequest, delegate: self)
```

The context synchronizes the EMV capability with the final supported networks. You do not need to add EMV yourself when using Stripe's request builder or context.

If you present your own PassKit controller, apply these exclusions after all request customization and synchronize EMV yourself:

```swift
// For an unsupported setup, recurring, or future off-session flow:
paymentRequest.supportedNetworks.removeAll { $0 == .chinaUnionPay }

// After all supported-network changes, preserve the other capability bits.
if paymentRequest.supportedNetworks.contains(.chinaUnionPay) {
    paymentRequest.merchantCapabilities.insert(.emv)
} else {
    paymentRequest.merchantCapabilities.remove(.emv)
}
```

SDK filtering prevents customers from selecting an unsupported network in the Apple Pay sheet. Server-side checks reject unsupported China UnionPay Apple Pay card validations and new setups for future MITs, including for older SDKs and custom controllers. This SDK filtering does not change server behavior for previously saved payment methods or existing MITs.

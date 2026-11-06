# Checkout Sheet

CheckoutSheet is a new component in the StripePaymentSheet module. It owns a complete Checkout Session checkout: contact information, shipping address when required, payment collection, review, pricing, and confirmation. Merchants configure and present one component. PaymentSheet's API and checkout flow are independent.

The component is available on iOS 16 and later behind the existing `STP` SPI while the Checkout Session integration is in development. It accepts the same **modeless, mobile-elements Checkout Sessions** as CheckoutController.

```swift
@_spi(STP) import StripePaymentSheet

var configuration = CheckoutSheet.Configuration(
    clientSecret: checkoutSessionClientSecret,
    returnURL: "my-app://stripe-redirect"
)
configuration.merchantDisplayName = "My Store"
configuration.applePay = .init(merchantId: "merchant.com.example.store")

let checkoutSheet = try await CheckoutSheet(configuration: configuration)
let result = await checkoutSheet.present(from: presentingViewController)
switch result {
case .completed(let paymentStatus):
    // Handle the session's paid, unpaid, or no-payment-required status.
    // Fulfill orders from your server's Checkout Session webhooks.
case .canceled:
    // The customer closed checkout. The same open session can be presented again.
case .failed(let error):
    // Loading/presentation failed. Show the error and allow retry.
}
```

Register the return URL's scheme and forward incoming URLs to `StripeAPI.handleURLCallback(with:)`, as with the existing Checkout integrations. The API client, default customer details, merchant logo, appearance, Link availability, and Adaptive Pricing can be configured on `CheckoutSheet.Configuration`.

Payment errors and canceled authentication keep the checkout open for retry. Successful confirmation stays visible until the customer chooses Done or closes the confirmation; then the presentation returns `.completed`. An unpaid session shows “Checkout complete,” without claiming that payment funds are available.

## Example app

Run the **PaymentSheet Example** scheme. Choose **Checkout Sheet**, configure the session, choose **Create Checkout Session**, then **Checkout**. The existing Checkout Elements playground also has a **Checkout Sheet** integration option. Set `STP_CHECKOUT_SHEET=true` in the scheme's launch environment to open that option directly.

Use Email source **None** to test email collection, Default Shipping Address **No address** to test shipping entry, and Customer **Returning** to test saved payment methods. Disable Collect Shipping Address for a checkout with no shipping task. The `$0 cart` exercises checkout without payment collection. The SDK receives an ordinary test-mode session from the existing playground backend; it does not use prototype timers or hardcoded payment results. Checkout Sheet uses Dashboard-managed payment methods because the current preview API rejects explicit `payment_method_types`.

## Implementation

The UI adapts Verde's active Accordion stack composition in `Verde/BusinessTypes/Ecommerce/CommerceCheckoutView.swift`, `CommerceSheetView.swift`, and `VerdeSummaryRow.swift`: compact wallet entry, task cards, editable review, a prominent total, capsule actions, and confirmation. Semantic type and scrolling preserve accessibility at large text sizes. Real Stripe payment forms, saved-method management, address validation/autocomplete, and wallet authorization replace prototype fixtures.

CheckoutController owns the source of truth. All email, shipping/tax, promotion, currency, and confirmation operations use its existing serialized update and confirmation pipelines. EmbeddedPaymentElement's internal UI host allows Checkout Sheet to keep real payment editors in its own navigation. Ordinary EmbeddedPaymentElement presentations keep their existing behavior.

The current modeless API exposes one-time items and shipping-address collection. It does not expose shipping-rate selection or subscription checkout, so those prototype tasks are omitted. Promotion-code entry appears only when the session enables `allow_promotion_codes`. Wallet availability follows session and device capabilities; Link currently cannot collect a required shipping address. New checkout copy uses the SDK localization lookup, with English fallbacks where translated strings are not yet available.

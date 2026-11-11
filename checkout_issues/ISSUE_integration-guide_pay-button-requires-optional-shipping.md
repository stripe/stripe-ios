Summary: An integrator who follows the guide's supported option to omit shipping collection but copies its Pay-button predicate leaves Pay permanently disabled. The predicate requires `session.shippingAddress != nil` even for a valid non-shipping purchase.

Repro:

1. Create a one-time Checkout Session with a customer email, without shipping address collection. Configure Payment Element and select a valid card.
2. Use the UIKit `updatePayButton` predicate from [Render the order summary](https://stripe.sourcegraphcloud.com/stripe-internal/mint/-/blob/pay-server/docs/content/payments/mobile/checkout-sessions/partials/build-a-checkout-page.md?L242-247): `!checkout.isUpdating && checkout.session.paymentOption != nil && checkout.session.shippingAddress != nil`.
3. Pay stays disabled because the session has no shipping address. Calling `checkout.confirm` directly completes the same purchase successfully.

Test: `CheckoutSupportedFlowsLiveTests.testGuidePayButtonAllowsPurchaseWithoutShipping` creates a real session, selects a test card, fails the assertion that the copied predicate enables Pay, and then successfully confirms the purchase. No network responses are mocked. Result: `/tmp/checkout-guide-live.xcresult`.

Elaboration: The guide explicitly says to omit Shipping Address Element when no address is needed, but its UIKit and SwiftUI Pay predicates unconditionally require an address. The examples should condition the shipping check on whether the integration collects shipping. The full four-Element example, which enables shipping, is not affected. Source checked at docs commit `6389c38d3f1864c4ced050277be636f8f29f5adb`.

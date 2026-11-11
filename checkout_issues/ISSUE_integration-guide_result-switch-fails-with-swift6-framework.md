Summary: An iOS app using Swift 6 and a StripePaymentSheet framework built with library evolution cannot compile the guide's confirmation-result handler. Its switch covers the three current cases but has no fallback for unknown cases.

Repro:

1. Import this branch's resilient StripePaymentSheet framework using a working SPI import.
2. Copy the [Confirm the Session result handler](https://stripe.sourcegraphcloud.com/stripe-internal/mint/-/blob/pay-server/docs/content/payments/mobile/checkout-sessions/partials/build-a-checkout-page.md?L950-961), switching over `.completed`, `.canceled`, and `.failed` only.
3. Type-check in Swift 6 mode. The compiler reports that `CheckoutController.ConfirmResult` may have additional unknown values.

Test: `guide_repros/CheckoutGuideAPISurface.swift`, run by `python3 guide_repros/check_swift_samples.py <built-frameworks-directory>`. Swift 6 rejects the result switch. Adding only `@unknown default` makes the scaffold compile. The scaffold supplies app-owned views/helpers and uses the correct SPI to isolate this defect from the separate import issue.

Elaboration: `ConfirmResult` is a non-frozen enum in the framework. The guide supports manual framework installation, so an external Swift 6 client must handle future enum cases. Swift 5 emits a warning for this sample; Swift 6 makes it an error. This report does not claim that source-based Swift Package Manager builds without library evolution have the same error.

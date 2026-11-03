Summary: An iOS integrator following the guide's `@_spi(CheckoutSessionPreview) import StripePaymentSheet` cannot compile its `CheckoutController` configuration against this branch. Swift reports `cannot find type 'CheckoutController' in scope`.

Repro:

1. Build this branch's StripePaymentSheet framework.
2. Copy the [setup import](https://stripe.sourcegraphcloud.com/stripe-internal/mint/-/blob/pay-server/docs/content/payments/mobile/checkout-sessions/partials/setup.md?L49-53) and reference `CheckoutController.Configuration` as the integration guide does.
3. Type-check the file against the built framework. The controller is unavailable.

Test: `guide_repros/CheckoutPreviewImport.swift`, run by `python3 guide_repros/check_swift_samples.py <built-frameworks-directory>`. The documented import fails. Changing only the SPI name to `InternalOnlyAPI` compiles.

Elaboration: The branch exposes `CheckoutController` through `InternalOnlyAPI` and `ReactNativeSDK`, not `CheckoutSessionPreview`. The same incorrect import appears in the migration guide. The guide and the distributed preview SDK need an agreed import name; this report does not recommend exposing InternalOnlyAPI as the final merchant API. Source checked at docs commit `6389c38d3f1864c4ced050277be636f8f29f5adb`.

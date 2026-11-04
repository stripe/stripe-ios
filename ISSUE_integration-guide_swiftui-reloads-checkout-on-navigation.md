Summary:
The iOS guide's SwiftUI `CheckoutContainer` reloads `CheckoutController` every time its `.task` runs, even when a controller is already stored in `@State`. Navigating from checkout to an ordinary merchant details page and back replaces the controller and discards the customer's selected payment method and locally collected shipping address.

Repro:
1. Assemble the guide's SwiftUI container and sheet-style Payment Element in a navigation view. Keep the same Session client secret as the container input.
2. Save a shipping address, enter test card 4242, and return to checkout. The selected Visa appears and Pay enables.
3. Navigate to a merchant-owned order-details screen, then go back.
4. `.task` runs again and executes `checkout = try await CheckoutController(configuration: configuration)`. After loading, the payment-method button goes back to “Select payment method,” the address is empty, and Pay is disabled.

Test:
`CheckoutGuideUITests.testReturnFromOrderDetailsPreservesSelection` drives these interactions in the separate guide-derived example-app screen. It failed because the empty-selection prompt returned after navigation. `STP_CHECKOUT_GUIDE=navigation` keeps the guide's unconditional load. Backend creation is outside that container; the controller reload uses its existing client-secret input. The [screen after returning](guide_repros/images/guide-navigation-loses-selection.png) shows the lost card/address and disabled Pay button.

Elaboration:
Retain the loaded controller across view appearances and avoid replacing it when `.task` reruns. The `navigation-fixed` reproduction variant adds only an early return when the controller already exists; it is separate from the literal guide path. `testReturnFromOrderDetailsWithLoadGuard` passed, preserving selection and an enabled Pay button. The comparison also verifies that the Session ID is unchanged. The literal-path test failed again in the same run. Xcode stalled while finalizing that result bundle; the completed test outcomes are retained in `guide_repros/walkthrough-results.txt`. A production sample should also explain ownership and when to deliberately start a new Session.

This is a lifecycle problem in the sample, not a requirement for the SDK to recover sensitive entered card data into a newly created controller. Merely declaring the controller as `@State` doesn't protect it from the next explicit assignment.

See the guide source: https://stripe.sourcegraphcloud.com/stripe-internal/mint@de7108d190d32c9c7f82b6ae80e8be698f412931/-/blob/pay-server/docs/content/payments/mobile/checkout-sessions/partials/build-a-checkout-page.md?L124-159

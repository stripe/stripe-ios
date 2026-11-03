Summary: After a merchant calls `checkout.updateShippingAddress(name:address:)`, reopening the Shipping Address Element shows the previous address. Saving the unchanged form replaces the merchant's newer address in `checkout.session.shippingAddress` with that previous address.

Repro:

1. Create a checkout with a Shipping Address Element. Open it, enter address A, and save.
2. Call `checkout.updateShippingAddress(name:address:)` with address B and await completion. The session and merchant's order summary now show B.
3. Reopen the Shipping Address Element. Its fields still show A.
4. Press Save Address without editing. The session and order summary revert to A.

In the Checkout Playground, use the existing "Set address directly (bypass element)" control for step 2. The live repro changes Jane Doe / 510 Townsend St to Alex Direct / 1 Direct Ave, then verifies that reopening and saving restores Jane Doe / 510 Townsend St.

Test:

- `Example/PaymentSheet Example/PaymentSheetUITest/CheckoutElementsUITests.swift` — `testShippingAddressElementShowsStaleAddressAfterExternalUpdate`: passed against the test backend, including saving the stale form and verifying the overwrite.
- `StripePaymentSheet/StripePaymentSheetTests/PaymentSheet/Checkout/ShippingAddressElementConfigurationTests.swift` — `testShippingAddressElementDoesNotReflectAddressUpdatesMadeOutsideTheElement`: passed; checks actual form values, saving them over the newer session address, and stale values remaining after clearing the session address.

Elaboration: `CheckoutController` seeds the element's address form during initialization. `updateShippingAddress` updates local session state and, when required, the tax region, but neither it nor `updateForSessionChange` refreshes the form. `ShippingAddressElement.present` reuses that form, and its save delegate writes the stale values back through `updateShippingAddress`.

These Checkout APIs are exposed through SPI. The affected address is the local value exposed by `CheckoutController.session`.

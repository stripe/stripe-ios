# `ShippingAddressElement` never re-syncs after construction

**Surface:** sub-elements · **Confidence:** High (live-verified) · **Severity:** Medium

## Summary

`ShippingAddressElement` is seeded once when the checkout loads and never finds out about address changes made any other way. If a merchant updates the shipping address through their own UI (not through the element's own sheet), the session is correct, but the element itself goes stale.

**Repro, from the customer's/merchant's perspective:**

1. Customer opens the Shipping Address Element, enters "Jane Doe, 510 Townsend St," and saves. The merchant's own order summary shows it.
2. Merchant's app later sets a different shipping address through its own code — e.g. a "use my saved address" button, or auto-filling from account data — calling the public `checkout.updateShippingAddress(...)` API directly instead of going through the element.
3. The merchant's order summary correctly updates to the new address.
4. Customer taps "Edit" to reopen the Shipping Address Element sheet to double check or tweak it.
5. The sheet still shows **"Jane Doe, 510 Townsend St"** — the original address, not the one the merchant just set.

This is reachable via the real public API (`CheckoutController.updateShippingAddress(name:address:)`) — anywhere a merchant has a second way to set the shipping address alongside the element.

## Repro (how it was actually driven, live against the real backend)

1. In the PaymentSheet Example app's Checkout Playground, create a Checkout Session with the Shipping Address Element enabled (default settings).
2. Tap **"Add shipping address"**, enter "Jane Doe" / "510 Townsend St", save.
3. Tap the debug button **"Set address directly (bypass element)"** — added to `CheckoutCartContentView.swift` to stand in for a merchant's own "use my saved address" control — which calls `checkout.updateShippingAddress(name: "Alex Direct", address: ...)` directly.
4. The merchant's own UI now shows **"Alex Direct"** (the session updated correctly).
5. Tap **"Edit"** to reopen the Shipping Address Element sheet. Its "Full name" field still shows **"Jane Doe"**, not "Alex Direct".

## Test

| Level | File | Test | Result |
|---|---|---|---|
| Live | `Example/PaymentSheet Example/PaymentSheetUITest/CheckoutElementsUITests.swift` | `testShippingAddressElementShowsStaleAddressAfterExternalUpdate` | ✅ Passed |
| Unit | `StripePaymentSheet/StripePaymentSheetTests/.../ShippingAddressElementConfigurationTests.swift` | `testShippingAddressElementDoesNotReflectAddressUpdatesMadeOutsideTheElement` | ✅ Passed |

The live test requires the debug button in `CheckoutCartContentView.swift` (`setShippingAddressDirectly()` / `checkout_set_shipping_address_directly`) and an accessibility identifier on the shipping address card's "Edit" button (`checkout_shipping_address_edit`, needed to disambiguate it from an unrelated "Edit" button elsewhere in the view hierarchy). Run with:

```
ci_scripts/run_tests.rb --test "PaymentSheetUITest/CheckoutElementsUITests/testShippingAddressElementShowsStaleAddressAfterExternalUpdate"
```

## Elaboration

`CheckoutController.shippingAddressElement` is declared `private let` and assigned exactly once, during `init`, via `makeShippingAddressElement` — see [`CheckoutController.swift:50`](https://github.com/stripe/stripe-ios/blob/yuki/checkout-session-bug-finder/StripePaymentSheet/StripePaymentSheet/Source/PaymentSheet/Checkout/CheckoutController.swift#L50) and [`CheckoutController.swift:128-133, 183-220`](https://github.com/stripe/stripe-ios/blob/yuki/checkout-session-bug-finder/StripePaymentSheet/StripePaymentSheet/Source/PaymentSheet/Checkout/CheckoutController.swift#L128-L220). Grepping the whole `Checkout/` directory for `shippingAddressElement` turns up no other assignment site.

`ShippingAddressElement` itself ([`Shipping Address Element/ShippingAddressElement.swift`](https://github.com/stripe/stripe-ios/blob/yuki/checkout-session-bug-finder/StripePaymentSheet/StripePaymentSheet/Source/PaymentSheet/Checkout/Shipping%20Address%20Element/ShippingAddressElement.swift)) has no method that lets anything re-seed its `addressViewController` after construction. Its only outbound path is the `ShippingAddressElementDelegate.updateShippingAddressFromElement` callback fired from the user's own `save()` action inside the sheet — there's no inbound path at all.

Compare this to `ExpressCheckoutElement`/`CurrencySelectorElement`, which are both constructed with a `CheckoutSessionSource` holding a live Combine publisher (`sessionPublisher: $session`) specifically so they keep receiving session updates — `ShippingAddressElement` was never given that same mechanism. And `CheckoutController.updateForSessionChange()` (the other place session changes get distributed) only touches `confirmationChallenge` and `paymentElement` — see [`CheckoutController.swift:587-600`](https://github.com/stripe/stripe-ios/blob/yuki/checkout-session-bug-finder/StripePaymentSheet/StripePaymentSheet/Source/PaymentSheet/Checkout/CheckoutController.swift#L587-L600) — not `shippingAddressElement`.

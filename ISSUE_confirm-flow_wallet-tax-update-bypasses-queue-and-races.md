# Apple Pay's tax-region update bypasses the update queue and can race another update

**Surface:** confirm-flow · **Confidence:** Medium (code-verified; live repro not completed — see note) · **Severity:** Medium

## Summary

Apple Pay's tax-region sync (fired when the customer picks a shipping/billing contact inside the Apple Pay sheet) skips the normal update queue entirely. If anything else updates the session at the same time, whichever network response lands last wins and **fully replaces** the session — silently discarding the other change.

**Repro, from the customer's/merchant's perspective:**

1. Customer taps the Apple Pay button. The system payment sheet opens.
2. Customer selects a shipping or billing contact inside that sheet — this fires Apple Pay's own tax-region update in the background, with no visible loading state in the merchant's app.
3. At the same moment, something else in the merchant's app updates the session too — e.g. a scheduled price/shipping change, or any other server-driven update the merchant's own code triggers while that sheet is open.
4. Both updates are now in flight at once. Whichever one's network response comes back **last** wins outright — not a merge, a full replacement — so the other one's change (tax region, totals, whatever it touched) is silently dropped.

**Correction after attempting a live repro:** the obvious version of this — "customer edits a billing field, then taps Apple Pay" — turned out to be blocked by the SDK itself: the Apple Pay button is disabled ([`CheckoutController.swift:26-30`](https://github.com/stripe/stripe-ios/blob/yuki/checkout-session-bug-finder/StripePaymentSheet/StripePaymentSheet/Source/PaymentSheet/Checkout/CheckoutController.swift#L26-L30)) while anything else is queued, so that specific sequence can't happen. The reachable version needs the Apple Pay sheet to *already* be open before anything else starts updating — i.e. step 3 above has to come from the merchant's own background/programmatic code, not a second customer tap.

## Repro (code-level — see Test; live attempt did not complete, see note below)

1. Have a `CheckoutController` with both `paymentElement` and `expressCheckoutElement` configured.
2. Start a queued tax-region update for address A (e.g. via `updateBillingTaxRegionIfNecessary`, which goes through `enqueueSessionUpdate`) and let its network request stay in flight.
3. While it's still in flight, call `checkoutWalletUpdater.updateTaxRegionWithoutEnqueueing(address: B, canUpdateWhileSheetPresented: true, confirmationSource: .expressCheckoutElement)` — what Apple Pay's `didSelectShippingContact`/`didSelectPaymentMethod` delegate callbacks call — for a different address B.
4. Let A's response arrive after B's, even though A was sent first and B is the more recent action.
5. Observe `checkout.session` reflects A's result, not B's, despite B being the later one.

**Live-repro attempt note:** triggering this live requires a queued update to start *while the Apple Pay system sheet is already open and the customer is mid-interaction with it*. That means the trigger has to come from this app's process while a separate system process (`com.apple.PassbookUIService`) owns the foreground modal — precisely-timed, cross-process UI automation that wasn't achieved cleanly within reasonable effort. The code-level test below is the repro of record for this one.

## Test

| Level | File | Test | Result |
|---|---|---|---|
| Unit | `StripePaymentSheet/StripePaymentSheetTests/.../CheckoutPendingOperationsTests.swift` | `testWalletUpdateBypassesQueueAndCanRaceAQueuedUpdate` | ✅ Passed |

Verified meaningful: temporarily routing the wallet update through the queue (the "fixed" behavior) instead of calling it directly flips the result to the correct one (the later update wins) and makes the test's assertion fail as expected — that change was not committed.

## Elaboration

`CheckoutSessionWalletUpdater.updateTaxRegionWithoutEnqueueing` — the only implementation, on `CheckoutController`, see [`CheckoutSessionWalletUpdater.swift:34-59`](https://github.com/stripe/stripe-ios/blob/yuki/checkout-session-bug-finder/StripePaymentSheet/StripePaymentSheet/Source/PaymentSheet/Checkout/CheckoutSessionWalletUpdater.swift#L34-L59) — calls `performUnqueuedUpdate` directly. It never goes through `enqueueSessionUpdate`/`pendingOperations`, by design (hence the name).

But `performUnqueuedUpdate` ([`Checkout+Internal.swift:240-271`](https://github.com/stripe/stripe-ios/blob/yuki/checkout-session-bug-finder/StripePaymentSheet/StripePaymentSheet/Source/PaymentSheet/Checkout/Checkout+Internal.swift#L240-L271)) carries its own explicit warning:

> Only call this within a queued context, to prevent concurrent updates from applying responses out of order.

Nothing else compensates for this. `requireSheetNotPresented()` — the only other guard `performUnqueuedUpdate` can check — only looks at `paymentElement?.isPresentingPaymentUI` ([`Payment Element/PaymentElement.swift:143-145`](https://github.com/stripe/stripe-ios/blob/yuki/checkout-session-bug-finder/StripePaymentSheet/StripePaymentSheet/Source/PaymentSheet/Checkout/Payment%20Element/PaymentElement.swift#L143-L145)), which has no knowledge of an Apple Pay/Express Checkout wallet sheet being open — and the wallet call passes `canUpdateWhileSheetPresented: true` anyway, bypassing that guard regardless.

Meanwhile, `updateBillingTaxRegionIfNecessary` (used by Payment Element's billing sync) correctly goes through the FIFO `pendingOperations` queue via `performQueuedUpdate`. So one wallet-adjacent update path respects the queue and the other explicitly doesn't, and nothing prevents both from having requests in flight at once — the two concurrent `/update` network calls can then have their responses arrive in either order, and `commitSession` simply applies whichever one resolves last.

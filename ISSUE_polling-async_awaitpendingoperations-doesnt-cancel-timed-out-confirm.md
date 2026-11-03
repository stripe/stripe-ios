# `awaitPendingOperations` doesn't cancel a timed-out confirm

**Surface:** polling-async · **Confidence:** High (live-verified) · **Severity:** Medium

## Summary

If the merchant calls `presentPaymentOptions` (e.g. the customer taps "Select payment method") a second time while a confirm is still running, the resulting wait can hit `CheckoutController.awaitPendingOperations()`'s 30s timeout. When that timeout fires, the flow dismisses and proceeds **as if everything finished cleanly** — but the original confirm is never canceled and keeps running in the background, later silently overwriting session state.

**Repro, from the customer's perspective:**

1. Customer taps **Buy** with a card. Confirm starts, and for whatever reason (slow network, 3DS, slow poll) it's taking a while.
2. While that confirm is still pending, the customer taps **"Select payment method"** again — to double check what they picked, or because the merchant's UI lets them get back there.
3. The merchant's screen shows a brief loading spinner, then after ~30s gives up and shows the payment method picker as if nothing was in flight — no error, no indication anything's wrong.
4. Customer picks a *different* card and taps **Buy** again... but the Buy button is still disabled, because the *first* confirm never actually stopped.
5. Moments later, the first confirm finishes on its own and silently commits its result — even though the customer has moved on and is trying to pay a different way.

This is reachable via the real public API — `flowController.presentPaymentOptions(from:)`, called via `presentPaymentOptionsAwaitingMutations` in [`PaymentSheetFlowController.swift:583-618`](https://github.com/stripe/stripe-ios/blob/yuki/checkout-session-bug-finder/StripePaymentSheet/StripePaymentSheet/Source/PaymentSheet/PaymentSheetFlowController.swift#L583-L618) — and the timeout-dismiss-as-success behavior lives at [`PaymentSheetFlowController.swift:606-609`](https://github.com/stripe/stripe-ios/blob/yuki/checkout-session-bug-finder/StripePaymentSheet/StripePaymentSheet/Source/PaymentSheet/PaymentSheetFlowController.swift#L606-L609).

## Repro (how it was actually driven, live against the real backend)

1. In the PaymentSheet Example app's Checkout Playground, create a Checkout Session with **"Delay Checkout Client Requests"** enabled (injects a 35s delay on real `/checkout_client/*` requests — long enough to exceed the 30s timeout while still hitting the real backend).
2. Select a card payment method, tap **Buy**. The real `/confirm` request is in flight, delayed 35s; the Buy button is disabled.
3. Tap the debug toolbar button added to `CheckoutCartView.swift` (`checkout_force_present_payment_options`) — stands in for the customer re-presenting Payment Options, which the real UI normally blocks while a confirm is running.
4. A loading sheet appears, then **dismisses on its own after ~30s** — the real payment options sheet never shows.
5. The Buy button is **still disabled** (the original confirm is still running).
6. ~5s later, the original confirm's delayed response arrives and the **Success alert appears** — it was never canceled by the timeout in step 4.

## Test

| Level | File | Test | Result |
|---|---|---|---|
| Live | `Example/PaymentSheet Example/PaymentSheetUITest/CheckoutElementsUITests.swift` | `testReopeningPaymentOptionsDuringASlowConfirmTimesOutWhileConfirmKeepsRunning` | ✅ Passed |
| Unit | `StripePaymentSheet/StripePaymentSheetTests/.../CheckoutSessionPollerTests.swift` | `testClockSleepIgnoresTaskCancellation`, `testPollKeepsRequestingAfterItsTaskIsCanceled` | ✅ Passed |

The live test requires the debug toolbar button and 35s request delay added to `CheckoutCartView.swift`. Run it with:

```
ci_scripts/run_tests.rb --test "PaymentSheetUITest/CheckoutElementsUITests/testReopeningPaymentOptionsDuringASlowConfirmTimesOutWhileConfirmKeepsRunning"
```

The unit tests demonstrate the mechanism that lets the orphaned poll keep running once nothing is watching it — see Elaboration.

## Elaboration

Two independent, compounding gaps:

**1. The reachable gap.** `awaitPendingOperations` ([`Checkout+Internal.swift:152-172`](https://github.com/stripe/stripe-ios/blob/yuki/checkout-session-bug-finder/StripePaymentSheet/StripePaymentSheet/Source/PaymentSheet/Checkout/Checkout+Internal.swift#L152-L172)) wraps the pending operation's `.value` in `withTimeout`, but per [`Timeout.swift:58-60`](https://github.com/stripe/stripe-ios/blob/yuki/checkout-session-bug-finder/StripeCore/StripeCore/Source/Helpers/Timeout.swift#L58-L60)'s own documented contract —

> Cancellation does not propagate to unstructured Tasks... you must cancel the task yourself when `withTimeout` throws a `TimeoutError`

— it never calls `.cancel()` on the underlying operation `Task` when it times out. That's the actual cause of the impact above. Verified: no call site anywhere in `Checkout/*.swift` currently does this (grepped for `.cancel()`, `isCancelled`, `checkCancellation` — zero hits).

**2. The latent, compounding gap.** `CheckoutSessionPoller` itself also ignores `Task` cancellation even if something *did* try to cancel it:
- `sleep(for:)` ([`CheckoutSessionPoller.swift:25-31`](https://github.com/stripe/stripe-ios/blob/yuki/checkout-session-bug-finder/StripePaymentSheet/StripePaymentSheet/Source/PaymentSheet/Checkout/CheckoutSessionPoller.swift#L25-L31)) uses `withCheckedContinuation` + `DispatchQueue.asyncAfter` with no cancellation handling.
- the `poll()` loop ([`CheckoutSessionPoller.swift:86-154`](https://github.com/stripe/stripe-ios/blob/yuki/checkout-session-bug-finder/StripePaymentSheet/StripePaymentSheet/Source/PaymentSheet/Checkout/CheckoutSessionPoller.swift#L86-L154)) never checks `Task.isCancelled` / `Task.checkCancellation()`.

This means fixing `awaitPendingOperations` alone (adding a `.cancel()` call on timeout) would **not** be sufficient — `CheckoutSessionPoller` would ignore that cancellation too, per the two committed unit tests.

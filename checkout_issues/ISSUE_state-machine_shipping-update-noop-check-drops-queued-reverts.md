Summary: When a merchant makes overlapping `checkout.updateShippingAddress(name:address:)` calls, a later clear or return to the currently committed address can return successfully without taking effect. After both calls finish, `checkout.session.shippingAddress` contains the earlier call's value.

Repro:

1. Create a Checkout Session with automatic tax and shipping address collection enabled. Initialize `CheckoutController` with no shipping address. No Shipping Address Element is needed.
2. Start `updateShippingAddress(name: "A", address: addressA)` in a task.
3. While its tax-region request is in flight, call and await `updateShippingAddress(name: nil, address: nil)`.
4. Await the first task. Both calls return without errors, but the final shipping address is A instead of nil.

Two related sequences reproduce the same cause: starting at A, changing to B and then requesting A leaves B; starting at A, clearing and then requesting A leaves nil. This requires overlapping programmatic API calls. The integration docs tell merchants to disable mutation controls while `isUpdating`; this is not a repro through those disabled controls.

Test:

- `StripePaymentSheet/StripePaymentSheetTests/PaymentSheet/Checkout/CheckoutShippingMutationLiveTests.swift`, `testSetThenClearWhileRequestIsInFlight`: reproduces against the real test backend with no mocked responses. `testChangeThenRestoreWhileRequestIsInFlight` and `testClearThenRestoreWhileRequestIsInFlight` reproduce the other two sequences. All three fail their expected final-address assertions; the SDK's recorded tax region also reflects the earlier call.
- `StripePaymentSheet/StripePaymentSheetTests/PaymentSheet/Checkout/CheckoutPendingOperationsTests.swift`, `testQueuedShippingSetThenClearPreservesLatestValue`: reproduces with controlled HTTP response timing. The matching change/restore and clear/restore tests also fail. Sequential set/clear and two distinct queued changes pass in both the local and live matrices.

Elaboration: `updateShippingAddress` checks whether the requested address equals `session.shippingAddress` before calling `performQueuedUpdate`. `clearShippingAddress` likewise returns immediately when the committed address is nil. These checks ignore an earlier queued update that has not committed yet, so the later call never enters the queue. The FIFO queue serializes the operations it receives correctly; the bug is discarding a later operation before enqueueing it. This is separate from the existing Shipping Address Element stale-form issue.

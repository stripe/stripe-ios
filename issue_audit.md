# Checkout issue audit

Audit of the three original `ISSUE_*.md` reports against commit `602a31c1ea0` and the local repro tests. Production code is unchanged. The two rejected reports and their invalid wallet-race test have been removed. The shipping report is rewritten around the reproduced overwrite. The original reports remain available at that commit for comparison.

## Wallet tax update: reject the reported race

The report's trigger does not survive the actual call path:

1. Express Checkout calls `expressCheckoutElementShouldConfirm`, which enters `confirm(source:makeFlow:)`.
2. The coordinator rejects confirmation if an operation is already pending. It then enqueues the entire confirmation.
3. The Apple Pay branch awaits `confirmApplePay`, which awaits `context.presentApplePay()`. That await lasts until the wallet flow returns its result; presenting the sheet does not release the queue.
4. Contact callbacks call the unqueued updater from inside that outstanding operation. Merchant updates submitted in the meantime wait behind it. `runServerUpdate` also queues its merchant closure, not just the refresh afterward.
5. Canceling before authorization waits for pending contact updates and restores the original tax region before completing the wallet operation.

Sources: [coordinator](StripePaymentSheet/StripePaymentSheet/Source/PaymentSheet/Checkout/Checkout+Confirm.swift), [Apple Pay wrapper](StripePaymentSheet/StripePaymentSheet/Source/PaymentSheet/Checkout/Checkout+Confirm+ApplePay.swift), [wallet delegates](StripePaymentSheet/StripePaymentSheet/Source/PaymentSheet/Checkout/CheckoutApplePayContext.swift), [queue](StripePaymentSheet/StripePaymentSheet/Source/PaymentSheet/Checkout/Checkout+Internal.swift), [server update](StripePaymentSheet/StripePaymentSheet/Source/PaymentSheet/Checkout/CheckoutController.swift).

The removed `testWalletUpdateBypassesQueueAndCanRaceAQueuedUpdate` called the internal updater outside the queued wallet operation. Its out-of-order responses demonstrate what happens when the helper's precondition is violated. It does not reproduce an Apple Pay integration. Starting merchant work after the wallet opens does not rescue the report: that work queues behind the wallet.

The suggested fix would introduce a deadlock: the wallet would await an update that itself waits for the wallet operation to finish. The opening comment in `CheckoutSessionWalletUpdater.swift` explicitly describes this constraint.

Additional inaccuracies:

- `isUpdating` remains true during the confirmation, so the claim that the wallet update has no loading state omits the enclosing operation's state.
- `commitSession` preserves existing local state. Replacing an API response snapshot is not equivalent to discarding every other change, and does not itself roll back server state.
- A backend mutation made outside `runServerUpdate` is a different scenario. The report does not demonstrate a client race for that case.

Audit tests passed for both orderings: rejection when an update precedes Apple Pay, and merchant updates waiting while a real wallet context handles a billing-contact callback and cancellation inside a queued operation. The latter observed exactly one update request while the wallet was open, then the restoration and merchant tax update after cancellation. The merchant's server-update closure did not start while the wallet was open. This test stubs PassKit presentation and HTTP responses; it is not an end-to-end Apple Pay system-sheet test. The production coordinator's enclosing queue is verified by source and its separate passing confirmation-serialization test.

## Pending-operation timeout: reject the cancellation-defect claim

The 30-second timer limits a second caller's wait to present payment options. It does not time out the original confirmation. `awaitPendingOperations` throws `CheckoutError.timedOut`, and `presentPaymentOptionsAwaitingMutations` catches it, dismisses the loading sheet, invokes `completion(true)`, and returns before installing the picker.

For that overload, `true` means `didCancel`. `PaymentElement.present` discards this Boolean and reports only dismissal, matching its documented return contract. Neither path reports a successful payment or promises to cancel one.

Sources: [wait contract and task ownership](StripePaymentSheet/StripePaymentSheet/Source/PaymentSheet/Checkout/Checkout+Internal.swift), [presentation and completion contract](StripePaymentSheet/StripePaymentSheet/Source/PaymentSheet/PaymentSheetFlowController.swift), [Payment Element wrapper](StripePaymentSheet/StripePaymentSheet/Source/PaymentSheet/Checkout/Payment%20Element/PaymentElement.swift).

The report's customer narrative contradicts its live repro. The customer cannot choose another card in a picker that never appears. The original confirmation remains tracked, keeps `isUpdating` true, rejects a duplicate confirmation, and returns its eventual result to the original caller. The reported Success alert is evidence that the caller receives the result, not that the confirmation is orphaned.

The existing `testAwaitPendingOperationsTimesOutWithoutCancelingQueuedWork` explicitly expects this behavior and predates the bug-hunt commit `b2eb0c55009`.

The live repro's injected delay occurs before the forwarding URLSession task is resumed. It delays sending `/confirm`, rather than delaying delivery of an already-received response. The normal example screen disables payment-method selection during an update; the repro adds a control that bypasses that restriction. Both facts belong in an honest repro description.

The poller does ignore task cancellation, but the report does not connect this to a caller that actually cancels the polling task on the alleged path. The direct poller tests demonstrate that isolated property only. Also, `pendingOperations` stores erased wrapper tasks that await separate typed tasks: canceling a stored wrapper would not automatically cancel the actual confirmation task, even before considering the poller. Adding `.cancel()` at the timeout site is not a demonstrated fix.

A narrower UX observation is supported: the loading sheet dismisses after a timeout without showing an explanation, and `PaymentElement.present` cannot convey the reason. Whether that API needs error reporting is a separate product/API decision. It does not establish that a pending payment should be canceled.

The added 35-second confirmation test passed using the actual FlowController presentation method and callback: the loading sheet was dismissed, the callback received `didCancel == true`, the confirmation had not yet returned, and `isUpdating` remained true. The original caller then received success. A second added test passed for timeout followed by a duplicate confirmation attempt: the duplicate was rejected, and the original confirmation completed and cleared the queue normally.

## Shipping Address Element: retain, with a narrower explanation

The form is initialized from shipping defaults or the initial session address. `updateShippingAddress` changes `session.localState.shippingAddress` and optionally updates the tax region, but neither it nor `updateForSessionChange` refreshes the retained address form. `present` reuses that form.

Sources: [element construction and address updates](StripePaymentSheet/StripePaymentSheet/Source/PaymentSheet/Checkout/CheckoutController.swift), [presentation and save delegate](StripePaymentSheet/StripePaymentSheet/Source/PaymentSheet/Checkout/Shipping%20Address%20Element/ShippingAddressElement.swift), [form values and save action](StripePaymentSheet/StripePaymentSheet/Source/PaymentSheet/AddressViewController/AddressViewController.swift).

The original unit test only checks `configuration.defaultValues`. That alone would not prove stale visible fields: configuration can remain unchanged while a form's current values change. The audit extends it to read the actual form values and save them through the element's save delegate. The live repro is extended to press Save Address after reopening the stale form and check which address appears in the cart.

The live test passed against the test backend with automatic tax and shipping address collection enabled. The cart first showed Jane Doe / 510 Townsend St, then Alex Direct / 1 Direct Ave after the direct update. Reopening showed Jane Doe. Saving without edits restored Jane Doe / 510 Townsend St in the cart and removed Alex Direct / 1 Direct Ave. This is a reproduced overwrite of the session address, beyond stale display alone.

The `private let` reference is not the cause: it can still refer to an object whose state changes. The missing synchronization is the relevant fact. Also, these Checkout APIs are exposed through SPI; the report should not imply they are generally available public SDK APIs.

Here, “session address” means the address exposed by `CheckoutController.session`. It is held locally until confirmation; a tax-region update is not proof that the full shipping address has already been persisted to the server. No actual shipment or completed payment with the stale address is claimed by this audit.

## Execution results

Environment: Xcode 27.1, iOS 18.5 simulator (iPhone 12 mini).

Live UI tests: **2 passed, 0 failed**. Result bundle: `/tmp/checkout-issue-audit-ui.xcresult`; command and build log: `/tmp/checkout-issue-audit-ui.log`.

- `CheckoutElementsUITests/testShippingAddressElementShowsStaleAddressAfterExternalUpdate`: passed in 29 seconds, including the added save-and-overwrite assertions.
- `CheckoutElementsUITests/testReopeningPaymentOptionsDuringASlowConfirmTimesOutWhileConfirmKeepsRunning`: passed in 64 seconds. The picker never appeared, Buy stayed disabled after the presentation timeout, and the original payment produced a Success alert.

Targeted unit tests: **11 passed, 0 failed**. Result bundle: `/tmp/checkout-issue-audit-unit.xcresult`; exact command and build log: `/tmp/checkout-issue-audit-unit.log`.

| Test | Evidence |
| --- | --- |
| `CheckoutApplePayContextTests/testQueuedWalletPresentationSerializesContactUpdatesAndMerchantUpdates` | Wallet callbacks and restoration execute before queued merchant updates; the merchant server closure waits too. Added for this audit. |
| `CheckoutApplePayContextTests/testDidFinish_notStarted_waitsForBillingTaxUpdateBeforeCanceling` | Canceling the wallet waits for the contact update and restoration. |
| `CheckoutPendingOperationsTests/testApplePayConfirmationCannotStartWhileAnUpdateIsPending` | The Apple Pay confirmation coordinator rejects the reverse ordering. Added for this audit. |
| `CheckoutPendingOperationsTests/testWalletUpdateBypassesQueueAndCanRaceAQueuedUpdate` | Passed during the audit, but did not represent the production call path. Removed from the branch. |
| `CheckoutPendingOperationsTests/testAwaitPendingOperationsTimesOutWithoutCancelingQueuedWork` | Existing coverage expects the wait to time out without canceling queued work. |
| `CheckoutConfirmationStubbedTests/testSessionUpdateQueuedDuringConfirmationWaitsForConfirmation` | The real confirmation coordinator serializes later operations behind confirmation. |
| `CheckoutConfirmationStubbedTests/testPendingWaitTimeoutLeavesConfirmationOwnedByOriginalCaller` | After the wait timeout, duplicate confirmation is rejected and the original caller receives success. Added for this audit. |
| `CheckoutConfirmationStubbedTests/testPaymentOptionsWaitTimeoutReportsCancellationWhileConfirmationContinues` | The actual presentation timeout callback reports cancellation; the original confirmation subsequently succeeds. Added for this audit. |
| `ShippingAddressElementConfigurationTests/testShippingAddressElementDoesNotReflectAddressUpdatesMadeOutsideTheElement` | Actual form values remain stale; saving overwrites the newer address. Clearing the session address also leaves old form values. Extended for this audit. |
| `CheckoutSessionPollerTests/testClockSleepIgnoresTaskCancellation` | Confirms the production clock ignores task cancellation in isolation. |
| `CheckoutSessionPollerTests/testPollKeepsRequestingAfterItsTaskIsCanceled` | Confirms the poller continues after direct cancellation in isolation; does not prove cancellation occurs on the reported path. |

The changed Swift test files passed the pinned SwiftLint checks. The build and test run passed. No production behavior was changed. The branch update retains the audit evidence and the valid shipping report.

After removing the invalid wallet-race test, the full `CheckoutPendingOperationsTests` class was rerun: **8 passed, 0 failed**. Result bundle: `/tmp/checkout-issue-branch-update.xcresult`. The repository format and lint scripts also passed.

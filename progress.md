# Progress Tracker

Source of truth for what's been covered. Update this after finishing (or abandoning) a surface —
don't rely on conversation history, it gets compacted/restarted.

Status values: `not started` / `in progress` / `done`.

## Audit outcome (2026-11-03)

One issue remains: saving the stale Shipping Address Element form overwrites a newer address set directly by the merchant. The wallet-race and confirmation-cancellation reports were rejected and removed. See [issue_audit.md](issue_audit.md) for source traces, test results, and limitations. Other exploration notes below have not been re-audited.

## Code-reading surfaces (search_strategy.md)

| # | Surface | Status | Result |
|---|---------|--------|--------|
| 1 | state-machine | done | Audit: confirmation and later merchant updates remain serialized. The payment-options wait timeout does not cancel the original confirmation; it continues to report its result to its caller. Earlier investigation also found no stale confirmation-challenge defect. |
| 2 | polling-async | done | Report rejected and removed. A payment-options presentation timeout reports cancellation while the original confirmation remains tracked. Direct poller cancellation tests establish an isolated behavior, not the alleged confirmation bug. |
| 3 | confirm-flow | done | Report rejected and removed. The entire Apple Pay flow holds a queued operation; contact updates run within it, and later merchant updates wait. The original race test violated the helper's queued-context precondition and was removed. New tests cover both operation orderings. |
| 4 | session-model-and-parsing | done | No bug found. Investigated `makeExchangeRateMeta`'s `.first(where:) ?? .first` fallback (looked like a currency mismatch risk if `localCurrencyOptions` had >1 entry) — ruled out: `CurrencySelectorUtilities` is explicitly architected as a 2-option (local vs. integration) toggle, confirmed by its own doc comment, so `localCurrencyOptions` is always a single entry in practice and the fallback never diverges. Also checked address-merging (`Checkout+Session+AddressMerging.swift`, fine) and money formatting (`makeAmount` uses `NSDecimalNumber`, avoids float imprecision, fine). |
| 5 | sub-elements | done | Confirmed `ISSUE_sub-elements_shipping-address-element-never-resyncs-after-construction.md`. Direct session address updates do not refresh the form. Reopening and saving restores the stale address over the newer one; reproduced against the test backend. |
| 6 | config-and-analytics | done | No bug found. Checked `AdaptivePricingFlagImageManager` (graceful emoji fallback on download failure, one-time prefetch is correct since the local/integration currency pair is fixed per session) and `Checkout+Configuration.swift` (plain config plumbing). Did not deep-dive `Checkout+Analytic(s).swift` or `STPPaymentMethodAddress+Checkout.swift` — lowest-priority surface per search_strategy.md, diminishing returns given findings so far cluster in concurrency/coordination code, not config/analytics. |

## Docs-driven surfaces (docs_driven_strategy.md)

| # | Surface | Status | Result |
|---|---------|--------|--------|
| 1 | core-lifecycle | done | No bug found. "No double charges" guarantee verified sound (`Checkout+Confirm.swift:286-297`). Added regression test for an untested-but-not-broken poll-phase double-confirm case (`CheckoutConfirmDuringPollTests.swift`). Preview-limitation list (tax ID, shipping options, etc.): zero client-side modeling found; inconclusive without a live-backend repro (not yet attempted). |
| 2 | multi-element-composition | done | No new bug. Checked the doc's three coordination claims against code: "only one Element confirms" (verified sound, same `confirmationInProgress`/`pendingOperations` guards checked in state-machine surface), "Currency Selector updates amounts shown by other Elements" (verified — `ExpressCheckoutElement` subscribes to `$session` reactively, `PaymentElement` is refreshed via `updateForSessionChange()`'s explicit dispatch), "Shipping Address Element updates taxes/totals" (outbound direction works via its delegate callback; the *inbound* gap — external updates not reaching the element — is the already-filed sub-elements bug, not new). |
| 3 | express-checkout-wallets | done | No new bug. Double-tap: defended at both UI layer (`isUpdating` disables all wallet buttons the instant `pendingOperations` becomes non-empty, synchronously, before any `await`) and logic layer (`confirm()`'s guards, verified in state-machine surface). Wallet-becomes-unavailable-after-mount: `CheckoutApplePayContext.create` re-checks `PKPaymentAuthorizationController.canMakePayments()` fresh at tap time, not relying on stale mount-time availability. Cancellation mid-flow: already covered thoroughly in confirm-flow surface (`CheckoutApplePayContext`'s `.pending` state machine). |
| 4 | adaptive-pricing-currency | done | No new bug. Checked whether a wallet (Apple Pay) could confirm with a stale currency if tapped right after a currency switch — can't: `confirm()`'s `pendingOperations.isEmpty` guard + `isUpdating`-driven button disabling (same mechanism verified elsewhere) blocks the tap until the currency update settles. The 24h exchange-rate-validity guarantee is server-enforced with no client-side expiry tracking to get wrong. Currency Selector Element's availability guard (`CurrencySelectorUtilities.adaptivePricingData`) correctly hides the element when any precondition (`adaptivePricingActive`, non-empty `localizedPricesMetas`, `exchangeRateMeta`, `activePresentmentCurrency`) is missing. |
| 5 | shipping-and-tax | done | No new bug. Checked whether a failed tax computation (e.g. unsupported country) leaves `shippingAddress` "half-saved" locally while the tax portion fails — it doesn't: `performUnqueuedUpdate` throws before reaching `commitSession`/`mutateLocalState` on any API failure, so a rejected address update is fully rejected, not partially applied. Checked rapid repeated shipping edits — correctly serialized/converges via the FIFO queue (same mechanism verified in state-machine surface). The Express Checkout Element wallet's tax updates commit to `CheckoutController.session` inside the queued wallet operation; the audit rejected the claimed race. |
| 6 | appearance-and-migration | done | No bug found, lighter pass (lowest-priority surface). Checked appearance config files for risky force-unwraps/crashes (none). Considered whether a merchant mixing old PaymentSheet/PaymentIntents with new CheckoutController in the same app could corrupt shared state (e.g. `AnalyticsHelper.shared` session ID if both flows run concurrently) — plausible but speculative and low-severity (analytics attribution only, not money/correctness); didn't find concrete reachable harm, so not filed per the no-theoretical-bugs rule. |

## Repro status after audit

- **Shipping address:** live UI repro passed, including reopening and saving the stale form over the newer address. The unit repro also verifies actual form fields and clearing the address.
- **Payment-options timeout:** live UI repro passed. The loading sheet dismisses without opening the picker, Buy remains disabled, and the original confirmation produces Success. A separate unit test verifies `didCancel == true` on presentation completion. This does not establish a cancellation defect.
- **Wallet race:** source tracing and queue/delegate tests reject the reported trigger. Merchant updates submitted while the wallet is open wait for the wallet operation to finish. PassKit presentation and HTTP responses were stubbed for this check; no end-to-end system-sheet race was reproduced.

The earlier instruction to leave bug-hunt work uncommitted is superseded for this update by the user's request to update the branch and issue reports.

## Guide-driven live exploration round 2 (2026-10-31, continued)

Went through more guide sections live against the real backend, beyond the bugs already filed:

- **Currency switch after shipping/tax established** (reverse order from the one working
  reference test): tried 4 times, inconsistent results (sometimes only tax lagged, sometimes
  neither total nor tax updated, with neither the success nor failure analytics event firing —
  meaning the tap likely never reached the SDK handler). Concluded likely test-automation
  flakiness, not a product bug, per instruction. Removed the test; not filed.
- **Apple Pay: cancel before authorizing, then retry** — new coverage
  (`testCancelingApplePayLeavesCheckoutUsable`). Passed: checkout returns to a fully usable
  state, second attempt completes normally. No bug.
- **Payment Element + Express Checkout coordination**, with a card already entered in Payment
  Element before switching to Apple Pay — new coverage
  (`testApplePayConfirmsWhenACardIsAlreadyEnteredInPaymentElement`). Passed: exactly one
  confirmation attempt, via ECE; the entered card was never submitted. No bug.
- **Link wallet**: confirmed via code that Link has no analog to Apple Pay's unqueued wallet
  tax-update path (`updateTaxRegionWithoutEnqueueing` has exactly one caller,
  `CheckoutApplePayContext`), and the audit rejected the claimed Apple Pay race as well. Didn't find a
  quick way to verify the Link button's displayed email re-syncs on session change (its
  rendering isn't in any Checkout-specific file, so likely shared, already-tested Link
  infrastructure) — dropped rather than sink more time into locating it.

## Open threads worth revisiting

- **core-lifecycle's preview-limitation list**: per the updated guidance, absence of client code
  for a documented limitation should now be filed, not left inconclusive. Worth a short follow-up
  pass using the live test backend (`STPTestingAPIClient+Swift.swift`) rather than a fresh full
  re-run of that surface.

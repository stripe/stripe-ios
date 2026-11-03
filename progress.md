# Progress Tracker

Source of truth for what's been covered. Update this after finishing (or abandoning) a surface —
don't rely on conversation history, it gets compacted/restarted.

Status values: `not started` / `in progress` / `done`.

## Code-reading surfaces (search_strategy.md)

| # | Surface | Status | Result |
|---|---------|--------|--------|
| 1 | state-machine | done | No new bug. The `awaitPendingOperations` finding (filed under polling-async) actually lives here (`Checkout+Internal.swift`). Ruled out: confirm vs. shipping/tax-update races (both go through the same `pendingOperations` FIFO queue, `confirm()` additionally requires the queue empty before starting, so they can't interleave); stale `confirmationChallenge` after a failed confirm (its tokens are fetched fresh per attempt via `fetchTokensWithTimeout()`/`complete()`, not cached — doesn't need `updateForSessionChange()` to refresh). |
| 2 | polling-async | done | Filed `ISSUE_polling-async_awaitpendingoperations-doesnt-cancel-timed-out-confirm.md`. Also ruled out: `CheckoutSessionWalletUpdater.updateTaxRegionWithoutEnqueueing` race (Apple Pay delegate serialization makes it unreachable), queued updater races (FIFO queue serializes them). |
| 3 | confirm-flow | done | Filed `ISSUE_confirm-flow_wallet-tax-update-bypasses-queue-and-races.md` — Apple Pay's `updateTaxRegionWithoutEnqueueing` bypasses `pendingOperations` and can race a queued update (e.g. Payment Element billing sync); verified with a test + sanity-check flip. Also investigated (no bug): `CheckoutApplePayContext`'s double-`didFinish` scenario (defended by `resume()`'s continuation nil-check), `confirmationChallenge` reuse across attempts (by design — fetches fresh tokens per attempt), Link's shared `confirmLinkPaymentOption` completion plumbing (inherited from mature PaymentSheet code, not Checkout-specific, left alone). |
| 4 | session-model-and-parsing | done | No bug found. Investigated `makeExchangeRateMeta`'s `.first(where:) ?? .first` fallback (looked like a currency mismatch risk if `localCurrencyOptions` had >1 entry) — ruled out: `CurrencySelectorUtilities` is explicitly architected as a 2-option (local vs. integration) toggle, confirmed by its own doc comment, so `localCurrencyOptions` is always a single entry in practice and the fallback never diverges. Also checked address-merging (`Checkout+Session+AddressMerging.swift`, fine) and money formatting (`makeAmount` uses `NSDecimalNumber`, avoids float imprecision, fine). |
| 5 | sub-elements | done | Filed `ISSUE_sub-elements_shipping-address-element-never-resyncs-after-construction.md` — `ShippingAddressElement` is a `private let`, seeded once at construction, with no path to learn about session changes made elsewhere (unlike Express Checkout/Currency Selector, which both correctly subscribe to a live `sessionPublisher` — verified `ExpressCheckoutElementView.swift:46-58` does this right, via `.dropFirst()` + weak-self `sink`). Did not deep-dive Payment Element or Currency Selector Element beyond this comparison — lower priority since they already use the reactive pattern Shipping Address Element lacks. |
| 6 | config-and-analytics | done | No bug found. Checked `AdaptivePricingFlagImageManager` (graceful emoji fallback on download failure, one-time prefetch is correct since the local/integration currency pair is fixed per session) and `Checkout+Configuration.swift` (plain config plumbing). Did not deep-dive `Checkout+Analytic(s).swift` or `STPPaymentMethodAddress+Checkout.swift` — lowest-priority surface per search_strategy.md, diminishing returns given findings so far cluster in concurrency/coordination code, not config/analytics. |

## Docs-driven surfaces (docs_driven_strategy.md)

| # | Surface | Status | Result |
|---|---------|--------|--------|
| 1 | core-lifecycle | done | No bug found. "No double charges" guarantee verified sound (`Checkout+Confirm.swift:286-297`). Added regression test for an untested-but-not-broken poll-phase double-confirm case (`CheckoutConfirmDuringPollTests.swift`). Preview-limitation list (tax ID, shipping options, etc.): zero client-side modeling found; inconclusive without a live-backend repro (not yet attempted). |
| 2 | multi-element-composition | done | No new bug. Checked the doc's three coordination claims against code: "only one Element confirms" (verified sound, same `confirmationInProgress`/`pendingOperations` guards checked in state-machine surface), "Currency Selector updates amounts shown by other Elements" (verified — `ExpressCheckoutElement` subscribes to `$session` reactively, `PaymentElement` is refreshed via `updateForSessionChange()`'s explicit dispatch), "Shipping Address Element updates taxes/totals" (outbound direction works via its delegate callback; the *inbound* gap — external updates not reaching the element — is the already-filed sub-elements bug, not new). |
| 3 | express-checkout-wallets | done | No new bug. Double-tap: defended at both UI layer (`isUpdating` disables all wallet buttons the instant `pendingOperations` becomes non-empty, synchronously, before any `await`) and logic layer (`confirm()`'s guards, verified in state-machine surface). Wallet-becomes-unavailable-after-mount: `CheckoutApplePayContext.create` re-checks `PKPaymentAuthorizationController.canMakePayments()` fresh at tap time, not relying on stale mount-time availability. Cancellation mid-flow: already covered thoroughly in confirm-flow surface (`CheckoutApplePayContext`'s `.pending` state machine). |
| 4 | adaptive-pricing-currency | done | No new bug. Checked whether a wallet (Apple Pay) could confirm with a stale currency if tapped right after a currency switch — can't: `confirm()`'s `pendingOperations.isEmpty` guard + `isUpdating`-driven button disabling (same mechanism verified elsewhere) blocks the tap until the currency update settles. The 24h exchange-rate-validity guarantee is server-enforced with no client-side expiry tracking to get wrong. Currency Selector Element's availability guard (`CurrencySelectorUtilities.adaptivePricingData`) correctly hides the element when any precondition (`adaptivePricingActive`, non-empty `localizedPricesMetas`, `exchangeRateMeta`, `activePresentmentCurrency`) is missing. |
| 5 | shipping-and-tax | done | No new bug. Checked whether a failed tax computation (e.g. unsupported country) leaves `shippingAddress` "half-saved" locally while the tax portion fails — it doesn't: `performUnqueuedUpdate` throws before reaching `commitSession`/`mutateLocalState` on any API failure, so a rejected address update is fully rejected, not partially applied. Checked rapid repeated shipping edits — correctly serialized/converges via the FIFO queue (same mechanism verified in state-machine surface). The Express Checkout Element wallet's shipping-triggered tax updates commit to the real `CheckoutController.session`, consistent with the already-filed confirm-flow race bug (same code path). |
| 6 | appearance-and-migration | done | No bug found, lighter pass (lowest-priority surface). Checked appearance config files for risky force-unwraps/crashes (none). Considered whether a merchant mixing old PaymentSheet/PaymentIntents with new CheckoutController in the same app could corrupt shared state (e.g. `AnalyticsHelper.shared` session ID if both flows run concurrently) — plausible but speculative and low-severity (analytics attribution only, not money/correctness); didn't find concrete reachable harm, so not filed per the no-theoretical-bugs rule. |

**Note:** do not `git add`/`git commit` anything (user instruction, 2026-10-31). Leave repro
tests and `ISSUE_*.md` files as uncommitted worktree changes. (One earlier commit, `b2eb0c5`,
predates this instruction and already captured the state through confirm-flow — don't amend it.)

## Live repro status (against the real test backend, in the PaymentSheet Example app)

- **sub-elements** (`ShippingAddressElement` staleness): DONE. Live UI test
  `testShippingAddressElementShowsStaleAddressAfterExternalUpdate` in
  `CheckoutElementsUITests.swift` passes against the real backend. Required adding a debug
  button to `CheckoutCartContentView.swift` and an accessibility identifier to disambiguate
  the real "Edit" button from an unrelated one left in the background view hierarchy.
- **polling-async** (`awaitPendingOperations` timeout): DONE. Live UI test
  `testReopeningPaymentOptionsDuringASlowConfirmTimesOutWhileConfirmKeepsRunning` passes
  against the real backend. Required a debug toolbar button in `CheckoutCartView.swift`
  (bypasses this screen's `.disabled(checkout.isUpdating)`) and bumping
  `delayCheckoutClientRequests` from 1s to 35s to exceed the 30s timeout for real.
- **confirm-flow** (wallet tax race): NOT achieved live. Discovered the ECE button is disabled
  by the SDK itself (`CheckoutController.swift:26-30`) while any other update is queued, so the
  simplest trigger (edit billing field, then tap Apple Pay) is structurally blocked — corrected
  the ISSUE file's Summary/Repro accordingly. The real reachable trigger needs a merchant's
  background code to fire a queued update while the Apple Pay system sheet (a separate process,
  `com.apple.PassbookUIService`) is already open and mid-interaction; didn't get a clean,
  precisely-timed cross-process UI test working within reasonable effort. Code-level unit test
  remains the repro of record for this one.

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
  `CheckoutApplePayContext`), so the confirm-flow race bug doesn't apply to Link. Didn't find a
  quick way to verify the Link button's displayed email re-syncs on session change (its
  rendering isn't in any Checkout-specific file, so likely shared, already-tested Link
  infrastructure) — dropped rather than sink more time into locating it.

## Open threads worth revisiting

- **core-lifecycle's preview-limitation list**: per the updated guidance, absence of client code
  for a documented limitation should now be filed, not left inconclusive. Worth a short follow-up
  pass using the live test backend (`STPTestingAPIClient+Swift.swift`) rather than a fresh full
  re-run of that surface.

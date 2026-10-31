# Progress Tracker

Source of truth for what's been covered. Update this after finishing (or abandoning) a surface —
don't rely on conversation history, it gets compacted/restarted.

Status values: `not started` / `in progress` / `done`.

## Code-reading surfaces (search_strategy.md)

| # | Surface | Status | Result |
|---|---------|--------|--------|
| 1 | state-machine | done | No new bug. The `awaitPendingOperations` finding (filed under polling-async) actually lives here (`Checkout+Internal.swift`). Ruled out: confirm vs. shipping/tax-update races (both go through the same `pendingOperations` FIFO queue, `confirm()` additionally requires the queue empty before starting, so they can't interleave); stale `confirmationChallenge` after a failed confirm (its tokens are fetched fresh per attempt via `fetchTokensWithTimeout()`/`complete()`, not cached — doesn't need `updateForSessionChange()` to refresh). |
| 2 | polling-async | done | Filed `ISSUE_polling-async_awaitpendingoperations-doesnt-cancel-timed-out-confirm.md`. Also ruled out: `CheckoutSessionWalletUpdater.updateTaxRegionWithoutEnqueueing` race (Apple Pay delegate serialization makes it unreachable), queued updater races (FIFO queue serializes them). |
| 3 | confirm-flow | in progress | — |
| 4 | session-model-and-parsing | not started | — |
| 5 | sub-elements | not started | — |
| 6 | config-and-analytics | not started | — |

## Docs-driven surfaces (docs_driven_strategy.md)

| # | Surface | Status | Result |
|---|---------|--------|--------|
| 1 | core-lifecycle | done | No bug found. "No double charges" guarantee verified sound (`Checkout+Confirm.swift:286-297`). Added regression test for an untested-but-not-broken poll-phase double-confirm case (`CheckoutConfirmDuringPollTests.swift`). Preview-limitation list (tax ID, shipping options, etc.): zero client-side modeling found; inconclusive without a live-backend repro (not yet attempted). |
| 2 | multi-element-composition | not started | — |
| 3 | express-checkout-wallets | not started | — |
| 4 | adaptive-pricing-currency | not started | — |
| 5 | shipping-and-tax | not started | — |
| 6 | appearance-and-migration | not started | — |

## Open threads worth revisiting

- **core-lifecycle's preview-limitation list**: per the updated guidance, absence of client code
  for a documented limitation should now be filed, not left inconclusive. Worth a short follow-up
  pass using the live test backend (`STPTestingAPIClient+Swift.swift`) rather than a fresh full
  re-run of that surface.

# Search Strategy: Parallel Bug Finding in Checkout Elements

Root: `StripePaymentSheet/StripePaymentSheet/Source/PaymentSheet/Checkout/`

Each agent:
1. Reads `bug_report_guidance.md` first.
2. Starts with its assigned surface, then follows actual callers and dependencies across boundaries. In particular, inspect the enclosing operation before claiming a queue is bypassed.
3. Reports candidates with concrete triggers and complete call paths. The lead verifies the repro before filing `ISSUE_<surface>_<description>.md` in the worktree root.
4. May edit source, including test infra helpers (this is a temporary branch, nothing here gets
   pushed). Do not run `git add`/`git commit` — leave changes uncommitted in the worktree.

## Surfaces (non-overlapping, risk-ordered)

1. **state-machine** — `CheckoutController.swift`, `CheckoutControllerLoader.swift`,
   `Checkout+Internal.swift`, `Checkout+Status.swift`.
   Focus: state transitions, re-entrancy, what happens if a confirm/update races a poll.

2. **polling-async** — `CheckoutSessionPoller.swift`, `CheckoutSessionWalletUpdater.swift`,
   `CheckoutSessionBillingAddressUpdater.swift`.
   Focus: cancellation, stale responses overwriting newer state, retry/backoff edge cases.

3. **confirm-flow** — `Checkout+Confirm.swift`, `Checkout+Confirm+ApplePay.swift`,
   `Checkout+Confirm+Link.swift`, `CheckoutApplePayContext.swift`, `PaymentOption+Checkout.swift`.
   Focus: double-confirm, wallet cancellation mid-confirm, error-path state left inconsistent.

4. **session-model-and-parsing** — `Checkout+Session*.swift`, `API Models/*.swift`,
   `CheckoutSessionUpdate.swift`, `CheckoutError.swift`.
   Focus: server response parsing/decoding, totals/discount/tax math, address merging logic.

5. **sub-elements** — `Currency Selector Element/`, `Express Checkout Element/`,
   `Payment Element/`, `Shipping Address Element/` (4 small, self-contained dirs; one agent
   can cover all four, or split if parallelism budget allows).
   Focus: each element's own state vs. the CS it's bound to going stale/updating underneath it.

6. **config-and-analytics** (lowest priority, optional) — `Checkout+Configuration.swift`,
   `Checkout+ApplePayConfiguration.swift`, `Checkout+Analytic*.swift`,
   `AdaptivePricingFlagImageManager.swift`, `CurrencySelectorUtilities.swift`,
   `STPPaymentMethodAddress+Checkout.swift`.

## Why this split

- Surfaces 1–3 are the state/async core — where checkout bugs actually live (races, stale
  state, double-fire). Prioritize agent effort here.
- Surface 4 is data correctness (parsing/money math) — different bug shape (wrong value, not
  wrong state), worth a dedicated agent rather than mixing into the state-machine agent.
- Surface 5 bundles four small dirs into one agent to stay within the project's "~10 agents"
  guideline while still isolating UI-element-specific bugs from core logic.
- Boundaries follow existing file naming (`Checkout+X.swift`), so overlap between agents should
  be rare; the merge/dedup pass (below) catches what isn't.

## After all agents finish: merge pass

One more agent reads all `ISSUE_*.md` files, dedupes by root cause (not by filename), and
produces a single ranked list (confidence, then surface 1–3 before 4–6) for human review.

## Execution after the audit

Run one bounded scenario matrix per round. Use one or two cheaper agents for read-only evidence gathering when delegation is available. The lead verifies the complete call path and concrete repro before accepting a finding; agent confidence is not evidence. Known unfinished preview features are excluded. Record what was actually checked in `progress.md`, rather than marking a whole surface done after a partial pass.

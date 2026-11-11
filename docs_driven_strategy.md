# Search Strategy: Public-Docs / Integrator-Driven Bug Finding

Different angle from `search_strategy.md`: instead of reading internal source for risk
patterns, start from the public integration docs as the spec, adopt a merchant-integrator
persona, and hunt for places where the SDK doesn't deliver what the docs promise, or where a
plausible merchant/customer action isn't handled.

This catches a different bug *shape*: contract violations and misuse-handling gaps, not
internal races. Run alongside `search_strategy.md`, not instead of it — same
`bug_report_guidance.md` format, same `checkout_issues/ISSUE_<surface>_<description>.md` output, same merge
pass at the end.

Docs root (fetch each with `execute_internal_search` / `fetch_internal_search_result`, type
`stripe_doc`): `https://docs.corp.stripe.com/payments/mobile/checkout-sessions` and siblings.

## Scope: supported behavior

Per the user's 2026-11-03 direction, do not spend time on known unfinished preview features: shipping option collection, tax ID collection, checkout phone collection, and the other explicitly unsupported features. Read the current docs to distinguish supported promises from those exclusions. Missing implementation of an excluded feature is not a bug report for this hunt.

## Method per agent

For your assigned doc(s):
1. Fetch the doc. Extract every concrete claim, guarantee, and code sample.
2. Map each claim to the actual Swift API in
   `StripePaymentSheet/StripePaymentSheet/Source/PaymentSheet/Checkout/` (don't trust the doc's
   staleness — docs describe intended behavior and may lag the SDK, especially "Appearance APIs
   can change before public preview").
3. For each public entry point, run this matrix mentally (or in a real test):
   - **Wrong order**: call it before prerequisite state exists (e.g. confirm before load
     completes).
   - **Duplicate/concurrent**: call it twice, or while a prior call is still in flight.
   - **Invalid/boundary config**: nil, empty, zero-amount, unsupported country/currency.
   - **Customer interrupts**: backgrounds the app, loses network, cancels a system sheet
     (Apple Pay, Google Pay auth), mid-flow.
4. File via `bug_report_guidance.md`.

## Verification: use the live test backend, not just stubs

`StripePayments/StripePaymentsTestUtils/STPTestingAPIClient+Swift.swift`'s
`createCheckoutSession(...)` hits a real playground backend and can construct an arbitrary
Checkout Session (it already takes params like `automaticTax`, `allowPromotionCodes`,
`allowedShippingCountries`; use these supported parameters to construct sessions that exercise real address, tax,
discount, and payment-method behavior). Prefer this over stubbed/mocked unit tests for
anything you're testing against a *documented claim* — a stub only proves your code does what
you told it to; a live session proves the SDK does what the docs promise against a real backend
response.

You may edit this helper (and any other source, including test infra) to add the params you
need — this is a temporary branch, nothing here gets pushed upstream. Do not run `git add`/
`git commit` — leave repro tests and `checkout_issues/ISSUE_*.md` files as uncommitted changes in the worktree.

## Partition (6 agents, by doc)

1. **core-lifecycle** — `/payments/checkout-sessions`, landing `/payments/mobile/checkout-sessions`.
   Test the explicit guarantees: "No double charges," session expiration/status tracking.
   Double-confirm, confirm-after-expiry, confirm-during-poll.

2. **multi-element-composition** — `build-a-checkout-page`.
   Elements "automatically share data and coordinate" — test what happens when one Element's
   state changes (shipping address) while another (Payment Element) is mid-render or mid-submit
   with stale data.

3. **express-checkout-wallets** — `express-checkout-element` (+ `accept-a-payment` sibling).
   Customer cancels Apple Pay/Google Pay sheet mid-flow; wallet becomes unavailable after mount
   (e.g. device state changes); double-tap before first wallet confirm resolves.

4. **adaptive-pricing-currency** — `adaptive-pricing`, general Adaptive Pricing doc.
   Switch currency mid-checkout after totals shown; exchange-rate-validity edge (doc states a
   24h guarantee — what happens right at/after expiry); unsupported country/business combos.

5. **shipping-and-tax** — `/tax/checkout`, Address Element docs.
   Address change that should trigger a tax/total recompute — does it, reliably, every time?
   Partial/invalid address; country not supported by Tax.

6. **appearance-and-migration** — `customize-appearance`, `migrate-from-payment-intents`.
   Merchant mixes old PaymentIntent-based code with new CheckoutController in the same screen;
   appearance misconfiguration causing functional (not just visual) breakage.

## Why this split

Mirrors the doc structure 1:1, so each agent's scope is exactly "one spec," no overlap by
construction. Core lifecycle (1) is highest-value — it's the one with explicit, directly
falsifiable promises ("no double charges"). Composition (2) and wallets (3) are where
cross-component state bugs live, same risk shape as `search_strategy.md` surfaces 1–3 but
reached by acting-as-integrator instead of reading source.

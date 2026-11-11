# Checkout bug bash — evidence and coverage

Scope: complete the supported-flow pass in `search_strategy.md` and `docs_driven_strategy.md`. Shipping options, tax ID collection, phone collection, promotion-code support, and other documented unfinished preview features are excluded. Baseline: `5efd450a813`. The user subsequently requested committing and pushing the reports and repros for shareable links; that instruction supersedes the earlier uncommitted-only guidance. Production SDK code is unchanged.

## Current status: requested iOS guide walkthrough finished

The fresh sentence-by-sentence audit is in [integration_guide_walkthrough.md](integration_guide_walkthrough.md). It assembles and runs a separate example-app screen using the guide's configuration, skips generic Stripe setup as requested, and uses only backend transport helpers. Both UIKit and SwiftUI, sheet and embedded payment collection, completed real payments. Fourteen UI scenarios produced twelve successful flows/controls and two intentionally failing bug repros. Fulfillment requirements were checked against the guide, Stripe's fulfillment contract, and a real SEPA `.completed(.unpaid)` result; no merchant fulfillment server was deployed.

This pass adds **four guide reports and one SDK report**, bringing the branch to **13 reports (8 guide, 5 SDK)**. It also adds guide-only UI evidence to the existing saved-method report. This is completion of the requested core iOS guide walkthrough, not a claim that every sibling guide, platform, or payment method has been tested.

## Current issue files

| Area | Finding and report |
| --- | --- |
| SDK | [Shipping form restores an old address](checkout_issues/ISSUE_sub-elements_shipping-address-element-never-resyncs-after-construction.md) |
| SDK | [Queued shipping clears/reverts are dropped](checkout_issues/ISSUE_state-machine_shipping-update-noop-check-drops-queued-reverts.md) |
| SDK | [COP display rounds away cents](checkout_issues/ISSUE_session-model_formatted-cop-total-rounds-away-cents.md) |
| SDK | [Link web handoff retains old email](checkout_issues/ISSUE_config_link-web-handoff-keeps-email-before-update.md) |
| SDK — new | [Email update clears selected card with Link enabled](checkout_issues/ISSUE_config_email-update-clears-selected-card-with-link.md) |
| Guide | [Preview import does not expose Checkout](checkout_issues/ISSUE_integration-guide_ios-preview-import-does-not-expose-checkout.md) |
| Guide | [Pay requires optional shipping](checkout_issues/ISSUE_integration-guide_pay-button-requires-optional-shipping.md) |
| Guide | [Result switch fails with a resilient Swift 6 framework](checkout_issues/ISSUE_integration-guide_result-switch-fails-with-swift6-framework.md) |
| Guide | [Missing Customer/save/reuse workflow](checkout_issues/ISSUE_integration-guide_missing-saved-payment-method-workflow.md) |
| Guide — new | [Return URL step configures an unused API](checkout_issues/ISSUE_integration-guide_return-url-configures-unused-embedded-api.md) |
| Guide — new | [Pay ignores required email](checkout_issues/ISSUE_integration-guide_pay-button-ignores-required-email.md) |
| Guide — new | [SwiftUI reloads checkout on navigation return](checkout_issues/ISSUE_integration-guide_swiftui-reloads-checkout-on-navigation.md) |
| Guide — new | [Fulfillment omits payment-status and deduplication rules](checkout_issues/ISSUE_integration-guide_fulfillment-omits-payment-status-and-deduplication.md) |

New fixtures: `Checkout Guide/CheckoutGuideContainer.swift`, `CheckoutGuideUITests.swift`, and the `STP_CHECKOUT_GUIDE` example-app route. Production SDK code is unchanged. [Portable results](guide_repros/walkthrough-results.txt) and report-linked screenshots distinguish actual failures from corrected harness interactions. Pinned SwiftLint and whitespace checks pass.

## Correction and integration-guide follow-up (earlier pass)

The earlier completion claim was too broad: the SDK scenario pass used docs as input but had not audited the guide's samples themselves. A subsequent direct audit of the core iOS guide found **three additional guide issues**, bringing the local report count to seven. See [integration_guide_audit.md](integration_guide_audit.md) for exact scope, sources, compiler controls, live checks, and limits.

- [Documented SPI import does not expose CheckoutController](checkout_issues/ISSUE_integration-guide_ios-preview-import-does-not-expose-checkout.md).
- [Pay-button predicate requires shipping even when collection is omitted](checkout_issues/ISSUE_integration-guide_pay-button-requires-optional-shipping.md).
- [Result switch fails in Swift 6 with a resilient framework](checkout_issues/ISSUE_integration-guide_result-switch-fails-with-swift6-framework.md).

The guide's server request body was also exercised verbatim and successfully loaded and paid. `guide_repros/check_swift_samples.py` reproduces both compilation problems and verifies their minimal corrections. These checks do not establish exhaustive coverage of all sibling guides or Android/React Native examples.

## SDK behavior findings

1. [Shipping Address Element restores stale form values](checkout_issues/ISSUE_sub-elements_shipping-address-element-never-resyncs-after-construction.md). Retained from the original audit; real UI reproduction and a form-level test verify the overwrite.
2. [Overlapping shipping API calls discard later clears/reverts](checkout_issues/ISSUE_state-machine_shipping-update-noop-check-drops-queued-reverts.md). Three failing local repros and the same three failures against the real test backend; two controls pass in each matrix. This requires overlapping programmatic calls, not taps through controls disabled while `isUpdating`.
3. [COP total strings round away cents](checkout_issues/ISSUE_session-model_formatted-cop-total-rounds-away-cents.md). A real session for 1,234,567 minor units exposes `COP 12,346` instead of `COP 12,345.67` on iOS 18.5, en_US. Numeric amounts remain correct. JPY control passes.

4. [Link web handoff retains the previous email](checkout_issues/ISSUE_config_link-web-handoff-keeps-email-before-update.md). Real session creation and initial Link lookup; after `updateEmail`, the session and Payment Element contain the new email but generated web parameters still contain the old email. No web presentation or payment is claimed by this repro.

The SDK scenario matrix below finished with four distinct root causes. It was not a full guide-sample audit; the follow-up and correction above record that additional work.

## Coverage and evidence

| Area | Checks | Result |
| --- | --- | --- |
| State and queue | Shipping overlap/revert/clear; confirmation/update ordering; duplicate confirmation; failures release pending work | Shipping defect above. Core regressions pass; real duplicate confirmation rejected while the original completes. |
| Polling and lifecycle | Request failures, rate limiting/backoff, deadline, preservation of latest response, next actions, cancellation ownership, terminal confirmation | Core regression matrix passes; real reconfirmation of a completed session rejected. |
| Payment Element and billing tax | Embedded/sheet selection, clear, saved-card change, rollback on failed tax update, selection restoration, form tax requirements | Regression matrices pass. Incomplete saved addresses are filtered; new-method forms append/widen required tax fields. |
| Wallets | Apple Pay contact/tax callbacks, queue ownership, tokenization failure/retry/cancel; Link decline/close/retry and response propagation | Regression matrices pass. All six live UI flows passed. |
| Data and currency | Decoding/statuses, line items/taxes, currency changes, flags/labels, currency precision | COP display defect above. Real EUR→USD→EUR round trip and JPY control pass. |
| Configuration and eligibility | Defaults, allowed countries, saved methods, Link/Apple Pay availability, analytics attribution, errors | Regression matrices pass. Link email handoff defect above; defaults/eligibility/analytics regression checks pass. |
| Live payment lifecycle | Declined card→valid-card retry, concurrent confirm, terminal confirm, free checkout | All behavioral checks passed. Duplicate/terminal test initially checked generic localized text; corrected to inspect integration-error payload and passed. |
| Final dedup | Retained form, pre-enqueue no-op checks, currency precision, cached Link email | Four distinct root causes; no duplicate reports. |

## Test runs

Environment: Xcode 27.1, iOS 18.5, iPhone 12 mini simulator `E52DA269-0E66-4555-9B2E-E74C04B128C3`.

| Result bundle under `/tmp/` | Result |
| --- | --- |
| `checkout-supported-updates-unit.xcresult` | 3 intentionally failing shipping repros, 2 passing controls. |
| `checkout-supported-updates-live.xcresult` | Same 3 failures and 2 controls against real backend; HTTPStubs observes request starts but returns false and supplies no response. |
| `checkout-bash-core.xcresult` | 173 passed, 2 skipped; three known shipping repro failures deliberately excluded. |
| `checkout-bash-live.xcresult` | 4 passed; COP repro failed; duplicate/terminal test had two erroneous localized-text assertions, subsequently corrected. |
| `checkout-bash-remaining.xcresult` | 211 passed, including corrected live duplicate/terminal test; 1 crashed because the new Link test omitted attribution context. |
| `checkout-bash-link-email.xcresult` | Corrected live Link repro: 1 expected assertion failure, old email in web handoff. |
| `checkout-bash-ui.xcresult` | 6 passed: saved-card remove/add/save/confirm, multi-element tax/currency synchronization, ECE Apple Pay, Apple Pay cancel/retry, Apple Pay after card entry, Link authentication cancel/retry. |

Core classes: `CheckoutPendingOperationsTests`, `CheckoutSessionPollerTests`, `CheckoutConfirmDuringPollTests`, `CheckoutConfirmationStubbedTests`, `PaymentElementTest`, `SavedPaymentMethodBillingSyncTests`, `FlowControllerSelectionRestorationTests`, `CheckoutErrorHandlingTests`, `CheckoutDefaultsInitializationTests`, `CheckoutUnitTests`.

Remaining regression classes: `CheckoutApplePayContextTests`, `CheckoutClientAPIResponseTest`, `CheckoutClientPollResponseTests`, `CheckoutSessionPollingAPIClientTests`, `CheckoutCurrencySelectorViewTests`, `ExpressCheckoutElementViewTests`, `CheckoutAddressMergingTests`, `ShippingAddressElementConfigurationTests`, `ShippingAddressElementPresentationTests`, `STPClientAttributionMetadataTests`, `PaymentSheetLoaderAutomaticTaxTest`, `PaymentSheetFormFactoryTaxTest`, `PaymentMethodAvailabilityTests`.

New `CheckoutSupportedFlowsLiveTests` is a plain XCTestCase, without recorded responses. It selects card params through the existing test hook for API confirmation checks; the UI batch separately exercises real card entry. Existing functional tests based on `STPNetworkStubbingTestCase` are not counted as live backend evidence.

## Rejected hypotheses and limits

- Original wallet tax race: the full wallet flow already owns the queue; enqueueing its nested updater would deadlock. Original timeout/orphaned-confirmation claim: only the presentation wait times out; confirmation remains owned and reports its result. See [issue_audit.md](issue_audit.md).
- Missing billing-country tax sync: reachable saved methods and new forms are protected by filtering and automatic-tax field requirements; an early return in the sync helper alone is insufficient evidence.
- Apple Pay retry/cancel returning an earlier error: matches existing flow-level Apple Pay behavior and the failure-on-dismissal test. No demonstrated UI failure or violated API promise; no issue filed.
- Server-email override: docs explicitly prohibit overriding `customer_email` or `Customer.email`; not a supported-flow issue.
- No arbitrary network-loss/background timing sweep, physical-device/OS matrix, or 24-hour adaptive-pricing expiry wait was performed. Poll/error recovery was exercised with controlled responses; live backend and UI evidence is identified separately above.

Three cheaper readers covered wallets, data, and configuration. Their source notes are `bash_wallets_notes.md`, `bash_data_notes.md`, and `bash_config_notes.md`; candidates were checked by the lead before filing. Follow-up task transport remained broken, so the lead owns final review.

Final validation: SwiftLint passed for the new live test file; `git diff --check` passed. The preexisting untracked Xcode workspace directory is untouched. The reports and repros are being published on `yuki/checkout-session-bug-finder` at the user's request. The new shipping, COP, and Link repros intentionally assert correct behavior and fail on the current SDK; they are not fixes. The guide follow-up additionally changes a test backend helper and adds compiler fixtures; production SDK code remains unchanged.

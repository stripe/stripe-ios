# iOS integration guide audit

The earlier bug-bash completion statement overstated the documentation coverage. Reading docs to choose SDK scenarios did not establish that the guide's instructions and samples work. This follow-up directly checked the core iOS integration guide.

Source: [Build a checkout with Mobile Checkout Elements](https://docs.corp.stripe.com/payments/mobile/checkout-sessions/build-a-checkout-page), including its shared setup and customer-email content. Raw source was inspected at docs commit `6389c38d3f1864c4ced050277be636f8f29f5adb`. Search-index damage to JSX, angle brackets, and template values was not treated as a documentation defect.

## Confirmed guide defects

- [Unavailable Swift SPI import](ISSUE_integration-guide_ios-preview-import-does-not-expose-checkout.md): the documented import fails to expose CheckoutController in this branch; changing only the import compiles. Also present in the migration guide.
- [Pay requires optional shipping](ISSUE_integration-guide_pay-button-requires-optional-shipping.md): copying the UIKit/SwiftUI predicate into a non-shipping integration disables a purchase that succeeds through the SDK. The complete four-Element example with shipping enabled is unaffected.
- [Swift 6 result switch](ISSUE_integration-guide_result-switch-fails-with-swift6-framework.md): the documented handler fails against a resilient framework without an unknown-case fallback. Adding only that fallback compiles; this is not a claim about SwiftPM builds without library evolution.

These are separate from the four SDK behavior reports. No additional SDK defect was inferred from a test-harness crash or a guide compilation failure.

## Section coverage

| Guide section | Verification | Disposition |
| --- | --- | --- |
| Setup/import | Actual Swift compiler against this branch's framework; minimal corrected-import control | Import defect. Package installation on a fresh merchant machine was not exercised. |
| Return URL | Read the source instruction to register the custom scheme; test host enforces registration | The first server-payload test used unregistered `my-app` and trapped. Corrected to the host's registered scheme; not a guide defect. The redundant EmbeddedPaymentElement configuration in the included return-URL partial is not necessary, but the guide also gives the correct CheckoutController instruction. |
| Create Session | Exact example request body sent through the real playground proxy, without adding a top-level currency; load, collect shipping, select a card, and confirm | Passed. Existing preview API version supplied by the test helper. |
| Configure controller/Elements | Type-checked API calls with app-owned scaffolding and the working SPI | No additional signature mismatch after isolating the import and Swift 6 switch defects. Placeholder configuration comments require inserting the later Element snippets, as instructed. |
| Customer email | Compared server-email immutability, defaults, updateEmail, and actual Link handoff behavior | Existing Link stale-email issue already covers the supported editable-email defect. The sentence promising an error for overriding server email differs from the debug assertion/release no-op behavior; no additional issue filed for that expressly prohibited call. |
| Observe Session/order summary | Type-checked Combine and SwiftUI calls; reviewed `.receive(on:)` before state reads | COP formatting already reported as SDK behavior. Unconditional shipping in the Pay predicate is a guide defect. |
| Currency selector | Getter/config/view calls type-check; prior live currency round trip and UI synchronization passed | No new guide issue established. |
| Express Checkout | Configuration, callback, availability, and view calls type-check; prior live Apple Pay and Link UI flows passed | No new guide issue established. |
| Shipping Address Element | Presentation/configuration calls type-check; source and prior UI coverage establish save/sync paths | Existing retained-form SDK issue is not duplicated as a guide report. |
| Payment Element sheet/embedded | Presentation, selection labels, view/delegate API calls type-check; prior real sheet/card/save flows passed | This scaffold was not rendered as a separate merchant app. No new embedded-layout claim made. |
| Confirmation | Swift 5/6 compiler controls; real non-shipping purchase | Two guide defects: shipping readiness and resilient-enum switch. |
| Fulfillment/testing | Read webhook and delayed-payment instructions and the included test-method reference | No sample webhook implementation exists here to execute. Earlier live card/wallet flows are evidence only for those exercised methods. |

Android/React Native code was not compiled or run. This report covers the core iOS guide, not an assertion that every sibling guide or every external setup step has been fully tested.

## Reproduction results

- `python3 guide_repros/check_swift_samples.py <products-dir>`: both documented compile failures reproduced; both minimal corrections compiled.
- `/tmp/checkout-guide-live.xcresult`: Pay predicate assertion failed while the real purchase succeeded; server-payload test trapped on the test author's unregistered URL scheme.
- `/tmp/checkout-guide-server-control.xcresult`: corrected server-payload test passed, including payment confirmation.
- SwiftLint passed for the changed live tests and test backend helper. `git diff --check` passed. The helper gained an optional request-body override solely to send the guide's payload verbatim.

The user subsequently requested publishing these reports and repros on the bug-bash branch for shareable links. No Stripe documentation source was edited.

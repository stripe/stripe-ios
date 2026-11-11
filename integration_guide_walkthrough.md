# Fresh merchant walkthrough of the iOS integration guide

Source: [Build a checkout with Mobile Checkout Elements](https://docs.corp.stripe.com/payments/mobile/checkout-sessions/build-a-checkout-page?platform=ios), raw docs revision `de7108d190d32c9c7f82b6ae80e8be698f412931`. Line numbers below refer to the raw source, not damaged search-index extracts. Read in rendered iOS order; Android and React Native branches are not part of this exercise.

Result: the assembled guide completes payments in both iOS UI frameworks and both Payment Element presentation styles. This pass found four new guide defects and one SDK defect; it does not count unfinished preview features or test-harness mistakes as bugs.

This pass assembles and runs a separate merchant screen in the example app. It does not use the configured playground cart or its SessionFactory. The user excluded “Set up Stripe” and authorized using backend helpers instead of literally implementing the server snippets. No unfinished preview feature is counted as a defect.

## Runnable integration and explicit scaffolding

- `Example/PaymentSheet Example/PaymentSheet Example/Checkout Guide/CheckoutGuideContainer.swift` contains the assembled SwiftUI and UIKit screens. Launch with `STP_CHECKOUT_GUIDE=sheet`, `embedded`, `uikit-sheet`, `uikit-embedded`, `email`, `navigation`, `navigation-fixed`, `currency`, or `sepa`. `email-no-link` is a separate SDK control, not the guide recipe.
- The backend helper only transports the request and fetches the publishable key. The default request is the guide's $50 painting-class example: `ui_mode`, email, US/CA shipping collection, and one one-time-price item. No Customer, save flags, billing defaults, automatic tax, preselected payment method, or prefilled shipping address is injected. The CSE scenario explicitly enables Adaptive Pricing as documented and uses a test-mode German location email. The SEPA scenario uses a EUR item and enables only SEPA on that individual Session because the shared merchant's automatic method list omits it.
- Existing example app infrastructure supplies the installed SDK, working SPI, registered `payments-example` return scheme/callback forwarding, Apple Pay entitlement/merchant ID, backend URL, and preview API version. These substitutions are setup/harness facts, not evidence that the guide documents them correctly.
- App-owned scaffolding: combine repeated `CheckoutView` / `viewDidLoad` fragments; add imports, stack/scroll constraints, UIKit target wiring, alert/result UI, labels, and a separate email field with an Update button. These are ordinary application code. The guide's literal Pay predicate is preserved. The merchant-owned email field supplies standard keyboard/focus handling; its first keyboard-dismissal attempt was a harness error, not a guide snippet. The first build typo in the added address label (`address?.line1` instead of `address.line1`) was mine, not in a guide snippet; fixed before UI testing.
- UIKit uses the same guide-derived configuration as SwiftUI, hosted in the example app's SwiftUI shell. This exercises UIKit Element mounting, subscriptions, presentation, and confirmation; it does not claim to test the guide's outer UIKit caller as a separate application.

## Reading ledger

`intro` = `payments/mobile/checkout-sessions/build-a-checkout-page.md`; `main`, `setup`, and `email` = respective files under its `partials/` directory. Every iOS prose paragraph and code block after the excluded setup step is accounted for below. Template control lines and other-platform content have no merchant action.

| Source | What I understand as a merchant, and what I do | Assessment / evidence |
| --- | --- | --- |
| intro 23–25 | Build a native screen from the named Elements; follow this page's iOS tab. | Clear purpose. Links explain optional products. |
| intro 29–33 | Share one controller; expect shipping/currency/payment state to synchronize. | Clear instruction; don't create independent controllers for each Element. Previously confirmed stale shipping form after external update remains a separate SDK report. |
| intro 35 | Choose only the Elements my checkout needs. | Clear. Conflicts with unconditional shipping requirement later; existing guide issue. |
| intro 42–44 | Put optional local-currency control beside total; use Session amounts. | Clear eligibility caveat. |
| intro 46–48 | Put wallets before the form; handle their completion without asking for another Pay tap. | Clear and actionable; supply independent ECE callback. |
| intro 50–52 | Collect shipping with a sheet or my own UI; render saved address and recalculated totals. | Sheet path is explained later. Own-UI alternative isn't explained here: the paragraph doesn't name `updateShippingAddress`. An actionable improvement is to name/link `updateShippingAddress` here. The sheet recipe itself is usable. |
| intro 54–56 | Choose embedded or sheet payment collection, read selected option, add my own Pay button. | Clear. “Keep payment fields on your checkout screen” overstates embedded behavior for methods whose details still open in a sheet; inspect actual rendered card flow. |
| intro 59 / preview-access 1–4 | Preview access is required. | Existing access supplied; no signup test. |
| setup 19–95 | Generic Stripe setup. | Explicitly skipped at user's request. Existing SPI issue not rediscovered or counted again. |
| setup 97–101 / enable-payment-methods 24–26 | Enable desired methods in Dashboard; consult support matrix. | Existing test merchant supplies enabled methods. A particular method still depends on currency/eligibility; the linked support matrix is the documented route. |
| setup 104–108 / ios-return-url-embedded 4 | Register a scheme and forward URLs to Stripe. | Clear; existing example app implements it. |
| ios-return-url-embedded 10–65 | Use the callback matching my app lifecycle. | Clear separate SceneDelegate, AppDelegate, SwiftUI alternatives. |
| ios-return-url-embedded 71–76 | Also create `EmbeddedPaymentElement.Configuration` and set its returnURL. | Wrong API for this recipe: this object is never consumed by CheckoutController. I must recognize and discard this orphan configuration. Following paragraph setup 108 supplies the actual CheckoutController instruction, so this need not block a working integration. |
| setup 121 | My server creates a new Session with `ui_mode: mobile_elements` and one-time-price items. | Clear; sent through helper without extra playground options. |
| setup 124 | Server email assumes it is already known; use later alternative if editable. | Clear forward reference. |
| setup 130 | Set allowed countries if collecting shipping. | Clear; US/CA in baseline. |
| setup 133–163 | Create $50 item and return its client secret. | Executed equivalent request through authorized helper. |
| setup 165 | Omit `mode`; preview supports only `one_time_price`. | Clear; request omits mode. |
| ios-error-handling 3–5 | Display localizedDescription for load, update, confirmation, and wallet failures. Implement my own showError. | Decline displays an actionable insufficient-funds message; selecting a replacement card and retrying succeeds. Missing email reaches a generic confirmation error; see the missing readiness check below. |
| main 72 | Insert configurations for all chosen Elements before loading controller. | Clear but requires assembling later fragments first. |
| main 78–119 | UIKit: async factory loads controller; caller catches load errors and presents it. | Ordinary caller/constructor wiring. `onExpressCheckoutResult` is supplied by the parent; later Pay handler belongs to checkout VC. Parent must implement wallet result handling too, as ECE paragraph says. |
| main 124–159 | SwiftUI: keep loaded controller in State; show spinner/error/content; initialize in task. | Initial load works. Actual navigation away/back reruns the unconditional load and loses the selected card and local shipping address. [Lifecycle report](checkout_issues/ISSUE_integration-guide_swiftui-reloads-checkout-on-navigation.md). |
| main 199–201 | Configuring CSE doesn't ensure eligibility. | Clear; nil is expected, not a failure. |
| email 13–15 | Valid checkout email is required before confirm; billing email doesn't satisfy it. | Clear distinction. Need my own email path if no server email. |
| email 19–23 | Known immutable email: server customer_email or Customer.email; no local override. | Baseline follows this. The promised “returns an error” for prohibited override differs from SDK assertion/no-op, already recorded; not tested as normal integration. |
| email 25–34 | Editable email: omit server email; optionally seed configuration.defaults.email. | Actionable but no sample field binding. Email scenario starts empty, a supported case. |
| email 52 | Collect input, call updateEmail, handle validation errors, supply valid email before confirm. | Requires merchant-written UI and readiness logic. Later complete Pay snippet omits email readiness. Do not silently fix it. |
| main 210–212 | Render items, discounts, tax, shipping, totals from Session; subscribe to changes. | Data source clear, but no iOS example of anything except total. The full summary required inspecting `Session.orderSummaryItems` and switching over `.oneTimePrice`, then using the nested item fields and aggregate totals. The runnable screen supplies that code explicitly; the total-only snippet does not implement this paragraph by itself. No promotion-code implementation issue filed (unfinished preview). |
| main 215, 220 | Observe Session/isUpdating; disable mutation and confirmation controls during updates. | Clear global rule. Applied to all merchant controls, including shipping; the later shipping snippets omit it, so the assembly supplies it from this global instruction. |
| main 222–248 | Subscribe via Combine, store cancellables, update total and Pay. | App must supply labels, buttons, subscriptions storage. Requires shipping even for optional no-shipping checkout: existing report. |
| main 253–263 | SwiftUI observes CheckoutController and renders total. | Clear and assembled literally. |
| main 329–332 | Mount CSE near total; enable Adaptive Pricing in Dashboard or via server. | Both cases exercised: nil in the baseline, visible with documented Adaptive Pricing enabled and a test-mode German shopper. EUR → USD → EUR updated the same merchant total. |
| main 335–339 | Add CSE configuration before loading controller. | Clear. |
| main 341–375 | Get optional Element; mount platform view; don't reserve space on nil; instance remains available. | Clear nil handling supplied in both platform snippets. |
| main 430, 435–437 | ECE shows eligible Apple Pay/Link buttons and confirms itself. | Clear and consistent with intro. |
| main 440–455 | Configure wallet completion; supply actual Apple merchant ID/entitlements. | Existing app Apple Pay setup substituted as allowed. |
| main 457–490 | UIKit adds uiView; SwiftUI conditionally adds view when availability nonempty. | Clear. No extra frame or height code supplied. Exercise mounting. |
| main 495–499 | Link automatic; hide via display; order Apple Pay/Link with paymentMethodOrder. | Clear optional configuration; baseline keeps defaults. |
| main 501–503 | Handle ECE's completed/canceled/failed separately from Pay. | Clear callback ownership. Merchant owns result UI. |
| main 505–507 | Read availableExpressCheckoutPaymentMethods; empty means no content. | Clear; no expectation that every enabled wallet appears. |
| main 560–567 | Present address sheet; save updates Session/dismisses; read address/tax/totals; restrict countries server-side. | Clear happy path. Taxes won't appear merely from address collection—automatic tax isn't enabled by this recipe. |
| main 572–576 | Add shipping configuration before load. | Clear. |
| main 578–602 | Present async, resume after dismissal. | Clear; both supplied tap snippets omit disabling while isUpdating despite main 215. The assembly applies the earlier global rule. This snippet inconsistency alone is not evidence of corruption. |
| main 650–655 | Choose sheet or embedded; both update selected payment method. | Clear alternative paths. |
| main 658–664 | Add default PE configuration before load; get Element afterward. | Clear. No Customer association/save workflow supplied anywhere; existing saved-method omission. |
| main 683–688 | Show selected label/sublabel; tap to present; async returns on dismissal. | Clear. |
| main 693–727 | UIKit subscriptions, selection text, enabled state, present from self. | Clear fragments after merging viewDidLoad with earlier subscriptions. |
| main 732–759 | SwiftUI observes selection; empty prompt or label/sublabel; disable during updates. | Clear; assembled literally. |
| main 822–848 | UIKit embedding requires scrollable container and height delegate. | Supplied ordinary scroll/stack constraints and the documented delegate; the embedded UI rendered and completed payment. |
| main 853–865 | SwiftUI embedding uses ScrollView/VStack and Element view. | Literal assembly rendered and completed a payment; no extra height or UIKit wrapper was needed inside the supplied ScrollView/VStack. |
| main 934–935 | Add Pay; disable during updates and incomplete data. | General advice leaves merchant to determine all readiness conditions. |
| main 941–962 | UIKit confirm from self; result switch shows confirmation, does nothing on canceled, displays error. | Ordinary source build doesn't need resilient-enum workaround. Existing Swift 6 framework report remains distinct. |
| main 967–992 | SwiftUI confirm; same handler and explicit disabled predicate. | Missing email readiness and unconditional shipping. The empty-email case produces an enabled Pay button and generic confirmation error. [Readiness report](checkout_issues/ISSUE_integration-guide_pay-button-ignores-required-email.md). |
| main 1070 | Fulfill on checkout.session.completed. | Literal instruction has no payment_status guard or idempotency instruction. The dedicated Stripe fulfillment guide requires both checks; [omission report](checkout_issues/ISSUE_integration-guide_fulfillment-omits-payment-status-and-deduplication.md). |
| main 1071 | Also handle delayed success/failure. | Doesn't say what each handler should do or that completed can precede successful payment. The omission is recorded with source evidence; a delayed-flow run is supplemental evidence, not proof of a deployed webhook handler. |
| main 1073 | Verify webhook signatures; linked instructions. | Clear delegation to dedicated webhook setup guide. No real merchant fulfillment endpoint in this app. |
| main 1077–1081 / testing-auto-pm 15–29 | Test ordinary, authenticated, declined, and long UnionPay cards. | Ordinary, declined, and authentication card numbers exercised. The authentication card shows a web challenge; COMPLETE then the page-directed Close returns a paid result. Long UnionPay input was read, not separately run. |
| testing-auto-pm 47–69 | Test bank-redirect success/failure using eligible methods. | Instructions supplied; baseline USD won't show all listed EUR/GBP methods. Support-matrix link explains currency requirements. |
| testing-auto-pm 72–95 | Test SEPA delayed success/failure with supplied IBANs. | The success IBAN was exercised: actual `.completed(.unpaid)` result. The failure IBAN was read, not separately run. |
| testing-auto-pm 114 | Read general Testing reference for more scenarios. | Clear reference; not a claim of testing every supported payment method here. |

## Execution results

Fourteen distinct UI scenarios were exercised against the real test backend: **12 passed and 2 remain intentionally failing repros**. The detailed outcomes and preserved control-run output are in [walkthrough-results.txt](guide_repros/walkthrough-results.txt).

| Scenario | Result |
| --- | --- |
| UIKit sheet and embedded; SwiftUI sheet and embedded | All four completed real card payments. Rendered screenshots inspected; embedded content scrolls and the supplied UIKit height delegate works. |
| Apple Pay | Completed through the separate ECE result callback after collecting shipping. |
| Insufficient-funds card, replace card, retry | Actionable error displayed; same checkout then paid. |
| Guide's authentication card | Web challenge completed; followed its “close this window” instruction; returned `.paid`. |
| CSE with Adaptive Pricing enabled | EUR → USD → EUR updates the displayed total. Baseline correctly omits the ineligible selector. |
| SEPA with guide IBAN | Completed with `.unpaid`, demonstrating why fulfillment needs a payment-status check. [Screenshot](guide_repros/images/sepa-completed-unpaid.png). |
| Editable email | Empty email enables Pay and produces a generic error, as reported. Supplying valid email, following payment reselection, and confirming then succeeds. |
| Navigation, literal `.task` | Reproduced lost card and shipping address on return, twice. Session ID unchanged. |
| Navigation, load guard | Passed: same Session ID, retained card/address, Pay enabled. |
| Email update after selecting a card, no prior confirmation | Reproduced lost card selection with default Link configuration. |
| Same email update, Link disabled | Passed: card selection retained. This is a control, not undocumented configuration added to the baseline. |

`/tmp/checkout-guide-walkthrough.xcresult` finalized with six successes plus the navigation repro and three investigation failures. `/tmp/checkout-guide-final-flows.xcresult` finalized with four successes and the isolated email-update SDK repro. The intermediate lifecycle/CSE control run completed its tests, but Xcode hung while packaging the bundle; its completed test outcomes were preserved from the runner log. No passing conclusion depends on an unfinished test.

Earlier short runs caught test/harness mistakes: the default address button is “Save address” rather than the playground's custom “Save Address”; default sheet mode first presents a method list; optional Link signup must be completed or declined; the keyboard-dismiss helper can dismiss an entire sheet when no keyboard is present; the long SEPA form needs scrolling to Continue; and the merchant-owned email field needed ordinary focus management. Those were corrected as app scaffolding/customer interactions. The email-update selection loss persisted after those corrections and was isolated separately. No harness mistake is filed as a guide or SDK defect.

## Findings and concrete documentation changes

- [SDK: preserve the selected card when checkout email changes](checkout_issues/ISSUE_config_email-update-clears-selected-card-with-link.md).
- [Retain the SwiftUI controller across navigation](checkout_issues/ISSUE_integration-guide_swiftui-reloads-checkout-on-navigation.md).
- [Include required email in the Pay readiness example](checkout_issues/ISSUE_integration-guide_pay-button-ignores-required-email.md).
- [Explain payment-status checks and once-only fulfillment](checkout_issues/ISSUE_integration-guide_fulfillment-omits-payment-status-and-deduplication.md).
- [Remove the unrelated EmbeddedPaymentElement return-URL configuration](checkout_issues/ISSUE_integration-guide_return-url-configures-unused-embedded-api.md).
- Existing reports remain relevant: [saved-method workflow](checkout_issues/ISSUE_integration-guide_missing-saved-payment-method-workflow.md), [optional shipping](checkout_issues/ISSUE_integration-guide_pay-button-requires-optional-shipping.md), [preview import](checkout_issues/ISSUE_integration-guide_ios-preview-import-does-not-expose-checkout.md), and [resilient Swift 6 enum switch](checkout_issues/ISSUE_integration-guide_result-switch-fails-with-swift6-framework.md). The last two were already isolated and were not rediscovered by counting harness compilation failures.

Smaller clarity improvements in the ledger: show the actual iOS order-summary item traversal; name the shipping-update API beside the merchant-owned shipping UI alternative; describe embedded mode as an inline method-selection surface whose card details can open in a sheet; and apply the stated `isUpdating` rule consistently to the shipping button. These are recorded as editorial gaps, not inflated into additional reproduced SDK failures.

This exercise does not deploy a fulfillment server, alter Dashboard settings, run Android/React Native, or claim every payment method in the generic testing reference was exercised. Server creation uses the authorized helper; fulfillment is audited against the explicit guide instructions and Stripe's authoritative fulfillment contract.

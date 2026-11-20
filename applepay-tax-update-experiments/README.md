# Apple Pay tax update failures: problems and fixes

This is an overview of how Checkout's Apple Pay flow handles a failed tax update while the sheet is open.
It covers what goes wrong today and in [#7697](https://github.com/stripe/stripe-ios/pull/7697), why, and a fix that I verified.
Every claim about Apple Pay's behavior was checked on the iOS 18.5 simulator against the playground backend. The screenshots are in [`screenshots/`](screenshots).

- **Fix:** branch [`yuki/fix-apple-pay-tax-update-recovery`](https://github.com/stripe/stripe-ios/compare/joyceqin/fix-apple-pay...yuki/fix-apple-pay-tax-update-recovery), stacked on #7697. The diff is in [`fix.diff`](fix.diff).
  I closed that PR because it was opened by mistake. Take whatever is useful into #7697.
- **Experiments:** this branch. It adds instrumentation behind `APPLEPAY_EXPERIMENT` and `ApplePayExperimentUITests.swift`, which drives the Apple Pay sheet. Not for merging.

---

## 1. Background: how tax updates work while the sheet is open

When automatic tax uses the buyer's address, `CheckoutApplePayContext` updates the Checkout Session's tax region
(`checkout_client/<id>/update` with `tax_region[...]`) as the buyer picks things in the sheet. It then sends Apple the new summary items:

| Buyer action | Delegate callback | Address it gets | Can it change the sheet's totals? |
|---|---|---|---|
| Picks or edits a shipping address | `didSelectShippingContact` | Redacted shipping address | **Yes**, through the handler |
| Picks a card (billing-sourced tax) | `didSelectPaymentMethod` | Redacted billing address: city, state, ZIP, country. No street. | **Yes**, through the handler |
| Taps Pay | `didAuthorizePayment` | Full billing and shipping contacts | **No.** `PKPaymentAuthorizationResult` has no summary items |

Two more facts shape everything below:

- **Confirm sends `expectedAmount: checkoutSession.amount`** (`CheckoutApplePayContext.swift`, `didAuthorizePayment`), and the server rejects a mismatch with
  `checkout_expected_amount_does_not_match_amount_due`. The server compares against the client's session. It knows nothing about what the sheet showed.
  So if the client session changes after the sheet's totals were last updated, the server will accept a total the buyer never saw.
- **`STPAPIClient` only retries HTTP 429** ([`URLSession+Retry.swift:19`](https://github.com/stripe/stripe-ios/blob/master/StripeCore/StripeCore/Source/Helpers/URLSession%2BRetry.swift#L19)).
  A network blip or a 5xx fails the tax update on the first try.

## 2. What Apple Pay actually does

Apple's docs don't describe most of this, and in one case they're wrong. Everything here was seen in the simulator.

### Billing (`didSelectPaymentMethod` / `didAuthorizePayment`)

| What we return | What the buyer sees | Screenshot |
|---|---|---|
| Any error in `PKPaymentRequestPaymentMethodUpdate(errors:)` | **Ignored.** No error, Pay stays enabled. This contradicts [Apple's docs](https://developer.apple.com/documentation/passkit/pkpaymentrequestpaymentmethodupdate/init(errors:paymentsummaryitems:)) | [02](screenshots/02-pm-update-error-ignored.png) |
| ...and then the buyer pays the stale total | The server rejects it: "$120.00 does not match … $131.70" | [03](screenshots/03-pm-update-error-server-rejects-amount.png) |
| `.failure` with `paymentBillingAddressInvalidError` (what #7697 does) | The sheet stays open. The card turns red, and Pay becomes "Update Billing Address" | [01](screenshots/01-pr-auth-error-update-billing-address.png) |
| ...and the buyer opens the card | **Our `localizedDescription` is shown**, here the raw server message | [09](screenshots/09-card-details-shows-our-message.png) |
| ...and the buyer opens the billing editor | The ZIP is red and **Done stays disabled** until a field changes. Retyping the same ZIP doesn't enable it | [10](screenshots/10-billing-editor-done-disabled.png) |
| ...and the buyer re-selects the same card | **`didSelectPaymentMethod` is not called again** | [07](screenshots/07-reselect-same-card.png), [08](screenshots/08-still-stale-120-after-reselect.png) |
| `.failure` with `errors: nil` | **The sheet closes.** The app gets "Canceled" | [04](screenshots/04-failure-no-errors-dismisses.png) |
| `.failure` with a non-PassKit error (also what the confirm path does for non-ZIP errors) | **The sheet closes.** The app gets "Canceled" | [05](screenshots/05-failure-plain-error-dismisses.png) |
| `.failure` with `PKPaymentErrorDomain` / `.unknownError` | **The sheet stays open.** No field marked, and Pay can be tapped again | [06](screenshots/06-failure-unknown-error-stays-open.png) |

### Shipping (`didSelectShippingContact`)

| Error in `PKPaymentRequestShippingContactUpdate(errors:)` | What the buyer sees | Screenshot |
|---|---|---|
| `paymentShippingAddressUnserviceableError` | A system alert: **"<App> Doesn't Ship to Your Shipping Address"** | [11](screenshots/11-shipping-unserviceable-alert.png) |
| `PKPaymentErrorDomain` / `.unknownError` | **Ignored.** Pay stays enabled with the stale total | [12](screenshots/12-shipping-unknown-error-ignored.png) |
| `paymentContactInvalidError(.postalAddress)` | "Update Shipping Address", Pay blocked, no field marked | [13](screenshots/13-shipping-contact-error-blocks-pay.png) |
| ...and the buyer opens the address list | Our `localizedDescription` appears under the address | [14](screenshots/14-shipping-list-shows-message.png) |
| ...and the buyer re-saves the same address and taps Done | **`didSelectShippingContact` is called again**, unlike billing. The buyer can recover inside the sheet | [20](screenshots/20-fix-shipping-recovered-after-resave.png) |

### The server

I sent the update endpoint deliberately bad addresses. **None were rejected:**

| `tax_region` sent | Result |
|---|---|
| `postal_code=00000` | Succeeded, $0 tax |
| `country=ZZ` | Succeeded, $0 tax |
| `state=ZZ` | Succeeded, normal tax |

So a tax update that fails while the sheet is open is almost always a network, server or session problem, **not the buyer's address**.
(Address problems can still surface at confirm as `customer_tax_location_invalid`, per the comment in `CheckoutElementsUITests`.)

## 3. The problems

### Before #7697

1. **Failures were silently swallowed.** The sheet kept the pre-tax total. The buyer could tap Pay, and the server then rejected the stale amount, closing the sheet with an error.
   This was never a safety issue, because the server's expected-amount check holds, but the experience is bad.

### In #7697

2. **Every failure is blamed on the ZIP.** Billing and shipping both return `…AddressInvalidError(withKey: CNPostalAddressPostalCodeKey)`, even for a network error.
   Given the server findings above, that's misleading in nearly every real case.
3. **A transient billing failure is permanent.** `paymentMethodUpdateTask` keeps the failed `Task`, and a failed `Task.value` rethrows the same error forever.
   The task is only replaced in `didSelectPaymentMethod`, which Apple won't call again for the same card. The editor won't save an unchanged address either ([10](screenshots/10-billing-editor-done-disabled.png)).
   So the buyer's only ways out are to change their address, pick another card, or cancel.
4. **The raw server message is shown to buyers.** `error.nonGenericDescription` is the server's `message`, because Checkout sets `useServerErrorMessage`.
   It isn't localized by the client, and it appears in Apple's otherwise localized sheet ([09](screenshots/09-card-details-shows-our-message.png)).
5. **Two explanations in #7697 need correcting:**
   - The PR description says the billing address isn't available until authorization. It is available in `didSelectPaymentMethod`, redacted, and the PR's own code uses it.
     The real reason errors have to go at authorization is that Apple ignores errors from `didSelectPaymentMethod`.
   - The code comment "instead of letting the customer pay stale totals" overstates the risk, because the server already blocks that. The real benefit is UX.

### Why retrying only at authorization isn't enough

This is the obvious next fix, and I tried it.
At authorization the full billing address is available, so the retry works mechanically. But the sheet still shows the pre-tax $120, and a successful retry produces $131.70.
Apple can't show the new total after Pay is tapped, so the code has to choose:
- Confirm, which charges an amount the buyer never saw. The server won't catch this, because the client session now matches it.
- Fail, which leaves the buyer stuck again ([08](screenshots/08-still-stale-120-after-reselect.png)).

So the main recovery has to happen **before** Pay, in the callbacks that can still update the totals.

## 4. The fix

All of it lives in `CheckoutApplePayContext` ([`fix.diff`](fix.diff)).

1. **Retry transient failures in the callbacks that can still update totals.**
   `updateTaxRegion(to:using:)` retries network errors (`NSURLErrorDomain`) and `api_error` (5xx) responses twice, after 0.5s and then 1s.
   Both `didSelectPaymentMethod` and `didSelectShippingContact` use it, before calling their handler. The delay is short because Apple times the sheet out after about 30s.
2. **Only blame an address field when the API names one.** `invalidAddressKey(for:)` maps a `tax_region[country|line1|line2|city|state|postal_code]` `param` to the matching `CNPostalAddress*Key`.
   - **If the API named a field:** return `paymentShippingAddressInvalidError` / `paymentBillingAddressInvalidError` for that field, with the server message.
   - **Shipping, for any other failure:** return `paymentContactInvalidError(withContactField: .postalAddress, localizedDescription: stp_unexpectedErrorMessage())`.
     It's the only shipping error that blocks Pay without a misleading alert, and re-saving the address recovers ([13](screenshots/13-shipping-contact-error-blocks-pay.png), [14](screenshots/14-shipping-list-shows-message.png), [20](screenshots/20-fix-shipping-recovered-after-resave.png)).
3. **Billing at authorization, when the last update failed and the address isn't to blame:** `recoverFromFailedBillingTaxUpdate(_:payment:)` re-runs the update using `payment.billingContact`.
   - **Still failing:** return `.failure` with a `PKPaymentErrorDomain` / `.unknownError` error and the localized generic message. The sheet stays open with no field marked, and the next Pay tap retries ([16](screenshots/16-fix-persistent-failure-sheet-stays-open.png)).
   - **Succeeds with the same total**, for example when tax is $0: confirm.
   - **Succeeds with a different total:** set `paymentState = .error` and the result to `.failed(CheckoutError.totalChanged)`, then return `.failure` with no errors so Apple closes the sheet.
     The merchant gets a failure with the localized generic message. The session already has the new total, so the next Apple Pay attempt shows it and can succeed ([17](screenshots/17-fix-total-changed-closes-sheet.png) → [18](screenshots/18-fix-reopen-shows-new-total.png) → [19](screenshots/19-fix-second-attempt-paid.png)).

What the fix leaves alone:
- The server message is still shown when the API names an address field, since it explains that field.
- The confirm path's `pkPaymentError(forStripeError:)` still passes non-ZIP errors through as non-PassKit errors, so the sheet closes. That's existing behavior.

## 5. Verification

**Unit tests**: all 43 `CheckoutApplePayContextTests` pass. New tests cover:
- retrying billing and shipping after a single network failure;
- marking only the field the API named;
- the shipping error for failures the address didn't cause;
- authorization when the update keeps failing, when the retry keeps the total, and when the retry changes the total.

**Simulator, real backend, with network failures forced in the experiment build:**

| Scenario | Result |
|---|---|
| Billing update fails once | The in-sheet retry succeeds, the sheet shows $131.70, payment completes ([15](screenshots/15-fix-in-sheet-retry-shows-taxed-total.png)) |
| Billing update keeps failing | The sheet stays open after two Pay taps, with no field marked ([16](screenshots/16-fix-persistent-failure-sheet-stays-open.png)) |
| Billing fails in the sheet, then succeeds at authorization with a new total | The sheet closes with the generic error. Reopening shows $131.70, and payment completes ([17](screenshots/17-fix-total-changed-closes-sheet.png)–[19](screenshots/19-fix-second-attempt-paid.png)) |
| Shipping fails in the sheet | The address shows the generic message. Re-saving it re-runs the update, the sheet shows $130.35, and payment completes ([14](screenshots/14-shipping-list-shows-message.png), [20](screenshots/20-fix-shipping-recovered-after-resave.png)) |

## 6. Open questions

- **Real device.** Everything above is from one simulator runtime with simulated cards.
- **Should a total-changed retry close the sheet, or keep it open?** Closing means a second Apple Pay tap. Keeping it open strands the buyer, so I chose closing.
- **`CheckoutError.invalidShippingCountry`** is still passed to Apple as a non-PassKit error with an English message. `paymentShippingAddressUnserviceableError` is the right error for that case. Not touched here.
- **Does `checkout_client/update` ever return a `tax_region[...]` `param`?** I couldn't get one. If it never does, `invalidAddressKey(for:)` is just defensive.

## 7. stripe-android, for comparison

At [`1516eff`](https://github.com/stripe/stripe-android/tree/1516eff22098d2d13c4840b4d870688f10979583):

- **ECE Google Pay updates tax while the sheet is open**
  ([`CheckoutGooglePayPaymentDataUpdateCallback.kt:82-135`](https://github.com/stripe/stripe-android/blob/1516eff22098d2d13c4840b4d870688f10979583/paymentsheet/src/main/java/com/stripe/android/checkout/CheckoutGooglePayPaymentDataUpdateCallback.kt#L82-L135)):
  - **No stuck state.** Each callback sends a fresh request.
  - **Messages are localized** by the client (`stripeErrorMessage(context)`).
  - **Billing failures mark no field** (`OTHER_ERROR`). Shipping failures, including network errors, use `SHIPPING_ADDRESS_INVALID`.
- **Payment Element Google Pay doesn't update tax while the sheet is open.** With billing-sourced tax, the billing address is sent at confirm, after the sheet closes
  ([`CheckoutSessionConfirmationInterceptor.kt:94-125`](https://github.com/stripe/stripe-android/blob/1516eff22098d2d13c4840b4d870688f10979583/paymentsheet/src/main/java/com/stripe/android/paymentelement/confirmation/intent/CheckoutSessionConfirmationInterceptor.kt#L94-L125)).
  - If the total changed, confirm fails locally with `checkout_session_total_changed` and the generic message. That's intentional and tested
    ([`CheckoutPaymentElementAnalyticsTest.kt:202-246`](https://github.com/stripe/stripe-android/blob/1516eff22098d2d13c4840b4d870688f10979583/paymentsheet/src/androidTest/java/com/stripe/android/checkout/CheckoutPaymentElementAnalyticsTest.kt#L202-L246)).
  - This is the same "close and try again" approach as iOS fix step 3.
- **Unverified lead from a code read:** the ECE in-sheet update may not write the new session back to the controller state, so confirm could send a stale `expected_amount`.

## Reproducing

1. Check out this branch and set `APPLEPAY_EXPERIMENT` in the `ApplePayExperimentUITests` launch environment.
   Variants: `baseline`, `pmupdate_billing`, `pmupdate_unknown`, `retry`, `retry_unknown`, `retry_plain`, `realbad_zip`, `realbad_state`, `realbad_country`.
2. Run, for example: `ci_scripts/run_tests.rb --ui --test PaymentSheetUITest/ApplePayExperimentUITests/testExperimentBaseline`
3. Screenshots and element trees go to `/tmp/apexp-out/<variant>/`. The delegate log (`APEXP …`) is in the simulator log, and [`delegate-log.txt`](delegate-log.txt) has the original runs.

# Checkout Elements Connect validation results (iOS)

November 10, 2026. Scope: sections 1–3 of the Mobile Checkout Sessions Connect work list (direct charges, destination charges, and separate charges and transfers (SC&T), all without `on_behalf_of`), on iOS only. `on_behalf_of` (section 4) was not tested.

## Summary

Sections 1–3 work on iOS without Connect-specific SDK changes. All 16 end-to-end payments completed through the SDK, and their PaymentIntents, Charges, application fees, and Transfers matched expectations. All 5 stubbed credential tests pass. Discount, tax, and Adaptive Pricing effects on fees and transfers were not tested.

## Method

- **End to end:** Sessions were created in test mode on platform `acct_1HvTI7Lu5o3P18Zp`. Direct charges were created on connected account `acct_1SGPAfLpAeuIWWTH` with a `Stripe-Account` header. Each Session was paid in `CheckoutConnectUITests` through the Checkout Playground on an iPhone 12 mini iOS 18.5 simulator, using real 3DS2 challenges, simulator Apple Pay, and native Link. `connect_e2e.py verify` then retrieved and checked the resulting objects.
- **Stubbed:** `CheckoutConnectStubbedTests` records every request the SDK sends. It checks `Stripe-Account` for direct charges, and checks that platform-owned Sessions send neither `Stripe-Account` nor Connect parameters. A deliberate break (setting the account after `/init`) made 4 of the tests fail, so the assertions work.

## Results

| § | Case | Payment method | Observed | Result |
|---|---|---|---|---|
| **1 Direct** | Basic | New card 4242 | PI `pi_3UaO7dLpAeuIWWTH…` on the connected account; no fee or `transfer_data` | ✅ |
| 1 | Application fee + 3DS | 3DS2 card 3184 | `application_fee_amount=123`, application fee object 123, 3DS `authenticated` (2.1.0) | ✅ |
| 1 | Cancel 3DS, then retry | 3DS2 card 3184 | Cancel returned `.canceled` with the Session still open; the retry authenticated and succeeded | ✅ |
| 1 | Saved card | Saved card on the connected account's Customer | Confirmed with saved PM `pm_1UaNzpLpAeuIWWTH…` | ✅ |
| 1 | Apple Pay | Simulator Apple Pay | Wallet `apple_pay`; PI on the connected account | ✅ |
| 1 | Link wallet | Express Checkout Element → Link signup → card | PI `pi_3UaOReLpAeuIWWTH…`, PM `card` with wallet `link` | ✅ |
| 1 | Link inline signup | Payment Element card form with Link signup | PI `pi_3UaOR2LpAeuIWWTH…`, wallet `link` | ✅ |
| 1 | `Stripe-Account` on every request | Stubbed | init, update, confirm, PI retrieve, poll, retrieve, and `/v1/tokens` all carry the connected account | ✅ |
| **2 Destination** | Flat fee | New card 4242 | `transfer_data.destination=acct_1SGPAf…`, fee 123, Transfer `tr_3UaO6e…` for 1000 | ✅ |
| 2 | Fixed transfer amount + 3DS | 3DS2 card 3184 | `transfer_data.amount=800`, no fee, Transfer `tr_3UaO76…` for 800, 3DS `authenticated` | ✅ |
| 2 | Percentage fee | Saved card on the platform's Customer | Fee 100 (10% of 1000); Transfer for 1000 | ✅ |
| 2 | Apple Pay | Simulator Apple Pay | Wallet `apple_pay`, fee 123, Transfer `tr_3UaO0Y…` | ✅ |
| 2 | Link wallet, cancel 3DS then retry | Link with 3DS2 card 3184 | Wallet `link`, 3DS `authenticated`, fee 123, Transfer `tr_3UaOHC…` | ✅ |
| 2 | Link inline signup | Payment Element card form with Link signup | Wallet `link`, fee 123, Transfer `tr_3UaOGa…` | ✅ |
| 2 | Totals changed by discounts | — | Not testable. Session creation returns `You can not pass discounts in modeless mode`, and the SDK's CheckoutClient `/update` does not support promotion codes yet | ⛔ |
| 2 | Totals changed by tax | — | Not tested. The platform has no tax registrations, so tax would be $0 | ⛔ |
| 2 | Adaptive Pricing | — | Not tested | ⛔ |
| **3 SC&T** | Basic | New card 4242 | PI and Charge `transfer_group=ORDER_b3d63f71`, no destination or fee; merchant Transfer `tr_3UaO8b…` with `source_transaction=ch_3UaO8b…` | ✅ |
| 3 | 3DS | 3DS2 card 3184 | Same checks, plus 3DS `authenticated`; Transfer `tr_3UaO85…` | ✅ |
| 3 | Link wallet | Express Checkout Element → Link signup → card | `transfer_group=ORDER_c5971b57` on PI and Charge, wallet `link`; Transfer `tr_3UaOI3…` | ✅ |
| 2, 3 | No connected account or Connect fields | Stubbed, new and saved card | No `Stripe-Account`; no `on_behalf_of`, `transfer_data`, `transfer_group`, or `application_fee` in `/confirm` | ✅ |

## SDK findings

- **All Checkout requests use one client.** Every CheckoutClient call, the payment handler, the Payment Element configuration, and Apple Pay tokenization use the merchant-supplied `CheckoutElementsController.Configuration.apiClient`. `STPAPIClient` adds `Stripe-Account` from `stripeAccount` to every request.
- **Link keeps `Stripe-Account` in Checkout.** The SDK removes `Stripe-Account` only from requests authenticated with the Link consumer's own publishable key. That is deliberate: a merchant account header would make those requests fail. The only call that does this is `updateConsentStatus`, which only the standalone `LinkController` uses. Checkout's Link requests, including `consumers/payment_details/share`, use the merchant's client and keep the header.
- **Card BIN lookups always use `STPAPIClient.shared`.** This is existing behavior (MOBILESDK-4322) and doesn't matter here, because BIN metadata isn't tied to an account.

## Backend and access findings

- **Unified-mode Connect fields need `checkout_unified_mode_preview` on the platform.** Without it, `payment_settings` is rejected as an unknown parameter. Before gating, all 9 playground merchants rejected it.
- **Direct charges also need gates on the platform's Connect client application.** A request sent with `Stripe-Account` is gated on the platform's **Connect Client Application** (test and live are separate), not on the platform merchant or the connected account. The client application needs `enable_checkout_mobile_elements_ui_mode` and `checkout_item_one_time_price`. Before the second gate was added there, direct-charge Session creation failed with `Received unknown parameter: items[0][type]`. The connected account itself needed no gates. See [Connect Requests, Gates and Flags](https://trailhead.corp.stripe.com/docs/terminal/connect-requests-gates-and-flags).
- **Link on direct charges follows the connected account's payment method configuration.** Link was off in `pmc_1SGPBCLpAeuIWWTHmI3MCEZY`, the configuration the platform's Connect application manages for this account (inherited from platform config `pmc_1NnDQg…`). It was turned on in test mode with `POST /v1/payment_method_configurations/pmc_1SGPBCLpAeuIWWTHmI3MCEZY` and `link[display_preference][preference]=on`. After that, CheckoutClient `/init` returned `link_mode: "LINK_CARD_BRAND"`. Other connected accounts still inherit the platform's off setting.
- **Field names:** the application fee field is `payment_settings.application_fee_data.initial_amount` (or `percentage_decimal`). The fixed transfer amount is `payment_settings.transfer_data.transfer_amount.initial_amount`.
- **Session creation rejects `return_url` for `ui_mode: mobile_elements`.** The SDK sends it on `/confirm` instead.
- **CheckoutClient returns a native 3DS2 next action (`use_stripe_sdk`)** for both platform and connected-account Sessions.

## Corrections to the work list

- **Access requirements:** add that direct charges need `enable_checkout_mobile_elements_ui_mode` and `checkout_item_one_time_price` on the platform's Connect client application (test and/or live), in addition to the merchant gates.
- **Rejection order:** `ui_mode=mobile_elements` does reject legacy `payment_intent_data` Connect fields. With an invalid destination, `payment_intent_data.transfer_data` fails with `No such destination` first, because the destination is checked before the mobile restriction.

## Not covered

- Fee and transfer amounts when discounts or tax change the total, and Adaptive Pricing.
- `on_behalf_of` (section 4) and Android.
- Live mode. The live Connect client application has separate gates.

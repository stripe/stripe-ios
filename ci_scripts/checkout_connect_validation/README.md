# Checkout Elements Connect validation

Manual end-to-end validation of Checkout Elements with Connect: direct charges, destination charges, and separate charges and transfers (SC&T). Not run in CI.

## Accounts

- Platform: `acct_1HvTI7Lu5o3P18Zp` (playground `US` merchant). Gated into `checkout_unified_mode_preview`. Its **Test Connect Client Application** is gated into `enable_checkout_mobile_elements_ui_mode` and `checkout_item_one_time_price`, which direct charges need.
- Connected account: `acct_1SGPAfLpAeuIWWTH` (US, platform-controlled, `card_payments` and `transfers` active). Link is turned on in its platform-managed payment method configuration, `pmc_1SGPBCLpAeuIWWTHmI3MCEZY`.

## Run

```bash
export STRIPE_TEST_SECRET_KEY=sk_test_...       # platform test key, see sandbox-apps stripe-mobile-playground-backend/server-keys.js
export STRIPE_TEST_PUBLISHABLE_KEY=pk_test_...  # platform test publishable key
mkdir -p /tmp/connect-validation

# 1. Create Sessions. Each Session can be paid once, so recreate them before each run.
#    Pass case names after `create` to create only those cases.
python3 -I ci_scripts/checkout_connect_validation/connect_e2e.py create > /tmp/connect-validation/cases.json

# 2. Pay for each Session through Checkout Elements in the Checkout Playground.
ci_scripts/run_tests.rb --ui --test PaymentSheetUITest/CheckoutConnectUITests

# 3. Verify the resulting PaymentIntents, Charges, application fees, and Transfers.
python3 -I ci_scripts/checkout_connect_validation/connect_e2e.py verify /tmp/connect-validation/cases.json
```

`CheckoutConnectUITests` opens each pre-created Session through the playground's `STP_CHECKOUT_CLIENT_SECRET`, `STP_CHECKOUT_PUBLISHABLE_KEY`, and `STP_CHECKOUT_STRIPE_ACCOUNT` launch environment.

`CheckoutConnectStubbedTests` covers the SDK side without a network: which requests carry `Stripe-Account`, and that `/confirm` sends no Connect parameters.

## Files

- `connect_e2e.py`: creates the case Sessions and verifies the results.
- `direct.py`: small Stripe API helper; also `accounts`, `create`, and `get` commands for probing.
- `link_probe.py`: prints CheckoutClient `/init` Link settings for a platform Session and a connected-account Session.

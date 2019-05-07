# Standard Integration (Sources Only)

**Note** STPPaymentContext is not currently the recommended integration with StripeiOS because it only supports Sources. See Custom Integration (Recommended) for examples of how to use payment methods and sources when needed.

This example app demonstrates how to build a payment flow using our pre-built UI components (`STPPaymentContext`).

For a detailed guide, see https://stripe.com/docs/mobile/ios/standard

1. If you haven't already, sign up for a [Stripe account](https://dashboard.stripe.com/register) (it takes seconds). Then go to https://dashboard.stripe.com/account/apikeys.
2. Execute `./setup.sh` from the root of the repository to build the necessary dependencies
3. Open `./Stripe.xcworkspace` (not `./Stripe.xcodeproj`) with Xcode
4. Fill in the `stripePublishableKey` constant in `./Example/Standard Integration (Swift)/CheckoutViewController.swift` with your test "Publishable key" from Stripe. This key should start with `pk_test`.
5. Head to [example-ios-backend](https://github.com/stripe/example-ios-backend/tree/v15.0.1) and click "Deploy to Heroku". Provide your Stripe test "Secret key" as the `STRIPE_TEST_SECRET_KEY` environment variable. This key should start with `pk_test`.
6. Fill in the `backendBaseURL` constant in `./Example/Standard Integration (Swift)/CheckoutViewController.swift` with the app URL Heroku provides (e.g. "https://my-example-app.herokuapp.com")

After this is done, you can make test payments through the app and see them in your Stripe dashboard.

Head to https://stripe.com/docs/testing#cards for a list of test card numbers.

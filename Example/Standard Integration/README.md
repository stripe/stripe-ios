# Standard Integration

This example app demonstrates how to build a payment flow using our pre-built UI component integration (`STPPaymentContext`).

For a detailed guide, see https://stripe.com/docs/mobile/ios/standard

1. If you haven't already, sign up for a [Stripe account](https://dashboard.stripe.com/register) (it takes seconds).
2. Open `./Stripe.xcworkspace` (not `./Stripe.xcodeproj`) with Xcode
3. Fill in the `stripePublishableKey` constant in `./Example/Standard Integration/CheckoutViewController.swift` with your Stripe [test "Publishable key"](https://dashboard.stripe.com/account/apikeys.). This key should start with `pk_test`.
4. Head to [example-ios-backend](https://github.com/stripe/example-ios-backend/tree/v17.0.0) and click "Deploy to Heroku". Provide your [Stripe test "Secret key"](https://dashboard.stripe.com/account/apikeys.) as the `STRIPE_TEST_SECRET_KEY` environment variable. This key should start with `sk_test`.
5. Fill in the `backendBaseURL` constant in `./Example/Standard Integration/CheckoutViewController.swift` with the app URL Heroku provides (e.g. "https://my-example-app.herokuapp.com")

After this is done, you can make test payments through the app and see them in your [Stripe dashboard](https://dashboard.stripe.com/test/payments).  

Head to https://stripe.com/docs/testing#cards for a list of test card numbers.

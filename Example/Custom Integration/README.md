# Custom Integration

This example app demonstrates how to to use `STPAPIClient` to accept various payment methods. This may be a useful reference if you're building your own payment UI and not using `STPPaymentContext`.

For a detailed guide, see https://stripe.com/docs/mobile/ios/custom

For more details on using Sources, see https://stripe.com/docs/mobile/ios/sources

1. If you haven't already, sign up for a [Stripe account](https://dashboard.stripe.com/register) (it takes seconds). Then go to https://dashboard.stripe.com/account/apikeys.
2. Open `./Stripe.xcworkspace` (not `./Stripe.xcodeproj`) with Xcode
3. Fill in the `stripePublishableKey` constant in `./Example/Custom Integration/Constants.m` with your test "Publishable key" from Stripe. This key should start with `pk_test`.
4. Head to [example-ios-backend](https://github.com/stripe/example-ios-backend/tree/v16.0.0) and click "Deploy to Heroku". Provide your Stripe test "Secret key" as the `STRIPE_TEST_SECRET_KEY` environment variable. This key should start with `sk_test`.
5. Fill in the `backendBaseURL` constant in `Constants.m` with the app URL Heroku provides (e.g. "https://my-example-app.herokuapp.com")

After this is done, you can make test payments through the app and see them in your Stripe dashboard.

Head to https://stripe.com/docs/testing#cards for a list of test card numbers.

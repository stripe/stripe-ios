# Basic Integration

<p align="center">
<img src="https://raw.githubusercontent.com/stripe/stripe-ios/11d293baa9b753234816367a5bbdc4ac5ad04af6/standard-integration.gif" width="240" alt="Basic Integration Example App" align="center">
</p>

This example app demonstrates how to build a payment flow using our pre-built UI component integration (`STPPaymentContext`).

For a detailed guide, see https://stripe.com/docs/mobile/ios/basic

## To run the example app:

1. If you haven't already, sign up for a [Stripe account](https://dashboard.stripe.com/register) (it takes seconds).
2. Open `stripe-ios/Stripe.xcworkspace` (not `stripe-ios/Stripe.xcodeproj`) with Xcode
3. Fill in the `stripePublishableKey` constant in `stripe-ios/Example/Basic Integration/Basic Integration/CheckoutViewController.swift` with your Stripe [test "Publishable key"](https://dashboard.stripe.com/account/apikeys.). This key should start with `pk_test`.
4. Head to [example-mobile-backend](https://github.com/stripe/example-mobile-backend/tree/v18.1.0) and click "Deploy to Heroku". Provide your [Stripe test "Secret key"](https://dashboard.stripe.com/account/apikeys.) as the `STRIPE_TEST_SECRET_KEY` environment variable. This key should start with `sk_test`.
5. Fill in the `backendBaseURL` constant in `./Example/Basic Integration/Basic Integration/CheckoutViewController.swift` with the app URL Heroku provides (e.g. "https://my-example-app.herokuapp.com")

After this is done, you can make test payments through the app and see them in your [Stripe dashboard](https://dashboard.stripe.com/test/payments).  

Head to https://stripe.com/docs/testing#cards for a list of test card numbers.

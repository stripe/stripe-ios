# Stripe iOS Bindings

[![Build Status](https://travis-ci.org/stripe/stripe-ios.svg?branch=master)](https://travis-ci.org/stripe/stripe-ios)

The Stripe iOS bindings make it easy to collect your users' credit card details inside your iOS app. By creating [tokens](https://stripe.com/docs/api#tokens), Stripe handles the bulk of PCI compliance by preventing sensitive card data from hitting your server (for more, see [our article about PCI compliance](https://support.stripe.com/questions/do-i-need-to-be-pci-compliant-what-do-i-have-to-do)).

We also offer [seamless integration](https://stripe.com/applepay) with Apple's new [Apple Pay](https://apple.com/apple-pay) service that will allow you to securely collect payments from your customers in a way that prevents them from having to re-enter their credit card information.

## Integration

We've written a [guide](https://stripe.com/docs/mobile/ios) that explains everything from installation, to creating payment tokens, to Apple Pay integration and more.

## Example app

The example app is a great way to see the flow of recording credit card details, converting them to a token with the Stripe iOS bindings, and then using that token to charge users on your backend. It uses [PaymentKit](https://github.com/stripe/PaymentKit) to create a simple credit card form, and a small backend hosted with Parse Cloud Code to process the actual transactions. It also uses our [ApplePayStubs](https://github.com/stripe/ApplePayStubs) library to demonstrate how the Apple Pay flow works in the iOS simulator (normally Apple Pay requires a device to use).

### Running the example

Note: the example app requires Xcode 6 to build and run.

Before you can run the app, you need to provide it with your own Stripe and Parse API keys.

#### Stripe
1. If you haven't already, sign up for a [Stripe account](https://dashboard.stripe.com/register) (it takes seconds). Then go to https://dashboard.stripe.com/account/apikeys.
2. Replace the `StripePublishableKey` constant in Example/StripeExample/Constants.m with your Test Publishable Key.
3. Replace the `stripe_secret_key` variable in Example/Parse/cloud/main.js with your Test Secret Key.

#### Parse
1. Sign up for a [Parse account](https://parse.com/#signup), then create a new Parse app.
2. Head to the "Application keys" section of your parse app's settings page. Replace the `ParseApplicationId` and `ParseClientKey` constants in Example/StripeExample/Constants.m with your app's Application ID and Client Key, respectively.
3. Replace the appropriate values in Example/Parse/config/global.json with your Parse app's name, Application ID, and Master Secret. IMPORTANT: these values, along with your Stripe Secret Key, can be used to control your Stripe and Parse accounts. Thus, once you edit these files, you shoudn't check them back into git.
4. Install the Parse command line tool at https://www.parse.com/docs/cloud_code_guide#started, then run `parse deploy` from the Example/Parse directory.

After this is done, you can make test payments through the app (use credit card number 4242 4242 4242 4242, along with any cvc and any future expiration date) and then view them in your Stripe Dashboard!

## Running the tests

1. Open Stripe.xcodeproj
1. Select either the iOS or OS X scheme in the toolbar at the top
1. Go to Product->Test

## Misc. notes

### Handling errors

See [StripeError.h](https://github.com/stripe/stripe-ios/blob/master/Stripe/StripeError.h).

### Operation queues

API calls are run on `[NSOperationQueue mainQueue]` by default, but all methods have counterparts that can take a custom operation queue.

### Validating STPCards

You have a few options for handling validation of credit card data on the client, depending on what your application does.  Client-side validation of credit card data is not required since our API will correctly reject invalid card information, but can be useful to validate information as soon as a user enters it, or simply to save a network request.

The simplest thing you can do is to populate an `STPCard` object and, before sending the request, call `- (BOOL)validateCardReturningError:` on the card.  This validates the entire card object, but is not useful for validating card properties one at a time.

To validate `STPCard` properties individually, you should use the following:

     - (BOOL)validateNumber:error:
     - (BOOL)validateCvc:error:
     - (BOOL)validateExpMonth:error:
     - (BOOL)validateExpYear:error:

These methods follow the validation method convention used by [key-value validation](http://developer.apple.com/library/mac/#documentation/cocoa/conceptual/KeyValueCoding/Articles/Validation.html).  So, you can use these methods by invoking them directly, or by calling `[card validateValue:forKey:error]` for a property on the `STPCard` object.

When using these validation methods, you will want to set the property on your card object when a property does validate before validating the next property.  This allows the methods to use existing properties on the card correctly to validate a new property.  For example, validating `5` for the `expMonth` property will return YES if no `expYear` is set.  But if `expYear` is set and you try to set `expMonth` to 5 and the combination of `expMonth` and `expYear` is in the past, `5` will not validate.  The order in which you call the validate methods does not matter for this though.

## Migrating from versions < 1.2

Versions of Stripe-iOS prior to 1.2 included a class called `STPView`, which provided a pre-built credit card form. This functionality has been moved from Stripe-iOS to PaymentKit, a separate project. If you were using `STPView` prior to version 1.2, migrating is simple:

1. Add PaymentKit to your project, as explained on its [project page](https://github.com/stripe/PaymentKit).
2. Replace any references to `STPView` with a `PTKView` instead. Similarly, any classes that implement `STPViewDelegate` should now instead implement the equivalent `PTKViewDelegate` methods. Note that unlike `STPView`, `PTKView` does not take a Stripe API key in its constructor.
3. To submit the credit card details from your `PTKView` instance, where you would previously call `createToken` on your `STPView`, replace that with the following code (assuming `self.paymentView` is your `PTKView` instance):

        if (![self.paymentView isValid]) {
            return;
        }
        STPCard *card = [[STPCard alloc] init];
        card.number = self.paymentView.card.number;
        card.expMonth = self.paymentView.card.expMonth;
        card.expYear = self.paymentView.card.expYear;
        card.cvc = self.paymentView.card.cvc;
        [Stripe createTokenWithCard:card completion:^(STPToken *token, NSError *error) {
            if (error) {
                // handle the error as you did previously
            } else {
                // submit the token to your payment backend as you did previously
            }
        }];

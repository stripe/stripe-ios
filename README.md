# Stripe iOS SDK

[![Travis](https://img.shields.io/travis/stripe/stripe-ios.svg?style=flat)](https://travis-ci.org/stripe/stripe-ios)
[![CocoaPods](https://img.shields.io/cocoapods/v/Stripe.svg?style=flat)](http://cocoapods.org/?q=author%3Astripe%20name%3Astripe)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods](https://img.shields.io/cocoapods/l/Stripe.svg?style=flat)](https://github.com/stripe/stripe-ios/blob/master/LICENSE)
[![CocoaPods](https://img.shields.io/cocoapods/p/Stripe.svg?style=flat)](https://github.com/stripe/stripe-ios#)

The Stripe iOS SDK make it easy to collect your users' credit card details inside your iOS app. By creating [tokens](https://stripe.com/docs/api#tokens), Stripe handles the bulk of PCI compliance by preventing sensitive card data from hitting your server (for more, see [our article about PCI compliance](https://support.stripe.com/questions/do-i-need-to-be-pci-compliant-what-do-i-have-to-do)).

We also offer [seamless integration](https://stripe.com/applepay) with [Apple Pay](https://apple.com/apple-pay) that will allow you to securely collect payments from your customers in a way that prevents them from having to re-enter their credit card information.

## Requirements
Our SDK is compatible with iOS apps supporting iOS6 and above. It requires Xcode 6.3+ and the iOS8 SDK to build the source.

## Integration

We've written a [guide](https://stripe.com/docs/mobile/ios) that explains everything from installation, to creating payment tokens, to Apple Pay integration and more.

## Example apps

There are 3 example apps included in the repository:
- Stripe iOS Example (Simple) shows how to use STPPaymentPresenter to really easily obtain your user's payment information with Apple Pay. When Apple Pay isn't available on the device, it'll use Stripe Checkout instead. It uses a small backend to create a charge. The app is written in Swift.
- Stripe iOS Example (Custom) demonstrates 3 different ways of collecting your user's payment details: via Apple Pay, via Stripe Checkout, and via your own credit card form. It also uses our [ApplePayStubs](https://github.com/stripe/ApplePayStubs) library to demonstrate how the Apple Pay flow appears in the iOS simulator (normally Apple Pay requires a device to use). It, too, uses a small example backend to make charges.
- Stripe OSX Example demonstrates how to use Stripe Checkout inside a native Mac app.

### Getting started with the Simple iOS Example App

Note: all the example apps require Xcode 6.1 to build and run.

Before you can run the app, you need to provide it with your Stripe publishable key.

1. If you haven't already, sign up for a [Stripe account](https://dashboard.stripe.com/register) (it takes seconds). Then go to https://dashboard.stripe.com/account/apikeys.
2. Replace the `stripePublishableKey` constant in ViewController.swift (for the Simple app) or Constants.m (for the Custom app) with your Test Publishable Key.
3. Head to https://github.com/stripe/example-ios-backend and click "Deploy to Heroku" (you may have to sign up for a Heroku account as part of this process). Provide your Stripe test secret key for the STRIPE_TEST_SECRET_KEY field under 'Env'. Click "Deploy for Free".
4. Replace the `backendChargeURLString` variable in the example iOS app with the app URL Heroku provides you with (e.g. "https://my-example-app.herokuapp.com")

After this is done, you can make test payments through the app (use credit card number 4242 4242 4242 4242, along with any cvc and any future expiration date) and then view them in your Stripe Dashboard!

## Running the tests

1. Open Stripe.xcworkspace
1. Choose the "iOS Tests" or "OSX Tests" scheme
1. Run Product -> Test

## Migration Guides

### Migrating from versions < 3.0

Before version 3.0, most token-creation methods were class methods on the `Stripe` class. These are now all instance methods on the `STPAPIClient` class. Where previously you might write
```objective-c
[Stripe createTokenWithCard:card publishableKey:myPublishableKey completion:completion];
```
you would now instead write
```objective-c
STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:myPublishableKey];
[client createTokenWithCard:card completion:completion];
```
This version also made several helper classes, including `STPAPIConnection` and `STPUtils`, private. You should remove any references to them from your code (most apps shouldn't have any).

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
        STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:publishableKey];
        [client createTokenWithCard:card completion:^(STPToken *token, NSError *error) {
            if (error) {
                // handle the error as you did previously
            } else {
                // submit the token to your payment backend as you did previously
            }
        }];

## Misc. notes

### Handling errors

See [StripeError.h](https://github.com/stripe/stripe-ios/blob/master/Stripe/PublicHeaders/StripeError.h) for a list of error codes that may be returned from the Stripe API.

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


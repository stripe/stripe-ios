## Migration Guides

### Migrating from versions < 9.0

Version 9.0 drops support for iOS 7.x and Xcode 7.x. If you need to support iOS or Xcode versions below 8.0, the last compatible Stripe SDK release is version 8.0.7.

### Migrating from versions < 6.0

6.0 moves most of the contents of `STPCard` into a new class, `STPCardParams`, which represents a request to the Stripe API. `STPCard` now only refers to responses from the Stripe API. Most apps should be able to simply replace all usage of `STPCard` with `STPCardParams` - you should only use `STPCard` if you're dealing with an API response, e.g. a card attached to an `STPToken`. This renaming has been done in a way that will avoid breaking changes, although using `STPCard`s to make requests to the Stripe API will produce deprecation warnings.

### Migrating from versions < 5.0

5.0 deprecates our native Stripe Checkout adapters. If you were using these, we recommend building your own credit card form instead. If you need help with this, please contact support@stripe.com.

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

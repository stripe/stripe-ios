## Migration Guides

### Migrating from versions < 17.0.0
* The API version has been updated from 2015-10-12 to 2019-05-16. CHANGELOG.md has details on the changes made, which includes breaking changes for `STPConnectAccountParams` users. Your backend Stripe API version should be sufficiently decoupled from the SDK's so that keeping their versions in sync is not required, and no further action is required to migrate to this version of the SDK.
* For STPPaymentContext users: the completion block type in `paymentContext:didCreatePaymentResult:completion:` has changed to `STPPaymentStatusBlock`, to let you inform the context that the user has cancelled. 

### Migrating from versions < 16.0.0
* The following have been migrated from Source/Token to PaymentMethod. If you have integrated with any of these things, you must also migrate to PaymentMethod and the Payment Intent API.  See https://stripe.com/docs/payments/payment-methods#transitioning.  See CHANGELOG.md for more details.
  * UI components
    * STPPaymentCardTextField
    * STPAddCardViewController
    * STPPaymentOptionViewController
  * PaymentContext
    * STPPaymentContext
    * STPCustomerContext
    * STPBackendAPIAdapter
    * STPPaymentResult
  * Standard Integration example project
* `STPPaymentIntentAction*` types have been renamed to `STPIntentAction*`. Xcode should offer a deprecation warning & fix-it to help you migrate.
* `STPPaymentHandler` supports 3DS2 authentication, and is recommended instead of `STPRedirectContext`. See https://stripe.com/docs/mobile/ios/authentication

### Migrating from versions < 15.0.0
* "PaymentMethod" has a new meaning: https://stripe.com/docs/api/payment_methods/object.  All things referring to "PaymentMethod" have been renamed to "PaymentOption" (see CHANGELOG.md for the full list).  `STPPaymentMethod` and `STPPaymentMethodType` have been rewritten to match this new API object.
* PaymentMethod succeeds Source as the recommended way to charge customers.  In this vein, several 'Source'-named things have been deprecated, and replaced with 'PaymentMethod' equivalents.  For example, `STPPaymentIntentsStatusRequiresSource` is replaced by `STPPaymentIntentsStatusRequiresPaymentMethod` (see CHANGELOG.md for the full list).  Following the deprecation warnings & fix-its will be enough to migrate your code - they've simply been renamed, and will continue to work for Source-based flows.

### Migrating from versions < 14.0.0
* `STPPaymentCardTextField` now copies the `STPCardParams` object when setting/getting the `cardParams` property, instead of sharing the object with the caller.
  * Changes to the `STPCardParams` object after setting `cardParams` no longer mutate the object held by the `STPPaymentCardTextField`
  * Changes to the object returned by `STPPaymentCardTextField.cardParams` no longer mutate the object held by the `STPPaymentCardTextField`
  * This is a breaking change for code like: `paymentCardTextField.cardParams.name = @"Jane Doe";`
* `STPPaymentIntentParams.returnUrl` has been renamed to `STPPaymentIntentParams.returnURL`. Xcode should offer a deprecation warning & fix-it to help you migrate.
* `STPPaymentIntent.returnUrl` has been removed, because it's no longer a property of the PaymentIntent. When the PaymentIntent status is `.requiresSourceAction`, and the `nextSourceAction.type` is `.authorizeWithURL`, you can find the return URL at `nextSourceAction.authorizeWithURL.returnURL`.

### Migrating from versions < 13.1.0
 * The SDK now supports PaymentIntents with `STPPaymentIntent`, which use `STPRedirectContext` in the same way that `STPSource` does
   * `STPRedirectContextCompletionBlock` has been renamed to `STPRedirectContextSourceCompletionBlock`. It has the same signature, and Xcode should offer a deprecation warning & fix-it to help you migrate.

### Migrating from versions < 13.0.0
* Remove Bitcoin source support because Stripe no longer processes Bitcoin payments: https://stripe.com/blog/ending-bitcoin-support
  * Sources can no longer have a "STPSourceTypeBitcoin" source type. These sources will now be interpreted as "STPSourceTypeUnknown".
  * You can no longer `createBitcoinParams`. Please use a different payment method.

### Migrating from versions < 12.0.0
* The SDK now requires iOS 9+ and Xcode version 9+. If you need to support iOS 8 or Xcode 8, the last supported version is [11.5.0](https://github.com/stripe/stripe-ios/releases/tag/v11.5.0)
* `STPPaymentConfiguration.requiredShippingAddress` now is a set of `STPContactField` objects instead of a `PKAddressField` bitmask.
  * Most of the previous `PKAddressField` constants have matching `STPContactField` constants. To convert your code, switch to passing in a set of the matching constants
    * Example: `(PKAddressField)(PKAddressFieldName|PKAddressFieldPostalAddress)` becomes `[NSSet setwithArray:@[STPContactFieldName, STPContactFieldPostalAddress]]`)
  * Anywhere you were using `PKAddressFieldNone` you can now simply pass in `nil`
  * If you were using `PKAddressFieldAll`, you must switch to manually listing all the fields that you want.
  * The new constants also correspond to and work similarly to Apple's new `PKContactField` values.
* `AddressBook` framework support has been removed. If you were using AddressBook related functionality, you must switch over to using the `Contacts` framework.
* `STPRedirectContext` will no longer retain itself for the duration of the redirect. If you were relying on this functionality, you must change your code to explicitly maintain a reference to it.

### Migrating from versions < 11.4.0
* The `STPBackendAPIAdapter` protocol and all associated methods are no longer deprecated. We still recommend using `STPCustomerContext` to update a Stripe customer object on your behalf, rather than using your own implementation of `STPBackendAPIAdapter`.

### Migrating from versions < 11.3.0
* Changes to  `STPCard`, `STPCardParams`, `STPBankAccount`, and `STPBankAccountParams`
  * `STPCard` no longer subclasses from `STPCardParams`. You must now specifically create `STPCardParams` objects to create new tokens.
  * `STPBankAccount` no longer subclasses from `STPBankAccountParams`.
  * You can no longer directly create `STPCard` objects, you should only use ones that have been decoded from Stripe API responses via `STPAPIClient`.
  * All `STPCard` and `STPBankAccount` properties have been made readonly.
  * Broken out individual address properties on `STPCard` and `STPCardParams` have been deprecated in favor of the grouped `address` property.
* The value of `[STPAPIResponseDecodable allResponseFields]` is now completely (deeply) filtered to not contain any instances of `[NSNull null]`. Previously, only `[NSNull null]` one level deep (shallow) were removed.

### Migrating from versions < 11.2.0
* `STPCustomer`'s `shippingAddress` property is now correctly annotated as nullable. Its type is an optional (`STPAddress?`) in Swift.

### Migrating from versions < 11.0.0
- We've greatly simplified the integration for `STPPaymentContext`. In order to migrate to the new `STPPaymentContext` integration using ephemeral keys, you'll need to:
  1. On your backend, add a new endpoint that creates an ephemeral key for the Stripe customer associated with your user, and returns its raw JSON. Note that you should _not_ remove the 3 endpoints you added for your initial PaymentContext integration until you're ready to drop support for previous versions of your app.
  2. In your app, make your API client class conform to `STPEphemeralKeyProvider` by adding a method that requests an ephemeral key from the endpoint you added in (1).
  3. In your app, remove any references to `STPBackendAPIAdapter`. Your API client class will no longer need to conform to `STPBackendAPIAdapter`, and you can delete the `retrieveCustomer`, `attachSourceToCustomer`, and `selectDefaultCustomerSource` methods.
  4. Instead of using the initializers for `STPPaymentContext` or `STPPaymentMethodsViewController` that take an `STPBackendAPIAdapter` parameter, you should use the new initializers that take an `STPCustomerContext` parameter. You'll need to set up your instance of `STPCustomerContext` using the key provider you set up in (2).
- For a more detailed overview of the new integration, you can refer to our tutorial at https://stripe.com/docs/mobile/ios/standard
- `[STPFile stringFromPurpose:]` now returns `nil` for `STPFilePurposeUnknown`. Will return a non-nil value for all other `STPFilePurpose`.
- We've removed the `email` and `phone` properties in `STPUserInformation`. You can pre-fill this information in the shipping form using the new `shippingAddress` property.
- The SMS card fill feature has been removed from `STPPaymentContext`, as well as the associated `smsAutofillDisabled` configuration option (ie it will now always behave as if it is disabled).

### Migrating from versions < 10.2.0
- `paymentRequestWithMerchantIdentifier:` has been deprecated. You should instead use `paymentRequestWithMerchantIdentifier:country:currency:`. Apple Pay is now available in many countries and currencies, and you should use the appropriate values for your business.
- We've added a `paymentCountry` property to `STPPaymentContext`. This affects the countryCode of Apple Pay payments, and defaults to "US". You should set this to the country your Stripe account is in.
- Polling for source object updates is deprecated. Check https://stripe.com/docs for the latest best practices on how to integrate with the sources API using webhooks.
- `paymentMethodsViewController:didSelectPaymentMethod:` is now optional. If you have an empty implementation of this method, you can remove it.

### Migrating from versions < 10.1.0

- STPPaymentMethodsViewControllerDelegate now has a separate `paymentMethodsViewControllerDidCancel:` callback, differentiating from successful method selections. You should make sure to also dismiss the view controller in that callback.

### Migrating from versions < 10.0

- Methods deprecated in Version 6.0 have now been removed.
- The `STPSource` protocol has been renamed `STPSourceProtocol`.
- `STPSource` is now a model object representing a source from the Stripe API. https://stripe.com/docs/sources
- `STPCustomer` will now include `STPSource` objects in its `sources` array if a customer has attached sources.
- `STPErrorCode` and `STPCardErrorCode` are now first class Swift enums (before, their types were `Int` and `String`, respectively)

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

```objective-c
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
```

## Misc. notes

### Handling errors

See [StripeError.h](https://github.com/stripe/stripe-ios/blob/master/Stripe/PublicHeaders/StripeError.h) for a list of error codes that may be returned from the Stripe API.

### Validating STPCards

You have a few options for handling validation of credit card data on the client, depending on what your application does.  Client-side validation of credit card data is not required since our API will correctly reject invalid card information, but can be useful to validate information as soon as a user enters it, or simply to save a network request.

The simplest thing you can do is to populate an `STPCard` object and, before sending the request, call `- (BOOL)validateCardReturningError:` on the card.  This validates the entire card object, but is not useful for validating card properties one at a time.

To validate `STPCard` properties individually, you should use the following:

```objective-c
 - (BOOL)validateNumber:error:
 - (BOOL)validateCvc:error:
 - (BOOL)validateExpMonth:error:
 - (BOOL)validateExpYear:error:
```

These methods follow the validation method convention used by [key-value validation](http://developer.apple.com/library/mac/#documentation/cocoa/conceptual/KeyValueCoding/Articles/Validation.html).  So, you can use these methods by invoking them directly, or by calling `[card validateValue:forKey:error]` for a property on the `STPCard` object.

When using these validation methods, you will want to set the property on your card object when a property does validate before validating the next property.  This allows the methods to use existing properties on the card correctly to validate a new property.  For example, validating `5` for the `expMonth` property will return YES if no `expYear` is set.  But if `expYear` is set and you try to set `expMonth` to 5 and the combination of `expMonth` and `expYear` is in the past, `5` will not validate.  The order in which you call the validate methods does not matter for this though.

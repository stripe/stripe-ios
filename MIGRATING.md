## Migration Guides

### Migrating from versions < 21.0.0
* The SDK is now written in Swift, and some classes and functions have been renamed. Migration instructions are available at [https://stripe.com/ios-migrating-guide-tktk](https://stripe.com/ios-migrating-guide-tktk).

### Migrating from versions < 20.1.0
* Swift Package Manager users may need to remove and re-add Stripe from the `Frameworks, Libraries, and Embedded Content` section of your target's settings after updating.
* Swift Package Manager users with Xcode 12.0 may need to use a [workaround](https://github.com/stripe/stripe-ios/issues/1673) for a code signing issue. This is fixed in Xcode 12.2.

### Migrating from versions < 20.0.0
* The minimum iOS version is now 11.0. If you'd like to deploy for iOS 10.0, please use Stripe SDK 19.4.0.
* Card.io is no longer supported. To enable our built-in [card scanning](https://github.com/stripe/stripe-ios#card-scanning-beta) beta, set the `cardScanningEnabled` flag on STPPaymentConfiguration.
* Catalyst support is out of beta, and now requires Swift Package Manager with Xcode 12 or Cocoapods 1.10.

### Migrating from versions < 19.4.0
* `metadata` fields are no longer populated on retrieved Stripe API objects and must be fetched on your server using your secret key. If this is causing issues with your deployed app versions please reach out to [Stripe Support](https://support.stripe.com/?contact=true). These fields have been marked as deprecated and will be removed in a future SDK version.

### Migrating from versions < 19.3.0
* `STPAUBECSFormView` now inherits from `UIView` instead of `UIControl`

### Migrating from versions < 19.2.0
* The `STPApplePayContext` 'applePayContext:didCreatePaymentMethod:completion:` delegate method now includes paymentInformation: 'applePayContext:didCreatePaymentMethod:paymentInformation:completion:`. 


### Migrating from versions < 19.0.0
#### `publishableKey` and `stripeAccount` changes
* Deprecates `publishableKey` and `stripeAccount` properties of `STPPaymentConfiguration`. 
  * If you used `STPPaymentConfiguration.sharedConfiguration` to set `publishableKey` and/or `stripeAccount`, use `STPAPIClient.sharedClient` instead. 
  * If you passed a STPPaymentConfiguration instance to an SDK component, you should instead create an STPAPIClient, set publishableKey on it, and set the SDK component's APIClient property.
* The SDK now uses `STPAPIClient.sharedClient` to make API requests by default.

This changes the behavior of the following classes, which previously used API client instances configured from `STPPaymentConfiguration.shared`: `STPCustomerContext`, `STPPaymentOptionsViewController`, `STPAddCardViewController`, `STPPaymentContext`, `STPPinManagementService`, `STPPushProvisioningContext`. 

You are affected by this change if:

1. You use `stripeAccount` to work with your Connected accounts
2. You use one of the above affected classes
3. You set different `stripeAccount` values on `STPPaymentConfiguration` and `STPAPIClient`, i.e. `STPPaymentConfiguration.shared.stripeAccount != STPAPIClient.shared.stripeAccount`

If all three of the above conditions are true, you must update your integration! The SDK used to send `STPPaymentConfiguration.shared.stripeAccount`, and will now send `STPAPIClient.shared.stripeAccount`.  

For example, if you are a Connect user who stores Payment Methods on your platform, but clones PaymentMethods to a connected account and creates direct charges on that connected account i.e. if:

1. You never set `STPPaymentConfiguration.shared.stripeAccount`
2. You set `STPAPIClient.shared.stripeAccount`

We recommend you do the following:

```
    // By default, you don't want the SDK to pass stripeAccount
    STPAPIClient.shared().publishableKey = "pk_platform"
    STPAPIClient.shared().stripeAccount = nil

    // You do want the SDK to pass stripeAccount when it makes payments directly on your connected account, so 
    // you create a separate APIClient instance...
    let connectedAccountAPIClient = STPAPIClient(publishableKey: "pk_platform")

    // ...set stripeAccount on it...
    connectedAccountAPIClient.stripeAccount = "your connected account's id"
    
    // ...and either set the relevant SDK components' apiClient property to your custom APIClient instance:
    STPPaymentHandler.shared().apiClient = connectedAccountAPIClient // e.g. if you are using PaymentIntents

    // ...or use it directly to make API requests with `stripeAccount` set:
    connectedAccountAPIClient.createToken(withCard:...) // e.g. if you are using Tokens + Charges
```
#### Postal code changes
* The user's postal code is now collected by default in countries that support postal codes. We always recommend collecting a postal code to increase card acceptance rates and reduce fraud. To disable this behavior:
  * For STPPaymentContext and other full-screen UI, set your `STPPaymentConfiguration`'s `.requiredBillingAddressFields` to `STPBillingAddressFieldsNone`.
  * For a PKPaymentRequest, set `.requiredBillingContactFields` to an empty set. If your app supports iOS 10, also set `.requiredBillingAddressFields` to `PKAddressFieldNone`.
  * For STPPaymentCardView, set `.postalCodeEntryEnabled` to `NO`.
* Users may now enter spaces, dashes, and uppercase letters into the postal code field in situations where the user has not explicitly selected a country. This allows users with non-US addreses to enter their postal code.
* `STPBillingAddressFieldsZip` has been renamed to `STPBillingAddressFieldsPostalCode`.
#### Localization changes
* All [Stripe Error messages](https://stripe.com/docs/api/errors#errors-message) are now localized
  based on the device locale.
      
  For example, when retrieving a SetupIntent with a nonexistent `id`
  when the device locale is set to `Locale.JAPAN`, the error message will now be localized.
  ```
  // before - English
  "No such setupintent: seti_invalid123"

  // after - Japanese
  "そのような setupintent はありません : seti_invalid123"
  ```

### Migrating from versions < 18.0.0
* Some error messages from the Payment Intents API are now localized to the user's display language. If your application's logic depends on specific `message` strings from the Stripe API, please use the error [`code`](https://stripe.com/docs/error-codes) instead.
* `STPPaymentResult` may contain a `paymentMethodParams` instead of a `paymentMethod` when using single-use payment methods such as FPX. Because of this, `STPPaymentResult.paymentMethod` is now nullable. Instead of setting the `paymentMethodId` manually on your `paymentIntentParams`, you may now call `paymentIntentParams.configure(with result: STPPaymentResult)`:
```
// 17.0.0
paymentIntentParams.paymentMethodId = paymentResult.paymentMethod.stripeId

// 18.0.0
paymentIntentParams.configure(with: paymentResult)
```
* `STPPaymentOptionTypeAll` has been renamed to `STPPaymentOptionTypeDefault`. This option will not include FPX or future optional payment methods.
* The minimum iOS version is now 10.0. If you'd like to deploy for iOS 9.0, please use Stripe SDK 17.0.2.

### Migrating from versions < 17.0.0
* The API version has been updated from 2015-10-12 to 2019-05-16. CHANGELOG.md has details on the changes made, which includes breaking changes for `STPConnectAccountParams` users. Your backend Stripe API version should be sufficiently decoupled from the SDK's so that keeping their versions in sync is not required, and no further action is required to migrate to this version of the SDK.
* For STPPaymentContext users: the completion block type in `paymentContext:didCreatePaymentResult:completion:` has changed to `STPPaymentStatusBlock`, to let you inform the context that the user has cancelled. 

### Migrating from versions < 16.0.0
* The following have been migrated from Source/Token to PaymentMethod. If you have integrated with any of these things, you must also migrate to PaymentMethod and the Payment Intent API.  See https://stripe.com/docs/payments/payment-intents/migration.  See CHANGELOG.md for more details.
  * UI components
    * STPPaymentCardTextField
    * STPAddCardViewController
    * STPPaymentOptionsViewController
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

See [StripeError.h](https://github.com/stripe/stripe-ios/blob/master/Stripe/PublicHeaders/Stripe/StripeError.h) for a list of error codes that may be returned from the Stripe API.

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

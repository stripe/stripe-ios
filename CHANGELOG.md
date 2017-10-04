## 11.x.x 2017-XX-XX

* Restores `[STPCard brandFromString:]` method which was marked as deprecated in a recent version [#801](https://github.com/stripe/stripe-ios/pull/801)
* Adds `[STPBankAccount metadata]` and `[STPCard metadata]` read-only accessors and improves annotation for `[STPSource metadata]` [#808](https://github.com/stripe/stripe-ios/pull/808)

## 11.3.0 2017-09-13
* Adds support for creating `STPSourceParams` for P24 source [#779](https://github.com/stripe/stripe-ios/pull/779)
* Adds support for native app-to-app Alipay redirects [#783](https://github.com/stripe/stripe-ios/pull/783)
* Fixes crash when `paymentContext.hostViewController` is set to a `UINavigationController` [#786](https://github.com/stripe/stripe-ios/pull/786)
* Improves support and compatibility with iOS 11
  * Explicitly disable code coverage generation for compatibility with Carthage in Xcode 9 [#795](https://github.com/stripe/stripe-ios/pull/795)
  * Restore use of native "Back" buttons [#789](https://github.com/stripe/stripe-ios/pull/789)
* Changes and fixes methods on `STPCard`, `STPCardParams`, `STPBankAccount`, and `STPBankAccountParams` to bring card objects more in line with the rest of the API. See MIGRATING for further details.
  * `STPCard` and `STPCardParams` [#760](https://github.com/stripe/stripe-ios/pull/760)
  * `STPBankAccount` and `STPBankAccountParams` [#761](https://github.com/stripe/stripe-ios/pull/761)
* Adds nullability annotations to `STPPaymentMethod` protocol [#753](https://github.com/stripe/stripe-ios/pull/753)
* Improves the `[STPAPIResponseDecodable allResponseFields]` by removing all instances of `[NSNull null]` including ones that are nested. See MIGRATING.md. [#747](https://github.com/stripe/stripe-ios/pull/747)

## 11.2.0 2017-07-27
* Adds an option to allow users to delete payment methods from the `STPPaymentMethodsViewController`. Enabled by default but can disabled using the `canDeletePaymentMethods` property of `STPPaymentConfiguration`.
  * Screenshots: https://user-images.githubusercontent.com/28276156/28131357-7a353474-66ee-11e7-846c-b38277d111fd.png
* Adds a postal code field to `STPPaymentCardTextField`, configurable with `postalCodeEntryEnabled` and `postalCodePlaceholder`. Disabled by default.
* `STPCustomer`'s `shippingAddress` property is now correctly annotated as nullable.
* Removed `STPCheckoutUnknownError`, `STPCheckoutTooManyAttemptsError`, and `STPCustomerContextMissingKeyProviderError`. These errors will no longer occur.

## 11.1.0 2017-07-12
* Adds stripeAccount property to `STPAPIClient`, set this to perform API requests on behalf of a connected account
* Fixes the `routingNumber` property of `STPBankAccount` so that it is populated when the information is available
* Adds iOS Objective-C Style Guide

## 11.0.0 2017-06-27
* We've greatly simplified the integration for `STPPaymentContext`. See MIGRATING.md.
* As part of this new integration, we've added a new class, `STPCustomerContext`, which will automatically prefetch your customer and cache it for a brief interval. We recommend initializing your `STPCustomerContext` before your user enters your checkout flow so their payment methods are loaded in advance. If in addition to using `STPPaymentContext`, you create a separate `STPPaymentMethodsViewController` to let your customer manage their payment methods outside of your checkout flow, you can use the same instance of `STPCustomerContext` for both.
* We've added a `shippingAddress` property to `STPUserInformation`, which you can use to pre-fill your user's shipping information.
* `STPPaymentContext` will now save your user's shipping information to their Stripe customer object. Shipping information will automatically be pre-filled from the customer object for subsequent checkouts.
* Fixes nullability annotation for `[STPFile stringFromPurpose:]`. See MIGRATING.md.
* Adds description implementations to all public models, for easier logging and debugging.
* The card autofill via SMS feature of `STPPaymentContext` has been removed. See MIGRATING.md.

## 10.2.0 2017-06-19
* We've added a `paymentCountry` property to `STPPaymentContext`. This affects the countryCode of Apple Pay payments, and defaults to "US". You should set this to the country your Stripe account is in.
* `paymentRequestWithMerchantIdentifier:` has been deprecated. See MIGRATING.md
* If the card.io framework is present in your app, `STPPaymentContext` and `STPAddCardViewController` will show a "scan card" button.
* `STPAddCardViewController` will now attempt to auto-fill the users city and state from their entered Zip code (United States only)
* Polling for source object updates is deprecated. Check https://stripe.com/docs for the latest best practices on how to integrate with the sources API using webhooks.
* Fixes a crash in `STPCustomerDeserializer` when both data and error are nil.
* `paymentMethodsViewController:didSelectPaymentMethod:` is now optional.
* Updates the example apps to use Alamofire.

## 10.1.0 2017-05-05
* Adds STPRedirectContext, a helper class for handling redirect sources.
* STPAPIClient now supports tokenizing a PII number and uploading images.
* Updates STPPaymentCardTextField's icons to match Elements on the web. When the card number is invalid, the field will now display an error icon.
* The alignment of the new brand icons has changed to match the new CVC and error icons. If you use these icons via `STPImageLibrary`, you may need to adjust your layout.
* STPPaymentCardTextField's isValid property is now KVO-observable.
* When creating STPSourceParams for a SEPA debit source, address fields are now optional.
* `STPPaymentMethodsViewControllerDelegate` now has a separate `paymentMethodsViewControllerDidCancel:` callback, differentiating from successful method selections. You should make sure to also dismiss the view controller in that callback
* Because collecting some basic data on tokenization helps us detect fraud, we've removed the ability to disable analytics collection using `[Stripe disableAnalytics]`.

## 10.0.1 2017-03-16
* Fixes a bug where card sources didn't include the card owner's name.
* Fixes an issue where STPPaymentMethodsViewController didn't reload after adding a new payment method.

## 10.0.0 2017-03-06
* Adds support for creating, retrieving, and polling Sources. You can enable any payment methods available to you in the Dashboard.
  * https://stripe.com/docs/mobile/ios/sources
  * https://dashboard.stripe.com/account/payments/settings
* Updates the Objective-C example app to include example integrations using several different payment methods.
* Updates `STPCustomer` to include `STPSource` objects in its `sources` array if a customer has attached sources.
* Removes methods deprecated in Version 6.0.
* Fixes property declarations missing strong/nullable identifiers.

## 9.4.0 2017-02-03
* Adds button to billing/shipping entry screens to fill address information from the other one.
* Fixes and unifies view controller behavior around theming and nav bars.
* Adds month validity check to `validationStateForExpirationYear`
* Changes some Apple Pay images to better conform to official guidelines.
* Changes STPPaymentCardTextField's card number placeholder to "4242..."
* Updates STPPaymentCardTextField's CVC placeholder so that it changes to "CVV" for Amex cards

## 9.3.0 2017-01-05
* Fixes a regression introduced in v9.0.0 in which color in STPTheme is used as the background color for UINavigationBar
  * Note: This will cause navigation bar theming to work properly as described in the Stripe iOS docs, but you may need to audit your custom theme settings if you based them on the actual behavior of 9.0-9.2
* If the navigation bar has a theme different than the view controller's theme, STP view controllers will use the bar's theme to style it's UIBarButtonItems
* Adds a fallback to using main bundle for localized strings lookup if locale is set to a language the SDK doesn't support
* Adds method to get a string of a card brand from `STPCardBrand`
* Updated description of how to run tests in README
* Fixes crash when user cancels payment before STPBackendAPIAdapter methods finish
* Fixes bug where country picker wouldn't update when first selected.


## 9.2.0 2016-11-14
* Moves FBSnapshotTestCase dependency to Cartfile.private. No changes if you are not using Carthage.
* Adds prebuilt UI for collecting shipping information.

## 9.1.0 2016-11-01
* Adds localized strings for 7 languages: de, es, fr, it, ja, nl, zh-Hans.
* Slight redesign to card/billing address entry screen.
* Improved internationalization for State/Province/County address field.
* Adds new Mastercard 2-series BIN ranges.
* Fixes an issue where callbacks may be run on the wrong thread.
* Fixes UIAppearance compatibility in STPPaymentCardTextField.
* Fixes a crash when changing application language via an Xcode scheme.

## 9.0.0 2016-10-04
* Change minimum requirements to iOS 8 and Xcode 8
* Adds "app extension API only" support.
* Updates Swift example app to Swift 3
* Various fixes to ObjC example app

## 8.0.7 2016-09-15
* Add ability to set currency for managed accounts when adding card
* Fix broken links for Privacy Policy/Terms of Service for Remember Me feature
* Sort countries in picker alphabetically by name instead of ISO code
* Make "County" field optional on billing address screen.
* PKPayment-related methods are now annotated as available in iOS8+ only
* Optimized speed of input sanitation methods (thanks @kballard!)

## 8.0.6 2016-09-01
* Improved internationalization on billing address forms
  * Users in countries that don't use postal codes will no longer see that field.
  * The country field is now auto filled in with the phone's region
  * Changing the selected country will now live update other fields on the form (such as State/County or Zip/Postal Code).
* Fixed an issue where certain Cocoapods configurations could result in Stripe resource files being used in place of other frameworks' or the app's resources.
* Fixed an issue where when using Apple Pay, STPPaymentContext would fire two `didFinishWithStatus` messages.
* Fixed the `deviceSupportsApplePay` method to also check for Discover cards.
* Removed keys from Stripe.bundle's Info.plist that were causing iTunes Connect to sometimes error on app submission.

## 8.0.5 2016-08-26
* You can now optionally use an array of PKPaymentSummaryItems to set your payment amount, if you would like more control over how Apple Pay forms are rendered.
* Updated credit card and Apple Pay icons.
* Fixed some images not being included in the resources bundle target.
* Non-US locales now have an alphanumeric keyboard for postal code entry.
* Modals now use UIModalPresentationStyleFormSheet.
* Added more accessibility labels.
* STPPaymentCardTextField now conforms to UIKeyInput (thanks @theill).

## 8.0.4 2016-08-01
* Fixed an issue with Apple Pay payments not using the correct currency.
* View controllers now update their status bar and scroll view indicator styles based on their theme.
* SMS code screen now offers to paste copied codes.

## 8.0.3 2016-07-25
* Fixed an issue with some Cocoapods installations

## 8.0.2 2016-07-09
* Fixed an issue with custom theming of Stripe UI

## 8.0.1 2016-07-06
* Fixed error handling in STPAddCardViewController

## 8.0.0 2016-06-30
* Added prebuilt UI for collecting and managing card information.

## 7.0.2 2016-05-24
* Fixed an issue with validating certain Visa cards.

## 7.0.1 2016-04-29
* Added Discover support for Apple Pay
* Add the now-required `accountHolderName` and `accountHolderType` properties to STPBankAccountParams
* We now record performance metrics for the /v1/tokens API - to disable this behavior, call [Stripe disableAnalytics].
* You can now demo the SDK more easily by running `pod try stripe`.
* This release also removes the deprecated Checkout functionality from the SDK.

## 6.2.0 2016-02-05
* Added an `additionalAPIParameters` field to STPCardParams and STPBankAccountParams for sending additional values to the API - useful for beta features. Similarly, added an `allResponseFields` property to STPToken, STPCard, and STPBankAccount for accessing fields in the response that are not yet refelected in those classes' @properties.

## 6.1.0 2016-01-21
* Renamed card on STPPaymentCardTextField to cardParams.
* You can now set an STPPaymentCardTextField's contents programmatically by setting cardParams to an STPCardParams object.
* Added delegate methods for responding to didBeginEditing events in STPPaymentCardTextField.
* Added a UIImage category for accessing our card icon images
* Fixed deprecation warnings for deployment targets >= iOS 9.0

## 6.0.0 2015-10-19
* Splits logic in STPCard into 2 classes - STPCard and STPCardParams. STPCardParams is for making requests to the Stripe API, while STPCard represents the response (you'll almost certainly want just to replace any usage of STPCard in your app with STPCardParams). This also applies to STPBankAccount and the newly-created STPBankAccountParams.
* Version 6.0.1 fixes a minor Cocoapods issue.

## 5.1.0 2015-08-17
* Adds STPPaymentCardTextField, a new version of github.com/stripe/PaymentKit featuring many bugfixes. It's useful if you need a pre-built credit card entry form.
* Adds the currency param to STPCard for those using managed accounts & debit card payouts.
* Versions 5.1.1 and 5.1.2 fix minor issues with CocoaPods installation
* Version 5.1.3 contains bug fixes for STPPaymentCardTextField.
* Version 5.1.4 improves compatibility with iOS 9.

## 5.0.0 2015-08-06
* Fix an issue with Carthage installation
* Fix an issue with CocoaPods frameworks
* Deprecate native Stripe Checkout

## 4.0.1 2015-05-06
* Fix a compiler warning
* Versions 4.0.1 and 4.0.2 fix minor issues with CocoaPods and Carthage installation.

## 4.0.0 2015-05-06
* Remove STPPaymentPresenter
* Support for latest ApplePayStubs
* Add nullability annotations to improve Swift support (note: this now requires Swift 1.2)
* Bug fixes

## 3.1.0 2015-01-19
* Add support for native Stripe Checkout, as well as STPPaymentPresenter for automatically using Checkout as a fallback for Apple Pay
* Add OSX support, including Checkout
* Add framework targets and Carthage support
* It's safe to remove the STRIPE_ENABLE_APPLEPAY compiler flag after this release.

## 3.0.0 2015-01-05
* Migrate code into STPAPIClient
* Add 'brand' and 'funding' properties to STPCard

## 2.2.2 2014-11-17
* Add bank account tokenization methods

## 2.2.1 2014-10-27
* Add billing address fields to our Apple Pay API
* Various bug fixes and code improvements

## 2.2.0 2014-10-08
* Move Apple Pay testing functionality into a separate project, ApplePayStubs. For more info, see github.com/stripe/ApplePayStubs.
* Improve the provided example app

## 2.1.0 2014-10-07
* Remove token retrieval API method
* Refactor functional tests to use new XCTestCase functionality

## 2.0.3 2014-09-24
* Group ApplePay code in a CocoaPods subspec

## 2.0.2 2014-09-24
* Move ApplePay code behind a compiler flag to avoid warnings from Apple when accidentally including it

## 2.0.1 2014-09-18
* Fix some small bugs related to ApplePay and iOS8

## 2.0 2014-09-09
* Add support for native payments via Pay

## 1.2 2014-08-21
* Removed PaymentKit as a dependency. If you'd like to use it, you may still do so by including it separately.
* Removed STPView. PaymentKit provides a near-identical version of this functionality if you need to migrate.
* Improve example project
* Various code fixes

## 1.1.4 2014-05-22
* Fixed an issue where tokenization requests would fail under iOS 6 due to SSL certificate verification

## 1.1.3 2014-05-12
* Send some basic version and device details with requests for debugging.
* Added -description to STPToken
* Fixed some minor code nits
* Modernized code

## 1.1.2 2014-04-21
* Added test suite for SSL certificate expiry/revokation
* You can now set STPView's delegate from Interface Builder

## 1.1.1 2014-04-14
* API methods now verify the server's SSL certificate against a preset blacklist.
* Fixed some bugs with SSL verification.
* Note: This version now requires the `Security` framework. You will need to add this to your app if you're not using CocoaPods.

## 1.0.4 2014-03-24

* Upgraded tests from OCUnit to XCTest
* Fixed an issue with the SenTestingKit dependency
* Removed some dead code

## 1.0.3 2014-03-21

* Fixed: Some example files had target memberships set for StripeiOS and iOSTest.
* Fixed: The example publishable key was expired.
* Fixed: Podspec did not pass linting.
* Some fixes for 64-bit.
* Many improvements to the README.
* Fixed example under iOS 7
* Some source code cleaning and modernization.

## 1.0.2 2013-09-09

* Add exceptions for null successHandler and errorHandler.
* Added the ability to POST the created token to a URL.
* Made STPCard properties nonatomic.
* Moved PaymentKit to be a submodule; added to Podfile as a dependency.
* Fixed some warnings caught by the static analyzer (thanks to jcjimenez!)

## 1.0.1 2012-11-16

* Add CocoaPods support
* Change directory structure of bindings to make it easier to install

## 1.0.0 2012-11-16

* Initial release

Special thanks to: Todd Heasley, jcjimenez.

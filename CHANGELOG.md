## 20.0.0 2020-09-14
* [Card scanning](https://github.com/stripe/stripe-ios#card-scanning-beta) is now built into STPAddCardViewController. Card.io support has been removed. [#1629](https://github.com/stripe/stripe-ios/pull/1629)
* Shrunk the SDK from 1.3MB when compressed & thinned to 0.7MB, allowing for easier App Clips integration. [#1643](https://github.com/stripe/stripe-ios/pull/1643)
* Swift Package Manager, Apple Silicon, and Catalyst are now fully supported on Xcode 12. [#1644](https://github.com/stripe/stripe-ios/pull/1644)
* Adds support for 19-digit cards. [#1608](https://github.com/stripe/stripe-ios/pull/1608)
* Adds GrabPay and Sofort as PaymentMethod. [#1627](https://github.com/stripe/stripe-ios/pull/1627)
* Drops support for iOS 10. [#1643](https://github.com/stripe/stripe-ios/pull/1643)

## 19.4.0 2020-08-13
* `pkPaymentErrorForStripeError` no longer returns PKPaymentUnknownErrors. Instead, it returns the original NSError back, resulting in dismissal of the Apple Pay sheet. This means ApplePayContext dismisses the Apple Pay sheet for all errors that aren't specifically PKPaymentError types.
* `metadata` fields are no longer populated on retrieved Stripe API objects and must be fetched on your server using your secret key. If this is causing issues with your deployed app versions please reach out to [Stripe Support](https://support.stripe.com/?contact=true). These fields have been marked as deprecated and will be removed in a future SDK version.

## 19.3.0 2020-05-28
* Adds giropay PaymentMethod bindings [#1569](https://github.com/stripe/stripe-ios/pull/1569)
* Adds Przelewy24 (P24) PaymentMethod bindings [#1556](https://github.com/stripe/stripe-ios/pull/1556)
* Adds Bancontact PaymentMethod bindings [#1565](https://github.com/stripe/stripe-ios/pull/1565)
* Adds EPS PaymentMethod bindings [#1578](https://github.com/stripe/stripe-ios/pull/1578)
* Replaces es-AR localization with es-419 for full Latin American Spanish support and updates multiple localizations [#1549](https://github.com/stripe/stripe-ios/pull/1549) [#1570](https://github.com/stripe/stripe-ios/pull/1570)
* Fixes missing custom number placeholder in `STPPaymentCardTextField` [#1576](https://github.com/stripe/stripe-ios/pull/1576)
* Adds tabbing on external keyboard support to `STPAUBECSFormView` and correctly types it as a `UIView` instead of `UIControl` [#1580](https://github.com/stripe/stripe-ios/pull/1580)

## 19.2.0 2020-05-01
* Adds ability to attach shipping details when confirming PaymentIntents [#1558](https://github.com/stripe/stripe-ios/pull/1558)
* `STPApplePayContext` now provides shipping details in the `applePayContext:didCreatePaymentMethod:paymentInformation:completion:` delegate method and automatically attaches shipping details to PaymentIntents (unless manual confirmation)[#1561](https://github.com/stripe/stripe-ios/pull/1561)
* Adds support for the BECS Direct Debit payment method for Stripe users in Australia [#1547](https://github.com/stripe/stripe-ios/pull/1547)

## 19.1.1 2020-04-28
* Add advancedFraudSignalsEnabled property [#1560](https://github.com/stripe/stripe-ios/pull/1560)

## 19.1.0 2020-04-15
* Relaxes need for dob for full name connect account (`STPConnectAccountIndividualParams`). [#1539](https://github.com/stripe/stripe-ios/pull/1539)
* Adds Chinese (Traditional) and Chinese (Hong Kong) localizations [#1536](https://github.com/stripe/stripe-ios/pull/1536)
* Adds `STPApplePayContext`, a helper class for Apple Pay. [#1499](https://github.com/stripe/stripe-ios/pull/1499)
* Improves accessibility [#1513](https://github.com/stripe/stripe-ios/pull/1513), [#1504](https://github.com/stripe/stripe-ios/pull/1504)
* Adds support for the Bacs Direct Debit payment method [#1487](https://github.com/stripe/stripe-ios/pull/1487)
* Adds support for 16 digit Diners Club cards [#1498](https://github.com/stripe/stripe-ios/pull/1498)

## 19.0.1 2020-03-24
* Fixes an issue building with Xcode 11.4 [#1526](https://github.com/stripe/stripe-ios/pull/1526)

## 19.0.0 2020-02-12
* Deprecates the `STPAPIClient` `initWithConfiguration:` method. Set the `configuration` property on the `STPAPIClient` instance instead. [#1474](https://github.com/stripe/stripe-ios/pull/1474)
* Deprecates `publishableKey` and `stripeAccount` properties of `STPPaymentConfiguration`. See [MIGRATING.md](https://github.com/stripe/stripe-ios/blob/master/MIGRATING.md) for more details. [#1474](https://github.com/stripe/stripe-ios/pull/1474)
* Adds explicit STPAPIClient properties on all SDK components that make API requests. These default to `[STPAPIClient sharedClient]`. This is a breaking change for some users of `stripeAccount`. See [MIGRATING.md](https://github.com/stripe/stripe-ios/blob/master/MIGRATING.md) for more details. [#1469](https://github.com/stripe/stripe-ios/pull/1469)
* The user's postal code is now collected by default in countries that support postal codes. We always recommend collecting a postal code to increase card acceptance rates and reduce fraud. See [MIGRATING.md](https://github.com/stripe/stripe-ios/blob/master/MIGRATING.md) for more details. [#1479](https://github.com/stripe/stripe-ios/pull/1479)

## 18.4.0 2020-01-15
* Adds support for Klarna Pay on Sources API [#1444](https://github.com/stripe/stripe-ios/pull/1444)
* Compresses images using `pngcrush` to reduce SDK size [#1471](https://github.com/stripe/stripe-ios/pull/1471)
* Adds support for CVC recollection in PaymentIntent confirm [#1473](https://github.com/stripe/stripe-ios/pull/1473)
* Fixes a race condition when setting `defaultPaymentMethod` on `STPPaymentOptionsViewController` [#1476](https://github.com/stripe/stripe-ios/pull/1476)

## 18.3.0 2019-12-3
* STPAddCardViewControllerDelegate methods previously removed in v16.0.0 are now marked as deprecated, to help migrating users [#1439](https://github.com/stripe/stripe-ios/pull/1439)
* Fixes an issue where canceling 3DS authentication could leave PaymentIntents in an inaccurate `requires_action` state [#1443](https://github.com/stripe/stripe-ios/pull/1443)
* Fixes text color for large titles [#1446](https://github.com/stripe/stripe-ios/pull/1446) 
* Re-adds support for pre-selecting the last selected payment method in STPPaymentContext and STPPaymentOptionsViewController. [#1445](https://github.com/stripe/stripe-ios/pull/1445)
* Fix crash when adding/removing postal code cells [#1450](https://github.com/stripe/stripe-ios/pull/1450)

## 18.2.0 2019-10-31
* Adds support for creating tokens with the last 4 digits of an SSN [#1432](https://github.com/stripe/stripe-ios/pull/1432)
* Renames Standard Integration to Basic Integration

## 18.1.0 2019-10-29
* Adds localizations for English (Great Britain), Korean, Russian, and Turkish [#1373](https://github.com/stripe/stripe-ios/pull/1373)
* Adds support for SEPA Debit as a PaymentMethod [#1415](https://github.com/stripe/stripe-ios/pull/1415)
* Adds support for custom SEPA Debit Mandate params with PaymentMethod [#1420](https://github.com/stripe/stripe-ios/pull/1420)
* Improves postal code UI for users with mismatched regions [#1302](https://github.com/stripe/stripe-ios/issues/1302)
* Fixes a potential crash when presenting the add card view controller [#1426](https://github.com/stripe/stripe-ios/issues/1426)
* Adds offline status checking to FPX payment flows [#1422](https://github.com/stripe/stripe-ios/pull/1422)
* Adds support for push provisions for Issuing users [#1396](https://github.com/stripe/stripe-ios/pull/1396)

## 18.0.0 2019-10-04
* Adds support for building on macOS 10.15 with Catalyst. Use the .xcframework file attached to the release in GitHub. Cocoapods support is coming soon. [#1364](https://github.com/stripe/stripe-ios/issues/1364)
* Errors from the Payment Intents API are now localized by default. See [MIGRATING.md](https://github.com/stripe/stripe-ios/blob/master/MIGRATING.md) for details.
* Adds support for FPX in Standard Integration. [#1390](https://github.com/stripe/stripe-ios/pull/1390)
* Simplified Apple Pay integration when using 3DS2. [#1386](https://github.com/stripe/stripe-ios/pull/1386)
* Improved autocomplete behavior for some STPPaymentHandler blocks. [#1403](https://github.com/stripe/stripe-ios/pull/1403)
* Fixed spurious `keyboardWillAppear` messages triggered by STPPaymentTextCard. [#1393](https://github.com/stripe/stripe-ios/pull/1393)
* Fixed an issue with non-numeric placeholders in STPPaymentTextCard. [#1394](https://github.com/stripe/stripe-ios/pull/1394)
* Dropped support for iOS 9. Please continue to use 17.0.2 if you need to support iOS 9.

## 17.0.2 2019-09-24
* Fixes an error that could prevent a 3D Secure 2 challenge dialog from appearing in certain situations.
* Improved VoiceOver support. [#1384](https://github.com/stripe/stripe-ios/pull/1384)
* Updated Apple Pay and Mastercard branding. [#1374](https://github.com/stripe/stripe-ios/pull/1374)
* Updated the Standard Integration example app to use automatic confirmation. [#1363](https://github.com/stripe/stripe-ios/pull/1363)
* Added support for collecting email addresses and phone numbers from Apple Pay. [#1372](https://github.com/stripe/stripe-ios/pull/1372)
* Introduced support for FPX payments. (Invite-only Beta) [#1375](https://github.com/stripe/stripe-ios/pull/1375)

## 17.0.1 2019-09-09
* Cancellation during the 3DS2 flow will no longer cause an unexpected error. [#1353](https://github.com/stripe/stripe-ios/pull/1353)
* Large Title UIViewControllers will no longer have a transparent background in iOS 13. [#1362](https://github.com/stripe/stripe-ios/pull/1362)
* Adds an `availableCountries` option to STPPaymentConfiguration, allowing one to limit the list of countries in the address entry view. [#1327](https://github.com/stripe/stripe-ios/pull/1327)
* Fixes a crash when using card.io. [#1357](https://github.com/stripe/stripe-ios/pull/1357)
* Fixes an issue with birthdates when creating a Connect account. [#1361](https://github.com/stripe/stripe-ios/pull/1361)
* Updates example code to Swift 5. [#1354](https://github.com/stripe/stripe-ios/pull/1354)
* The default value of `[STPTheme translucentNavigationBar]` is now `YES`. [#1367](https://github.com/stripe/stripe-ios/pull/1367)

## 17.0.0 2019-09-04
* Adds support for iOS 13, including Dark Mode and minor bug fixes. [#1307](https://github.com/stripe/stripe-ios/pull/1307)
* Updates API version from 2015-10-12 to 2019-05-16 [#1254](https://github.com/stripe/stripe-ios/pull/1254)
  * Adds `STPSourceRedirectStatusNotRequired` to `STPSourceRedirectStatus`.  Previously, optional redirects were marked as `STPSourceRedirectStatusSucceeded`.
  * Adds `STPSourceCard3DSecureStatusRecommended` to `STPSourceCard3DSecureStatus`.  
  * Removes `STPLegalEntityParams`.  Initialize an `STPConnectAccountParams` with an `individual` or `company` dictionary instead. See https://stripe.com/docs/api/tokens/create_account#create_account_token-account
* Changes the `STPPaymentContextDelegate paymentContext:didCreatePaymentResult:completion:` completion block type to `STPPaymentStatusBlock`, to let you inform the context that the user canceled.
* Adds initial support for WeChat Pay. [#1326](https://github.com/stripe/stripe-ios/pull/1326)
* The user's billing address will now be included when creating a PaymentIntent from an Apple Pay token. [#1334](https://github.com/stripe/stripe-ios/pull/1334)


## 16.0.7 2019-08-23
* Fixes STPThreeDSUICustomization not initializing defaults correctly. [#1303](https://github.com/stripe/stripe-ios/pull/1303)
* Fixes STPPaymentHandler treating post-authentication errors as authentication errors [#1291](https://github.com/stripe/stripe-ios/pull/1291)
* Removes preferredStatusBarStyle from STPThreeDSUICustomization, see STPThreeDSNavigationBarCustomization.barStyle instead [#1308](https://github.com/stripe/stripe-ios/pull/1308)

## 16.0.6 2019-08-13
* Adds a method to STPAuthenticationContext allowing you to configure the SFSafariViewController presented for web-based authentication.
* Adds STPAddress initializer that takes STPPaymentMethodBillingDetails. [#1278](https://github.com/stripe/stripe-ios/pull/1278)
* Adds convenience method to populate STPUserInformation with STPPaymentMethodBillingDetails. [#1278](https://github.com/stripe/stripe-ios/pull/1278)
* STPShippingAddressViewController prefills billing address for PaymentMethods too now, not just Card. [#1278](https://github.com/stripe/stripe-ios/pull/1278)
* Update libStripe3DS2.a to avoid a conflict with Firebase. [#1293](https://github.com/stripe/stripe-ios/issues/1293)

## 16.0.5 2019-08-09
* Fixed an compatibility issue when building with certain Cocoapods configurations. [#1288](https://github.com/stripe/stripe-ios/issues/1288)

## 16.0.4 2019-08-08
* Improved compatibility with other OpenSSL-using libraries. [#1265](https://github.com/stripe/stripe-ios/issues/1265)
* Fixed compatibility with Xcode 10.1. [#1273](https://github.com/stripe/stripe-ios/issues/1273)
* Fixed an issue where STPPaymentContext could be left in a bad state when cancelled. [#1284](https://github.com/stripe/stripe-ios/pull/1284)

## 16.0.3 2019-08-01
* Changes to code obfuscation, resolving an issue with App Store review [#1269](https://github.com/stripe/stripe-ios/pull/1269)
* Adds Apple Pay support to STPPaymentHandler [#1264](https://github.com/stripe/stripe-ios/pull/1264)

## 16.0.2 2019-07-29
* Adds API to let users set a default payment option for Standard Integration [#1252](https://github.com/stripe/stripe-ios/pull/1252)
* Removes querying the Advertising Identifier (IDFA).
* Adds customizable UIStatusBarStyle to STDSUICustomization.

## 16.0.1 2019-07-25
* Migrates Stripe3DS2.framework to libStripe3DS2.a, resolving an issue with App Store validation. [#1246](https://github.com/stripe/stripe-ios/pull/1246)
* Fixes a crash in STPPaymentHandler. [#1244](https://github.com/stripe/stripe-ios/pull/1244)

## 16.0.0 2019-07-18
* Migrates STPPaymentCardTextField.cardParams property type from STPCardParams to STPPaymentMethodCardParams
* STPAddCardViewController:
    * Migrates addCardViewController:didCreateSource:completion: and addCardViewController:didCreateToken:completion: to addCardViewController:didCreatePaymentMethod:completion
    * Removes managedAccountCurrency property - there’s no equivalent parameter necessary for PaymentMethods.
* STPPaymentOptionViewController now shows, adds, removes PaymentMethods instead of Source/Tokens.
* STPCustomerContext, STPBackendAPIAdapter:
    * Removes selectDefaultCustomerSource:completion: -  Users must explicitly select their Payment Method of choice.
    * Migrates detachSourceFromCustomer:completion:, attachSourceToCustomer:completion to detachPaymentMethodFromCustomer:completion:, attachPaymentMethodToCustomer:completion:
    * Adds listPaymentMethodsForCustomerWithCompletion: - the Customer object doesn’t contain attached Payment Methods; you must fetch it from the Payment Methods API.
* STPPaymentContext now uses the new Payment Method APIs listed above instead of Source/Token, and returns the reworked STPPaymentResult containing a PaymentMethod.
* Migrates STPPaymentResult.source to paymentMethod of type STPPaymentMethod
* Deprecates STPPaymentIntentAction* types, replaced by STPIntentAction*. [#1208](https://github.com/stripe/stripe-ios/pull/1208)
  * Deprecates `STPPaymentIntentAction`, replaced by `STPIntentAction`
  * Deprecates `STPPaymentIntentActionType`, replaced by `STPIntentActionType`
  * Deprecates `STPPaymentIntentActionRedirectToURL`, replaced by `STPIntentActionTypeRedirectToURL`
* Adds support for SetupIntents.  See https://stripe.com/docs/payments/cards/saving-cards#saving-card-without-payment
* Adds support for 3DS2 authentication.  See https://stripe.com/docs/mobile/ios/authentication

## 15.0.1 2019-04-16
* Adds configurable support for JCB (Apple Pay). [#1158](https://github.com/stripe/stripe-ios/pull/1158)
* Updates sample apps to use `PaymentIntents` and `PaymentMethods` where available. [#1159](https://github.com/stripe/stripe-ios/pull/1159)
* Changes `STPPaymentMethodCardParams` `expMonth` and `expYear` property types to `NSNumber *` to fix a bug using Apple Pay. [#1161](https://github.com/stripe/stripe-ios/pull/1161)

## 15.0.0 2019-3-19
* Renames all former references to 'PaymentMethod' to 'PaymentOption'. See [MIGRATING.md](/MIGRATING.md) for more details. [#1139](https://github.com/stripe/stripe-ios/pull/1139)
  * Renames `STPPaymentMethod` to `STPPaymentOption`
  * Renames `STPPaymentMethodType` to `STPPaymentOptionType`
  * Renames `STPApplePaymentMethod` to `STPApplePayPaymentOption`
  * Renames `STPPaymentMethodTuple` to `STPPaymentOptionTuple`
  * Renames `STPPaymentMethodsViewController` to `STPPaymentOptionsViewController`
  * Renames all properties, methods, comments referencing 'PaymentMethod' to 'PaymentOption'
* Rewrites `STPaymentMethod` and `STPPaymentMethodType` to match the [Stripe API](https://stripe.com/docs/api/payment_methods/object). [#1140](https://github.com/stripe/stripe-ios/pull/1140).
* Adds `[STPAPI createPaymentMethodWithParams:completion:]`, which creates a PaymentMethod. [#1141](https://github.com/stripe/stripe-ios/pull/1141)
* Adds `paymentMethodParams` and `paymentMethodId` to `STPPaymentIntentParams`.  You can now confirm a PaymentIntent with a PaymentMethod. [#1142](https://github.com/stripe/stripe-ios/pull/1142)
* Adds `paymentMethodTypes` to `STPPaymentIntent`.
* Deprecates several Source-named properties, based on changes to the [Stripe API](https://stripe.com/docs/upgrades#2019-02-11). [#1146](https://github.com/stripe/stripe-ios/pull/1146)
  * Deprecates `STPPaymentIntentParams.saveSourceToCustomer`, replaced by `savePaymentMethod`
  * Deprecates `STPPaymentIntentsStatusRequiresSource`, replaced by `STPPaymentIntentsStatusRequiresPaymentMethod`
  * Deprecates `STPPaymentIntentsStatusRequiresSourceAction`, replaced by `STPPaymentIntentsStatusRequiresAction`
  * Deprecates `STPPaymentIntentSourceAction`, replaced by `STPPaymentIntentAction`
  * Deprecates `STPPaymentSourceActionAuthorizeWithURL`, replaced by `STPPaymentActionRedirectToURL`
  * Deprecates `STPPaymentIntent.nextSourceAction`, replaced by `nextAction`
* Added new localizations for the following languages [#1050](https://github.com/stripe/stripe-ios/pull/1050)
  * Danish
  * Spanish (Argentina/Latin America)
  * French (Canada)
  * Norwegian
  * Portuguese (Brazil)
  * Portuguese (Portugal)
  * Swedish
* Deprecates `STPEphemeralKeyProvider`, replaced by `STPCustomerEphemeralKeyProvider`.  We now allow for ephemeral keys that are not customer [#1131](https://github.com/stripe/stripe-ios/pull/1131)
* Adds CVC image for Amex cards [#1046](https://github.com/stripe/stripe-ios/pull/1046)
* Fixed `STPPaymentCardTextField.nextFirstResponderField` to never return nil [#1059](https://github.com/stripe/stripe-ios/pull/1059)
* Improves return key functionality for `STPPaymentCardTextField`, `STPAddCardViewController` [#1059](https://github.com/stripe/stripe-ios/pull/1059)
* Add postal code support for Saudi Arabia [#1127](https://github.com/stripe/stripe-ios/pull/1127)
* CVC field updates validity if card number/brand change [#1128](https://github.com/stripe/stripe-ios/pull/1128)

## 14.0.0 2018-11-14
* Changes `STPPaymentCardTextField`, which now copies the `cardParams` property. See [MIGRATING.md](/MIGRATING.md) for more details. [#1031](https://github.com/stripe/stripe-ios/pull/1031)
* Renames `STPPaymentIntentParams.returnUrl` to `STPPaymentIntentParams.returnURL`. [#1037](https://github.com/stripe/stripe-ios/pull/1037)
* Removes `STPPaymentIntent.returnUrl` and adds `STPPaymentIntent.nextSourceAction`, based on changes to the [Stripe API](https://stripe.com/docs/upgrades#2018-11-08). [#1038](https://github.com/stripe/stripe-ios/pull/1038)
* Adds `STPVerificationParams.document_back` property. [#1017](https://github.com/stripe/stripe-ios/pull/1017)
* Fixes bug in `STPPaymentMethodsViewController` where selected payment method changes back if it wasn't dismissed in the `didFinish` delegate method. [#1020](https://github.com/stripe/stripe-ios/pull/1020)

## 13.2.0 2018-08-14
* Adds `STPPaymentMethod` protocol implementation for `STPSource`. You can now call `image`/`templatedImage`/`label` on a source. [#976](https://github.com/stripe/stripe-ios/pull/976)
* Fixes crash in `STPAddCardViewController` with some prefilled billing addresses [#1004](https://github.com/stripe/stripe-ios/pull/1004)
* Fixes `STPPaymentCardTextField` layout issues on small screens [#1009](https://github.com/stripe/stripe-ios/pull/1009)
* Fixes hidden text fields in `STPPaymentCardTextField` from being read by VoiceOver [#1012](https://github.com/stripe/stripe-ios/pull/1012)
* Updates example app to add client-side metadata `charge_request_id` to requests to `example-ios-backend` [#1008](https://github.com/stripe/stripe-ios/pull/1008)

## 13.1.0 2018-07-13
* Adds `STPPaymentIntent` to support PaymentIntents. [#985](https://github.com/stripe/stripe-ios/pull/985), [#986](https://github.com/stripe/stripe-ios/pull/986), [#987](https://github.com/stripe/stripe-ios/pull/987), [#988](https://github.com/stripe/stripe-ios/pull/988)
* Reduce `NSURLSession` memory footprint. [#969](https://github.com/stripe/stripe-ios/pull/969)
* Fixes invalid JSON error when deleting `Card` from a `Customer`. [#992](https://github.com/stripe/stripe-ios/pull/992)

## 13.0.3 2018-06-11
* Fixes payment method label overlapping the checkmark, for Amex on small devices [#952](https://github.com/stripe/stripe-ios/pull/952)
* Adds EPS and Multibanco support to `STPSourceParams` [#961](https://github.com/stripe/stripe-ios/pull/961)
* Adds `STPBillingAddressFieldsName` option to `STPBillingAddressFields` [#964](https://github.com/stripe/stripe-ios/pull/964)
* Fixes crash in `STPColorUtils.perceivedBrightnessForColor` [#954](https://github.com/stripe/stripe-ios/pull/954)
* Applies recommended project changes for Xcode 9.4 [#963](https://github.com/stripe/stripe-ios/pull/963)
* Fixes `[Stripe handleStripeURLCallbackWithURL:url]` incorrectly returning `NO` [#962](https://github.com/stripe/stripe-ios/pull/962)

## 13.0.2 2018-05-24
* Makes iDEAL `name` parameter optional, also accepts empty string as `nil` [#940](https://github.com/stripe/stripe-ios/pull/940)
* Adjusts scroll view content offset behavior when focusing on a text field [#943](https://github.com/stripe/stripe-ios/pull/943)

## 13.0.1 2018-05-17
* Fixes an issue in `STPRedirectContext` causing some redirecting sources to fail in live mode due to prematurely dismissing the `SFSafariViewController` during the initial redirects. [#937](https://github.com/stripe/stripe-ios/pull/937)

## 13.0.0 2018-04-26
* Removes Bitcoin source support. See MIGRATING.md. [#931](https://github.com/stripe/stripe-ios/pull/931)
* Adds Masterpass support to `STPSourceParams` [#928](https://github.com/stripe/stripe-ios/pull/928)
* Adds community submitted Norwegian (nb) translation. Thank @Nailer!
* Fixes example app usage of localization files (they were not able to be tested in Finnish and Norwegian before)
* Silences STPAddress deprecation warnings we ignore to stay compatible with older iOS versions
* Fixes "Card IO" link in full SDK reference [#913](https://github.com/stripe/stripe-ios/pull/913)

## 12.1.2 2018-03-16
* Updated the "62..." credit card number BIN range to show a UnionPay icon

## 12.1.1 2018-02-22
* Fix issue with apple pay token creation in PaymentContext, introduced by 12.1.0. [#899](https://github.com/stripe/stripe-ios/pull/899)
* Now matches clang static analyzer settings with Cocoapods, so you won't see any more analyzer issues. [#897](https://github.com/stripe/stripe-ios/pull/897)

## 12.1.0 2018-02-05
* Adds `createCardSources` to `STPPaymentConfiguration`. If you enable this option, when your user adds a card in the SDK's UI, a card source will be created and attached to their Stripe Customer. If this option is disabled (the default), a card token is created. For more information on card sources, see https://stripe.com/docs/sources/cards

## 12.0.1 2018-01-31
* Adding Visa Checkout support to `STPSourceParams` [#889](https://github.com/stripe/stripe-ios/pull/889)

## 12.0.0 2018-01-16
* Minimum supported iOS version is now 9.0.
  * If you need to support iOS 8, the last supported version is [11.5.0](https://github.com/stripe/stripe-ios/releases/tag/v11.5.0)
* Minimum supported Xcode version is now 9.0
* `AddressBook` framework support has been removed.
* `STPRedirectContext` will no longer retain itself for the duration of the redirect, you must explicitly maintain a reference to it yourself. [#846](https://github.com/stripe/stripe-ios/pull/846)
* `STPPaymentConfiguration.requiredShippingAddress` now is a set of `STPContactField` objects instead of a `PKAddressField` bitmask. [#848](https://github.com/stripe/stripe-ios/pull/848)
* See MIGRATING.md for more information on any of the previously mentioned breaking API changes.
* Pre-built view controllers now layout properly on iPhone X in landscape orientation, respecting `safeAreaInsets`. [#854](https://github.com/stripe/stripe-ios/pull/854)
* Fixes a bug in `STPAddCardViewController` that prevented users in countries without postal codes from adding a card when `requiredBillingFields = .Zip`. [#853](https://github.com/stripe/stripe-ios/pull/853)
* Fixes a bug in `STPPaymentCardTextField`. When completely filled out, it ignored calls to `becomeFirstResponder`. [#855](https://github.com/stripe/stripe-ios/pull/855)
* `STPPaymentContext` now has a `largeTitleDisplayMode` property, which you can use to control the title display mode in the navigation bar of our pre-built view controllers. [#849](https://github.com/stripe/stripe-ios/pull/849)
* Fixes a bug where `STPPaymentContext`'s `retryLoading` method would not re-retrieve the customer object, even after calling `STPCustomerContext`'s `clearCachedCustomer` method. [#863](https://github.com/stripe/stripe-ios/pull/863)
* `STPPaymentContext`'s `retryLoading` method will now always attempt to retrieve a new customer object, regardless of whether a cached customer object is available. Previously, this method was only intended for recovery from a loading error; if a customer had already been retrieved, `retryLoading` would do nothing. [#863](https://github.com/stripe/stripe-ios/pull/863)
* `STPCustomerContext` has a new property: `includeApplePaySources`. It is turned off by default. [#864](https://github.com/stripe/stripe-ios/pull/864)
* Adds `UITextContentType` support. This turns on QuickType suggestions for the name, email, and address fields; and uses a better keyboard for Payment Card fields. [#870](https://github.com/stripe/stripe-ios/pull/870)
* Fixes a bug that prevented redirects to the 3D Secure authentication flow when it was optional. [#878](https://github.com/stripe/stripe-ios/pull/878)
* `STPPaymentConfiguration` now has a `stripeAccount` property, which can be used to make API requests on behalf of a Connected account. [#875](https://github.com/stripe/stripe-ios/pull/875)
* Adds `- [STPAPIClient createTokenWithConnectAccount:completion:]`, which creates Tokens for Connect Accounts: (optionally) accepting the Terms of Service, and sending information about the legal entity. [#876](https://github.com/stripe/stripe-ios/pull/876)
* Fixes an iOS 11 bug in `STPPaymentCardTextField` that blocked tapping on the number field while editing the expiration or CVC on narrow devices (4" screens). [#883](https://github.com/stripe/stripe-ios/pull/883)

## 11.5.0 2017-11-09
* Adds a new helper method to `STPSourceParams` for creating reusable Alipay sources. [#811](https://github.com/stripe/stripe-ios/pull/811)
* Silences spurious availability warnings when using Xcode9 [#823](https://github.com/stripe/stripe-ios/pull/823)
* Auto capitalizes currency code when using `paymentRequestWithMerchantIdentifier ` to improve compatibility with iOS 11 `PKPaymentAuthorizationViewController` [#829](https://github.com/stripe/stripe-ios/pull/829)
* Fixes a bug in `STPRedirectContext` which caused `SFSafariViewController`-based redirects to incorrectly dismiss when switching apps. [#833](https://github.com/stripe/stripe-ios/pull/833)
* Fixes a bug that incorrectly offered users the option to "Use Billing Address" on the shipping address screen when there was no existing billing address to fill in. [#834](https://github.com/stripe/stripe-ios/pull/834)

## 11.4.0 2017-10-20
* Restores `[STPCard brandFromString:]` method which was marked as deprecated in a recent version [#801](https://github.com/stripe/stripe-ios/pull/801)
* Adds `[STPBankAccount metadata]` and `[STPCard metadata]` read-only accessors and improves annotation for `[STPSource metadata]` [#808](https://github.com/stripe/stripe-ios/pull/808)
* Un-deprecates `STPBackendAPIAdapter` and all associated methods. [#813](https://github.com/stripe/stripe-ios/pull/813)
* The `STPBackendAPIAdapter` protocol now includes two optional methods, `detachSourceFromCustomer` and `updateCustomerWithShipping`. If you've implemented a class conforming to `STPBackendAPIAdapter`, you may add implementations of these methods to support deleting cards from a customer and saving shipping info to a customer. [#813](https://github.com/stripe/stripe-ios/pull/813)
* Adds the ability to set custom footers on view controllers managed by the SDK. [#792](https://github.com/stripe/stripe-ios/pull/792)
* `STPPaymentMethodsViewController` will now display saved card sources in addition to saved card tokens. [#810](https://github.com/stripe/stripe-ios/pull/810)
* Fixes a bug where certain requests would return a generic failed to parse response error instead of the actual API error. [#809](https://github.com/stripe/stripe-ios/pull/809)

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
* Added an `additionalAPIParameters` field to STPCardParams and STPBankAccountParams for sending additional values to the API - useful for beta features. Similarly, added an `allResponseFields` property to STPToken, STPCard, and STPBankAccount for accessing fields in the response that are not yet reflected in those classes' @properties.

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
* Added test suite for SSL certificate expiry/revocation
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

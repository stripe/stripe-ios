## 24.2.0 2024-12-19

### Connect
* [Added] `StripeConnect` SDK to add connected account dashboard functionality to your app using [Connect embedded components](https://docs.stripe.com/connect/get-started-connect-embedded-components?platform=ios).

## 24.1.3 2024-12-16
### PaymentSheet, CustomerSheet
* [Changed] Changed the edit and remove saved payment method flow so that tapping 'Edit' displays an icon that leads to a new update payment method screen that displays payment method details for card (last 4 digits of card number, cvc and expiry date fields), US Bank account (name, email, last 4 digits of bank acocunt), and SEPA debit (name, email, last 4 digits of IBAN).

### Identity
* [Fixed] Fixes an error with selfie verification.

## 24.1.2 2024-12-05
### PaymentSheet
* [Fixed] Fixed an issue where FlowController returned incorrect `PaymentOptionDisplayData` for Link card brand transactions.

## 24.1.1 2024-12-02
### PaymentSheet
* [Fixed] Fixed an animation glitch when dismissing PaymentSheet in React Native.
* [Fixed] Fixed an issue in Instant Bank Payments that occurred when using a connected account.

## 24.1.0 2024-11-25
### Payments
* [Added] Support for Crypto bindings.

### PaymentSheet
* [Fixed] US Bank Account now shows the correct mandate when using the `instant_or_skip` verification method.

## 24.0.2 2024-11-21
### PaymentSheet
* [Fixed] A bug where PaymentSheet would cause layout issues when nested within certain navigation stacks.

## 24.0.1 2024-11-18
### PaymentSheet
* [Added] Instant Bank Payments are now available when using deferred intents.
* [Fixed] Fixed an issue with the vertical list with 3 or more saved payment methods where tapping outside the screen sometimes drops changes that were made (e.g. removal or update of PMs).
* [Fixed] Fixed an issue where the dialog when removing a co-branded card may show the incorrect card brand.
* [Fixed] Fixed issue preventing users to enter in 4 digit account numbers for AU Becs.

## 24.0.0 2024-11-04
### PaymentSheet
* [Changed] The default value of `PaymentSheet.Configuration.paymentMethodLayout` has changed from `.horizontal` to `.automatic`. See [MIGRATING.md](https://github.com/stripe/stripe-ios/blob/master/MIGRATING.md) for more details.
* [Fixed] Fixed an animation glitch when dismissing PaymentSheet in React Native.
* [Fixed] Fixed an issue with FlowController in vertical layout where the payment method could incorrectly be preserved across a call to `update` when it's no longer valid.
* [Fixed] Fixed a potential deadlock when `paymentOption` is accessed from Swift concurrency.
* [Fixed] Fixed deferred intent validation to handle cloned payment methods ([#4195](https://github.com/stripe/stripe-ios/issues/4195)

### Basic Integration
* [Removed] Basic Integration has been removed. [Please use Mobile Payment Element instead](https://docs.stripe.com/payments/mobile/migrating-to-mobile-payment-element-from-basic-integration).

## 23.32.0 2024-10-21
### PaymentSheet
* [Added] Added `PaymentSheet.Configuration.paymentMethodLayout`. Configure the layout of payment methods in the sheet using `paymentMethodLayout` to display them either horizontally, vertically, or let Stripe optimize the layout automatically.

## 23.31.1 2024-10-08
### PaymentSheet
* [Fixed] Fixed an issue where ISK was not correctly formatted as a zero-decimal currency when using PaymentSheet or Apple Pay. (Thanks [@Thithip](https://github.com/Thithip)!)
* [Fixed] Fixed an issue where US Bank Account forms would drop form field input when `FlowController.update` is called.

## 23.31.0 2024-09-23
### PaymentSheet
* [Added] The ability to customize the disabled colors of the primary button with `PaymentSheetAppearance.primaryButton.disabledBackgroundColor` and `PaymentSheetAppearance.primaryButton.disabledTextColor`.
* [Added] CVC Recollection is now in GA. For more information see our docs for [here](https://docs.stripe.com/payments/accept-a-payment?platform=ios#ios-cvc-recollection) for intent first integrations or [here](https://docs.stripe.com/payments/accept-a-payment-deferred?platform=ios&type=payment#ios-cvc-recollection) for deferred intent integrations.
* [Fixed] Fixed an issue where checkboxes were not visible when `appearance.colors.componentBorder` was transparent.

### CardScan
* [Fixed] The 0.5x lens is now used when scanning cards, if available. (Thanks [@akhmedovgg](https://github.com/akhmedovgg)!)

## 23.30.0 2024-09-09
### PaymentSheet
* [Added] CustomerSessions is now in private beta.
* [Fixed] PaymentSheet now uses a border width of 1.5 instead of 0 when `PaymentSheet.Appearance.borderWidth' is 0.
* [Fixed] The 0.5x lens is now used when scanning cards, if available. (Thanks [@akhmedovgg](https://github.com/akhmedovgg)!)

## 23.29.2 2024-08-19
### PaymentSheet
* [Fixed] Avoid multiple calls to CVC Recollection callback for deferred intent integrations
* [Fixed] Fixed an issue in SwiftUI where setting `isPresented=false` wouldn't dismiss the sheet.

## 23.29.1 2024-08-12
### PaymentSheet
* [Fixed] Fixed an issue where signing up with Link and paying would vend an empty `STPPaymentMethod` object to an `IntentConfiguration` confirmHandler callback.
* [Fixed] Fixed PaymentSheet.FlowController returning unlocalized labels for certain payment methods e.g. "AfterPay ClearPay" instead of "Afterpay" or "Clearpay" depending on locale.
* [Added] `PaymentSheet.IntentConfiguration` now validates that its `amount` is non-zero.

### PaymentsUI
* [Fixed] Fixed an issue where STPPaymentCardTextField wouldn't call its delegate `paymentCardTextFieldDidChange` method when the preferred card network changed.

## 23.29.0 2024-08-05
### PaymentSheet
* [Fixed] Fixed a scroll issue with native 3DS2 authentication screen when the keyboard appears.
* [Added] When a card is saved (ie you're using a PaymentIntent + setup_future_usage or SetupIntent), legal disclaimer text now appears below the form indicating the card can be charged for future payments.
* [Fixed] iOS 18 Compatibility with removing multiple saved payment methods
* [Fixed] Fixed an issue where the keyboard could focus on a hidden phone number field.
* [Added] Support for Sunbit (Private Beta) with PaymentIntents.
* [Added] Support for Billie (Private Beta) with PaymentIntents.
* [Fixed] Fixed an issue where saved payment method UI wouldn't respect `PaymentSheet.Configuration.style` when selected.
* [Added] Support for Satispay (Private Beta) with PaymentIntents.

### Payments
* [Added] Support for Sunbit (Private Beta) bindings.
* [Added] Support for Billie (Private Beta) bindings.
* [Added] Support for Satispay (Private Beta) bindings.

## 23.28.3 2024-09-03
This release was made in error, and contains changes from 23.29.0, 23.29.1, and 23.29.2.

## 23.28.1 2024-07-16
### Payments
* [Fixed] Improved reliability when paying or setting up with Cash App Pay.
* [Fixed] Pass stripeAccount context when presenting PayWithLinkWebController for connected accounts

## 23.28.0 2024-07-08

### Payments
* [Fixed] An issue where the correct card brand was not being displayed for card brand choice in STPPaymentOptionsViewController and STPPaymentContext.
* [Added] Adds coupon support to STPApplePayContext with a new `didChangeCouponCode` delegate method (h/t @JoeyLeeMEA).
* [Fixed] Fixed an issue where successful TWINT payments were sometimes incorrectly considered 'canceled'.

### PaymentSheet
* [Fixed] Fixed an issue where certain cobranded cards showed a generic card icon instead of using the other card brand.
* [Fixed] Fixed an issue where amounts with currency=IDR were displayed as-is, instead of dropping the last two digits.
* [Fixed] Fixed an issue where some payment method images in the horizontal scrollview could briefly flash.

## 23.27.6 2024-06-25
### All
* [Fixed] Improved reliability when paying with Swish.

## 23.27.5 2024-06-20
### PaymentSheet
* [Fixed] An issue that was preventing users from completing checkout with SetupIntents and PaymentIntents using `setup_future_usage` for the following payment method types: Amazon Pay, Cash App Pay, PayPal, and Revolut Pay.

## 23.27.4 2024-06-18
### PaymentSheet
* [Fixed] Fixed an issue where when displaying an LPM with no input fields, the sheet would take up the entire height of the screen.

## 23.27.3 2024-06-14
### PaymentSheet
* [Fixed] Fixed an issue where changing the country of a phone number would not update the UI when the phone number's validity changed.
* [Changed] The "save this card" checkbox is now unchecked by default. To change this behavior, set your PaymentSheet.Configuration.savePaymentMethodOptInBehavior to `.requiresOptOut`.
* [Fixed] Fixed an issue where PaymentSheet would not present in the iOS 18 beta when using SwiftUI.
* [Fixed] Fixed an issue in PaymentSheet.FlowController that could lead to the CVC recollection form being shown on presentPaymentOptions()

### CustomerSheet
* [Fixed] Fixed an issue where CustomerSheet would not present in the iOS 18 beta when using SwiftUI.

### Payments
* [Added] Updated support for MobilePay bindings.
* [Changed] Some Payment Methods (including Klarna and PayPal) may now authenticate using ASWebAuthenticationSession, enabling these payment methods to share session storage across apps.
* [Fixed] Fixed printing spurious STPAssertionFailure warnings.

## 23.27.2 2024-05-06
### CardScan
* [Changed] ScannedCard to allow access for expiryMonth, expiryYear and name.

### PaymentSheet
* [Added] Support for Multibanco with PaymentIntents.
* [Fixed] Fixed an issue where STPPaymentHandler sometimes reported errors using `unexpectedErrorCode` instead of a more specific error when customers fail a next action.
* [Changed] PaymentSheet displays Apple Pay as a button when there are saved payment methods and Link isn't available instead of within the list of saved payment methods.
* [Fixed] Expiration dates more than 50 years in the past (e.g. `95`) are now blocked.

### Payments
* [Added] Support for Multibanco bindings.
* [Fixed] Expiration dates more than 50 years in the past (e.g. `95`) are now blocked.

## 23.27.1 2024-04-22
### Payments
* [Fixed] An issue where the PrivacyInfo.xcprivacy was not bundled with StripePayments when installing with Cocoapods.

### Apple Pay
* [Changed] Apple Pay additionalEnabledApplePayNetworks are now in front of the supported network list.

### PaymentsUI
* [Added] Added support for `onBehalfOf` to STPPaymentCardTextField and STPCardFormView. This parameter may be required when setting a connected account as the merchant of record for a payment. For more information, see the [Connect docs](https://docs.stripe.com/connect/charges#on_behalf_of).

## 23.27.0 2024-04-08
### Payments
* [Added] Support for Alma bindings.
* [Fixed] STPBankAccountCollector errors now use "STPBankAccountCollectorErrorDomain" instead of "STPPaymentHandlerErrorDomain".

### All
* [Fixed] Fixed an issue with generating App Privacy reports.

## 23.26.0 2024-03-25
### PaymentSheet
* [Fixed] When confirming a SetupIntent with Link, "Set up" will be shown as the confirm button text instead of "Pay".

### CustomerSheet
* [Fixed] Fixed an issue dismissing the sheet when Link is the default payment method.

### Financial Connections
* [Fixed] Improved the UX of an edge case in Financial Connections authentication flow.

### All
* Added a [Privacy Manifest](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files).

## 23.25.1 2024-03-18
### All
* Xcode 14 is [no longer supported by Apple](https://developer.apple.com/news/upcoming-requirements/). Please upgrade to Xcode 15 or later.

### PaymentSheet
* [Fixed] A bug where `PaymentSheet.FlowController` was not respecting `PaymentSheet.Configuration.primaryButtonLabel`.
* [Added] Support for Klarna with SetupIntents and PaymentIntents with `setup_future_usage`.

### Financial Connections
* [Changed] Updated the design of Financial Connections authentication flow.

## 23.25.0 2024-03-11
### CustomerSheet
* [Added] Added `paymentMethodTypes` in `CustomerAdapter` to control what payment methods are displayed.

### PaymentSheet
* [Fixed] The rotating [card brand view](https://docs.stripe.com/co-badged-cards-compliance) is now shown when card brand choice is enabled if the card number is empty.

## 23.24.1 2024-03-05
### PaymentSheet
* [Fixed] Fixed an assertionFailure that happens when using FlowController and switching between saved payment methods

## 23.24.0 2024-03-04
### PaymentSheet
* [Added] Added support for [Link](https://docs.stripe.com/payments/link/mobile-payment-element-link) in PaymentSheet. Enabling Link in your [payment method settings](https://dashboard.stripe.com/settings/payment_methods) will enable Link in PaymentSheet. To choose different Link availability settings on web and mobile, use a custom [payment method configuration](https://docs.stripe.com/payments/multiple-payment-method-configs).
* [Fixed] Fixed an issue where some 3DS2 payments may fail to complete successfully.

### Payments
* [Added] Support for Amazon Pay bindings.

## 23.23.0 2024-02-26
### PaymentSheet
* [Added] Added support for [payment method configurations](https://docs.stripe.com/payments/multiple-payment-method-configs) when using the deferred intent integration path.

### CustomerSheet
* [Fixed] Fixed a bug where if an exception is thrown in detachPaymentMethod(), the payment method was removed in the UI [#3309](https://github.com/stripe/stripe-ios/pull/3309)

## 23.22.0 2024-02-12
### PaymentSheet
* [Changed] The separator text under the Apple Pay button from "Or pay with a card" to "Or use a card" when using a SetupIntent.
* [Fixed] Fixed a bug where deleting the last saved payment method in PaymentSheet wouldn't automatically transition to the "Add a payment method" screen.
* [Added] Support for CVC recollection in PaymentSheet and PaymentSheet.FlowController (client-side confirmation)

* [Changed] Make STPPinManagementService still usable from Swift.

## 23.21.2 2024-02-05
### Payments
* [Changed] We now auto append `mandate_data` when using Klarna with a SetupIntent. If you are interested in using Klarna with SetupIntents you sign up for the beta [here](https://stripe.com/docs/payments/klarna/accept-a-payment).

## 23.21.1 2024-01-22
### Payments
* [Changed] Increased the maximum number of status update retries when waiting for an intent to update to a terminal state. This impacts Cash App Pay and 3DS2.

## 23.21.0 2024-01-16
### PaymentSheet
* [Fixed] Fixed a few design issues on visionOS.
* [Added] Added billing details and type properties to [`PaymentSheet.FlowController.PaymentOptionDisplayData`](https://stripe.dev/stripe-ios/stripepaymentsheet/documentation/stripepaymentsheet/paymentsheet/flowcontroller/paymentoptiondisplaydata).

## 23.20.0 2023-12-18
### PaymentSheet
* [Added] Support for [card brand choice](https://stripe.com/docs/card-brand-choice). To set default preferred networks, use the new configuration option `PaymentSheet.Configuration.preferredNetworks`.
* [Fixed] Fixed visionOS support in Swift Package Manager and Cocoapods.

### CustomerSheet
* [Added] Support for [card brand choice](https://stripe.com/docs/card-brand-choice). To set default preferred networks, use the new configuration option `PaymentSheet.Configuration.preferredNetworks`.

### PaymentsUI
* [Added] Adds support for [card brand choice](https://stripe.com/docs/card-brand-choice) to STPPaymentCardTextField and STPCardFormView. To set a default preferred network for these UI elements, use the new `preferredNetworks` parameter.

* [Changed] Mark STPPinManagementService deprecated & suggest alternative.

## 23.19.0 2023-12-11
### Apple Pay
* [Fixed] STPApplePayContext initializer returns nil in more cases where the request is invalid.
* [Fixed] STPApplePayContext now allows Apple Pay when the customer doesn’t have saved cards but can set them up in the Apple Pay sheet (iOS 15+).

### PaymentSheet
* [Fixed] PaymentSheet sets newly saved payment methods as the default so that they're pre-selected the next time the customer pays.
* [Added] PaymentSheet now supports external payment methods. See https://stripe.com/docs/payments/external-payment-methods?platform=ios

### CustomerSheet
* [Added] Saved SEPA payment methods are now displayed to the customer for reuse, similar to saved cards.


## 23.18.3 2023-11-28
### PaymentSheet
* [Fixed] Visual bug where re-presenting PaymentSheet wouldn't show a spinner while it reloads.
* [Added] If PaymentSheet fails to load a deferred intent configuration, we fall back to displaying cards (or the intent configuration payment method types) instead of failing.
* [Fixed] Fixed an issue where PaymentSheet wouldn't accept valid Mexican phone numbers.
* [Added] The ability to customize the success colors of the primary button with `PaymentSheetAppearance.primaryButton.successBackgroundColor` and `PaymentSheetAppearance.primaryButton.successTextColor`.

## 23.18.2 2023-11-06
### CustomerSheet
* [Fixed] CustomerSheet no longer displays saved cards that originated from Apple Pay or Google Pay.

## 23.18.1 2023-10-30
### PaymentSheet
* [Fixed] Added a public initializer for `PaymentSheet.BillingDetails`.
* [Fixed] Fixed some payment method icons not updating to use the latest assets.
* [Fixed] PaymentSheet no longer displays saved cards that originated from Apple Pay or Google Pay.

### PaymentsUI
* [Fixed] Fixed an issue with `STPPaymentCardTextField` where the `paymentCardTextFieldDidEndEditing` delegate method was not called.

### PaymentSheet
* [Fixed] Fixed some payment method icons not updating to use the latest assets.

## 23.18.0 2023-10-23
### PaymentSheet
* [Added] Saved SEPA payment methods are now displayed to the customer for reuse, similar to saved cards.

### PaymentsUI
* [Fixed] Fixed an issue where the unknown card icon would sometimes pick up the view's tint color.

## 23.17.2 2023-10-16
### PaymentsUI
* [Fixed] An issue with `STPPaymentCardTextField`, where the card params were not updated after deleting an empty sub field.
* [Fixed] Switched to Asset Catalogs and updated to the latest card brand logos.

### Payments
* [Added] Support for MobilePay bindings.

## 23.17.1 2023-10-09
### PaymentSheet
* [Fixed] Fixed an issue when advancing from the country dropdown that prevented user's' from typing in their postal code. ([#2936](https://github.com/stripe/stripe-ios/issues/2936))

### PaymentsUI
* [Fixed] An issue with `STPPaymentCardTextField`, where the `paymentCardTextFieldDidChange` delegate method wasn't being called after deleting an empty sub field.

## 23.17.0 2023-10-02
### PaymentSheet
* [Fixed] Fixed an issue with selecting from lists on macOS Catalyst. Note that only macOS 11 or later is supported: We do not recommend releasing a Catalyst app targeting macOS 10.15.
* [Fixed] Fixed an issue with scanning card expiration dates.
* [Fixed] Fixed an issue where billing address collection configuration was not passed to Apple Pay.
* [Added] Support for Swish with PaymentIntents.
* [Added] Support for Bacs Direct Debit with PaymentIntents.

### Basic Integration
* [Fixed] Fixed an issue with scanning card expiration dates.

### Payments
* [Fixed] Fixed an issue where amounts in Serbian Dinar were displayed incorrectly.
* [Fixed] Fixed an issue where the SDK could hang in macOS Catalyst.
* [Added] Support for Swish bindings.

## 23.16.0 2023-09-18
### Payments
* [Added] Properties of STPConnectAccountParams are now mutable.
* [Fixed] Fixed STPConnectAccountCompanyParams.address being force unwrapped. It's now optional.
* [Added] Support for RevolutPay bindings

### PaymentSheet
* [Added] Support for Alipay with PaymentIntents.
* [Added] Support for Cash App Pay with SetupIntents and PaymentIntents with `setup_future_usage`.
* [Added] Support for AU BECS Debit with SetupIntents.
* [Added] Support for OXXO with PaymentIntents.
* [Added] Support for Konbini with PaymentIntents.
* [Added] Support for PayNow with PaymentIntents.
* [Added] Support for PromptPay with PaymentIntents.
* [Added] Support for Boleto with PaymentIntents and SetupIntets.
* [Added] Support for External Payment Method as an invite-only private beta.
* [Added] Support for RevolutPay with SetupIntents and PaymentIntents with setup_future_usage (private beta). Note: PaymentSheet doesn't display this as a saved payment method yet.
* [Added] Support for Alma (Private Beta) with PaymentIntents.

## 23.15.0 2023-08-28
### PaymentSheet
* [Added] Support for AmazonPay (private beta), BLIK, and FPX with PaymentIntents.
* [Fixed] A bug where payment amounts were not displayed correctly for LAK currency.

### StripeApplePay
* Fixed a compile-time issue with using StripeApplePay in an App Extension. ([#2853](https://github.com/stripe/stripe-ios/issues/2853))

### CustomerSheet
* [Added] `CustomerSheet`(https://stripe.com/docs/elements/customer-sheet?platform=ios) API, a prebuilt UI component that lets your customers manage their saved payment methods.

## 23.14.0 2023-08-21
### All
* Improved redirect UX when using Cash App Pay.

### PaymentSheet
* [Added] Support for GrabPay with PaymentIntents.

### Payments
* [Added] You can now create an STPConnectAccountParams without specifying a business type.

### Basic Integration
* [Added] Adds `applePayLaterAvailability` to `STPPaymentContext`, a property that mirrors `PKPaymentRequest.applePayLaterAvailability`. This is useful if you need to disable Apple Pay Later. Note: iOS 17+.


## 23.13.0 2023-08-07
### All
* [Fixed] Fixed compatibility with Xcode 15 beta 3. visionOS is now supported in iPadOS compatibility mode.
### PaymentSheet
* [Added] Enable bancontact and sofort for SetupIntents and PaymentIntents with setup_future_usage. Note: PaymentSheet doesn't display saved SEPA Debit payment methods yet.
### CustomerSheet
* [Added] `us_bank_account` PaymentMethod is now available in CustomerSheet

## 23.12.0 2023-07-31
### PaymentSheet
* [Added] Enable SEPA Debit and iDEAL for SetupIntents and PaymentIntents with setup_future_usage. Note: PaymentSheet doesn't display saved SEPA Debit payment methods yet.
* [Added] Add removeSavedPaymentMethodMessage to PaymentSheet.Configuration and CustomerSheet.Configuration.

### Identity
* [Added] Supports [phone verification](https://stripe.com/docs/identity/phone) in Identity mobile SDK.


## 23.11.2 2023-07-24
### PaymentSheet
* [Fixed] Update stp_icon_add@3x.png to 8bit color depth (Thanks @jszumski)

### CustomerSheet
* [Fixed] Ability to removing payment method immediately after adding it.
* [Fixed] Re-init addPaymentMethodViewController after adding payment method to allow for adding another payment method

## 23.11.1 2023-07-18
### PaymentSheet
* [Fixed] Fixed various bugs in Link private beta.

## 23.11.0 2023-07-17
### CustomerSheet
* [Changed] Breaking interface change for `CustomerSheetResult`. `CustomerSheetResult.canceled` now has a nullable associated value signifying that there is no selected payment method. Please use both `.canceled(StripeOptionSelection?)` and `.selected(PaymentOptionSelection?)` to update your UI to show the latest selected payment method.

## 23.10.0 2023-07-10
### Payments
* [Fixed] A bug where `mandate_data` was not being properly attached to PayPal SetupIntent's.
### PaymentSheet
* [Added] You can now collect payment details before creating a PaymentIntent or SetupIntent. See [our docs](https://stripe.com/docs/payments/accept-a-payment-deferred) for more info. This integration also allows you to [confirm the Intent on the server](https://stripe.com/docs/payments/finalize-payments-on-the-server).

## 23.9.4 2023-07-05
### PaymentSheet
* [Added] US bank accounts are now supported when initializing with an IntentConfiguration.

## 23.9.3 2023-06-26
### PaymentSheet
* [Fixed] Affirm no longer requires shipping details.

### CustomerSheet
* [Added] Added `billingDetailsCollectionConfiguration` to configure how you want to collect billing details (private beta).

## 23.9.2 2023-06-20
### Payments
* [Fixed] Fixed a bug causing Cash App Pay SetupIntents to incorrectly state they were canceled when they succeeded.

### AddressElement
* [Fixed] A bug that was causing `addressViewControllerDidFinish` to return a non-nil `AddressDetails` when the user cancels out of the AddressElement when default values are provided.
* [Fixed] A bug that prevented the auto complete view from being presented when the AddressElement was created with default values.

## 23.9.1 2023-06-12
### PaymentSheet
* [Fixed] Fixed validating the IntentConfiguration matches the PaymentIntent/SetupIntent when it was already confirmed on the server. Note: server-side confirmation is in private beta.
### CustomerSheet
* [Fixed] Fixed bug with removing multiple saved payment methods

## 23.9.0 2023-05-30
### PaymentSheet
* [Changed] The private beta API for https://stripe.com/docs/payments/finalize-payments-on-the-server has changed:
  * If you use `IntentConfiguration(..., confirmHandler:)`, the confirm handler now has an additional `shouldSavePaymentMethod: Bool` parameter that you should ignore.
  * If you use `IntentConfiguration(..., confirmHandlerForServerSideConfirmation:)`, use `IntentConfiguration(..., confirmHandler:)` instead. Additionally, the confirm handler's first parameter is now an `STPPaymentMethod` object instead of a String id. Use `paymentMethod.stripeId` to get its id and send it to your server.
* [Fixed] Fixed PKR currency formatting.

### CustomerSheet
* [Added] [CustomerSheet](https://stripe.com/docs/elements/customer-sheet?platform=ios) is now available (private beta)

## 23.8.0 2023-05-08
### Identity
* [Added] Added test mode M1 for the SDK.

## 23.7.1 2023-05-02
### Payments
* [Fixed] STPPaymentHandler.handleNextAction allows payment methods that are delayed or require further customer action like like SEPA Debit or OXXO.

## 23.7.0 2023-04-24
### PaymentSheet
* [Fixed] Fixed disabled text color, using a lower opacity version of the original color instead of the previous `.tertiaryLabel`.

### Identity
* [Added] Added test mode for the SDK.

## 23.6.2 2023-04-20

### Payments
* [Fixed] Fixed UnionPay cards appearing as invalid in some cases.

### PaymentSheet
* [Fixed] Fixed a bug that prevents users from using SEPA Debit w/ PaymentIntents or SetupIntents and Paypal in PaymentIntent+setup_future_usage or SetupIntent.

## 23.6.1 2023-04-17
### All
* Xcode 13 is [no longer supported by Apple](https://developer.apple.com/news/upcoming-requirements/). Please upgrade to Xcode 14.1 or later.
### PaymentSheet
* [Fixed] Visual bug of the delete icon when deleting saved payment methods reported in [#2461](https://github.com/stripe/stripe-ios/issues/2461).

## 23.6.0 2023-03-27
### PaymentSheet
* [Added] Added `billingDetailsCollectionConfiguration` to configure how you want to collect billing details. See the docs [here](https://stripe.com/docs/payments/accept-a-payment?platform=ios&ui=payment-sheet#billing-details-collection).

## 23.5.1 2023-03-20
### Payments
* [Fixed] Fixed amounts in COP being formatted incorrectly.
* [Fixed] Fixed BLIK payment bindings not handling next actions correctly.
* [Changed] Removed usage of `UIDevice.currentDevice.name`.

### Identity
* [Added] Added a retake photo button on selfie scanning screen.

## 23.5.0 2023-03-13
### Payments
* [Added] API bindings support for Cash App Pay. See the docs [here](https://stripe.com/docs/payments/cash-app-pay/accept-a-payment?platform=mobile).
* [Added] Added `STPCardValidator.possibleBrands(forCard:completion:)`, which returns the list of available networks for a card.

### PaymentSheet
* [Added] Support for Cash App Pay in PaymentSheet.

## 23.4.2 2023-03-06
### Identity
* [Added] ID/Address verification.

## 23.4.1 2023-02-27
### PaymentSheet
* [Added] Debug logging to help identify why specific payment methods are not showing up in PaymentSheet.

### Basic Integration
* [Fixed] Race condition reported in #2302

## 23.4.0 2023-02-21
### PaymentSheet
* [Added] Adds support for setting up PayPal using a SetupIntent or a PaymentIntent w/ setup_future_usage=off_session. Note: PayPal is in beta.

## 23.3.4 2023-02-13
### Financial Connections
* [Changed] Polished Financial Connections UI.

## 23.3.3 2023-01-30
### Payments
* [Changed] Updated image asset for AFFIN bank.

### Financial Connections
* [Fixed] Double encoding of GET parameters.

## 23.3.2 2023-01-09
* [Changed] Using [Tuist](https://tuist.io) to generate Xcode projects. From now on, only release versions of the SDK will include Xcode project files, in case you want to build a non release revision from source, you can follow [these instructions](https://docs.tuist.io/tutorial/get-started) to generate the project files. For Carthage users, this also means that you will only be able to depend on release versions.

### PaymentSheet
* [Added] `PaymentSheetError` now conforms to `CustomDebugStringConvertible` and has a more useful description when no payment method types are available.
* [Changed] Customers can now re-enter the autocomplete flow of `AddressViewController` by tapping an icon in the line 1 text field.

## 23.3.1 2022-12-12
* [Fixed] Fixed a bug where 3 decimal place currencies were not being formatted properly.

### PaymentSheet
* [Fixed] Fixed an issue that caused animations of the card logos in the Card input field to glitch.
* [Fixed] Fixed a layout issue in the "Save my info" checkbox.

### CardScan
* [Fixed] Fixed UX model loading from the wrong bundle. [#2078](https://github.com/stripe/stripe-ios/issues/2078) (Thanks [nickm01](https://github.com/nickm01))

## 23.3.0 2022-12-05
### PaymentSheet
* [Added] Added logos of accepted card brands on Card input field.
* [Fixed] Fixed erroneously displaying the card scan button when card scanning is not available.

### Financial Connections
* [Changed] FinancialConnectionsSheet methods now require to be called from non-extensions.
* [Changed] BankAccountToken.bankAccount was changed to an optional.

## 23.2.0 2022-11-14
### PaymentSheet
* [Added] Added `AddressViewController`, a customizable view controller that collects local and international addresses for your customers. See https://stripe.com/docs/elements/address-element?platform=ios.
* [Added] Added `PaymentSheet.Configuration.allowsPaymentMethodsRequiringShippingAddress`. Previously, to allow payment methods that require a shipping address (e.g. Afterpay and Affirm) in PaymentSheet, you attached a shipping address to the PaymentIntent before initializing PaymentSheet. Now, you can instead set this property to `true` and set `PaymentSheet.Configuration.shippingDetails` to a closure that returns your customers' shipping address. The shipping address will be attached to the PaymentIntent when the customer completes the checkout.
* [Fixed] Fixed user facing error messages for card related errors.
* [Fixed] Fixed `setup_future_usage` value being set when there's no customer.

## 23.1.1 2022-11-07
### Payments
* [Fixed] Fixed an issue with linking the StripePayments SDK in certain configurations.

## 23.1.0 2022-10-31
### CardScan
* [Added] Added a README.md for the `CardScanSheet` integration.

### PaymentSheet
* [Added] Added parameters to customize the primary button and Apple Pay button labels. They can be found under `PaymentSheet.Configuration.primaryButtonLabel` and `PaymentSheet.ApplePayConfiguration.buttonType` respectively.

## 23.0.0 2022-10-24
### Payments
* [Changed] Reduced the size of the SDK by splitting the `Stripe` module into `StripePaymentSheet`, `StripePayments`, and `StripePaymentsUI`. Some manual changes may be required. Migration instructions are available at [https://stripe.com/docs/mobile/ios/sdk-23-migration](https://stripe.com/docs/mobile/ios/sdk-23-migration).

|Module|Description|Compressed|Uncompressed|
|------|-----------|----------|------------|
|StripePaymentSheet|Stripe's [prebuilt payment UI](https://stripe.com/docs/payments/accept-a-payment?platform=ios&ui=payment-sheet).|2.7MB|6.3MB|
|Stripe|Contains all the below frameworks, plus [Issuing](https://stripe.com/docs/issuing/cards/digital-wallets?platform=iOS) and [Basic Integration](/docs/mobile/ios/basic).|2.3MB|5.1MB|
|StripeApplePay|[Apple Pay support](/docs/apple-pay), including `STPApplePayContext`.|0.4MB|1.0MB|
|StripePayments|Bindings for the Stripe Payments API.|1.0MB|2.6MB|
|StripePaymentsUI|Bindings for the Stripe Payments API, [STPPaymentCardTextField](https://stripe.com/docs/payments/accept-a-payment?platform=ios&ui=custom), STPCardFormView, and other UI elements.|1.7MB|3.9MB|

* [Changed] The minimum iOS version is now 13.0. If you'd like to deploy for iOS 12.0, please use Stripe SDK 22.8.4.
* [Changed] STPPaymentCardTextField's `cardParams` parameter has been deprecated in favor of `paymentMethodParams`, making it easier to include the postal code from the card field. If you need to access the `STPPaymentMethodCardParams`, use `.paymentMethodParams.card`.

### PaymentSheet
* [Fixed] Fixed a validation issue where cards expiring at the end of the current month were incorrectly treated as expired.
* [Fixed] Fixed a visual bug in iOS 16 where advancing between text fields would momentarily dismiss the keyboard.

## 22.8.4 2022-10-12
### PaymentSheet
* [Fixed] Use `.formSheet` modal presentation in Mac Catalyst. [#2023](https://github.com/stripe/stripe-ios/issues/2023) (Thanks [sergiocampama](https://github.com/sergiocampama)!)

## 22.8.3 2022-10-03
### CardScan
* [Fixed] [Garbled privacy link text in Card Scan UI](https://github.com/stripe/stripe-ios/issues/2015)

## 22.8.2 2022-09-19
### Identity
* [Changed] Support uploading single side documents.
* [Fixed] Fixed Xcode 14 support.
### Financial Connections
* [Fixed] Fixes an issue of returning canceled result from FinancialConnections if user taps cancel on the manual entry success screen.
### CardScan
* [Added] Added a new parameter to CardScanSheet.present() to specify if the presentation should be done animated or not. Defaults to true.
* [Changed] Changed card scan ML model loading to be async.
* [Changed] Changed minimum deployment target for card scan to iOS 13.

## 22.8.1 2022-09-12
### PaymentSheet
* [Fixed] Fixed potential crash when using Link in Mac Catalyst.
* [Fixed] Fixed Right-to-Left (RTL) layout issues.

### Apple Pay
* [Fixed] Fixed an issue where `applePayContext:willCompleteWithResult:authorizationResult:handler:` may not be called in Objective-C implementations of `STPApplePayContextDelegate`.

## 22.8.0 2022-09-06
### PaymentSheet
* [Changed] Renamed `PaymentSheet.reset()` to `PaymentSheet.resetCustomer()`. See `MIGRATING.md` for more info.
* [Added] You can now set closures in `PaymentSheet.ApplePayConfiguration.customHandlers` to configure the PKPaymentRequest and PKPaymentAuthorizationResult during a transaction. This enables you to build support for [Merchant Tokens](https://developer.apple.com/documentation/passkit/pkpaymentrequest/3916053-recurringpaymentrequest) and [Order Tracking](https://developer.apple.com/documentation/passkit/pkpaymentorderdetails) in iOS 16.

### Apple Pay
* [Added] You can now implement the `applePayContext(_:willCompleteWithResult:handler:)` function in your `ApplePayContextDelegate` to configure the PKPaymentAuthorizationResult during a transaction. This enables you to build support for [Order Tracking](https://developer.apple.com/documentation/passkit/pkpaymentorderdetails) in iOS 16.

## 22.7.1 2022-08-31
* [Fixed] Fixed Mac Catalyst support in Xcode 14. [#2001](https://github.com/stripe/stripe-ios/issues/2001)

### PaymentSheet
* [Fixed] PaymentSheet now uses configuration.apiClient for Apple Pay instead of always using STPAPIClient.shared.
* [Fixed] Fixed a layout issue with PaymentSheet in landscape.

## 22.7.0 2022-08-15
### PaymentSheet
* [Fixed] Fixed a layout issue on iPad.
* [Changed] Improved Link support in custom flow (`PaymentSheet.FlowController`).

## 22.6.0 2022-07-05
### PaymentSheet
* [Added] PaymentSheet now supports Link payment method.
* [Changed] Change behavior of Afterpay/Clearpay: Charge in 3 for GB, FR, and ES

### STPCardFormView
* [Changed] Postal code is no longer collected for billing addresses in Japan.

### Identity
* [Added] The ability to capture Selfie images in the native component flow.
* [Fixed] Fixed an issue where the welcome and confirmation screens were not correctly decoding non-ascii characters.
* [Fixed] Fixed an issue where, if a manually uploaded document could not be decoded on the server, there was no way to select a new image to upload.
* [Fixed] Fixed an issue where the IdentityVerificationSheet completion block was called early when manually uploading a document image instead of using auto-capture.

## 22.5.1 2022-06-21
* [Fixed] Fixed an issue with `STPPaymentHandler` where returning an app redirect could cause a crash.

## 22.5.0 2022-06-13
### PaymentSheet
* [Added] You can now use `PaymentSheet.ApplePayConfiguration.paymentSummaryItems` to directly configure the payment summary items displayed in the Apple Pay sheet. This is useful for recurring payments.

## 22.4.0 2022-05-23
### PaymentSheet
* [Added] The ability to customize the appearance of the PaymentSheet using `PaymentSheet.Appearance`.
* [Added] Support for collecting payments from customers in 54 additional countries within PaymentSheet. Most of these countries are located in Africa and the Middle East.
* [Added] `affirm` and `AUBECSDebit` payment methods are now available in PaymentSheet

## 22.3.2 2022-05-18
### CardScan
* [Added] Added privacy text to the CardImageVerification Sheet UI

## 22.3.1 2022-05-16
* [Fixed] Fixed an issue where ApplePayContext failed to parse an API response if the funding source was unknown.
* [Fixed] Fixed an issue where PaymentIntent confirmation could fail when the user closes the challenge window immediately after successfully completing a challenge

### Identity
* [Fixed] Fixed an issue where the verification flow would get stuck in a document upload loop when verifying with a passport and uploading an image manually.

## 22.3.0 2022-05-03

### PaymentSheet
* [Added] `us_bank_account` PaymentMethod is now available in payment sheet

## 22.2.0 2022-04-25

### Connections
* [Changed] `StripeConnections` SDK has been renamed to `StripeFinancialConnections`. See `MIGRATING.md` for more info.

### PaymentSheet
* [Fixed] Fixed an issue where `source_cancel` API requests were being made for non-3DS payment method types.
* [Fixed] Fixed an issue where certain error messages were not being localized.
* [Added] `us_bank_account` PaymentMethod is now available in PaymentSheet.

### Identity
* [Fixed] Minor UI fixes when using `IdentityVerificationSheet` with native components
* [Changed] Improvements to native component `IdentityVerificationSheet` document detection

## 22.1.1 2022-04-11

### Identity
* [Fixed] Fixes VerificationClientSecret (Thanks [Masataka-n](https://github.com/Masataka-n)!)

## 22.1.0 2022-04-04
* [Changed] Localization improvements.
### Identity
* [Added] `IdentityVerificationSheet` can now be used with native iOS components.

## 22.0.0 2022-03-28
* [Changed] The minimum iOS version is now 12.0. If you'd like to deploy for iOS 11.0, please use Stripe SDK 21.12.0.
* [Added] `us_bank_account` PaymentMethod is now available for ACH Direct Debit payments, including APIs to collect customer bank information (requires `StripeConnections`) and verify microdeposits.
* [Added] `StripeConnections` SDK can be optionally included to support ACH Direct Debit payments.

### PaymentSheet
* [Changed] PaymentSheet now uses light and dark mode agnostic icons for payment method types.
* [Changed] Link payment method (private beta) UX improvements.

### Identity
* [Changed] `IdentityVerificationSheet` now has an availability requirement of iOS 14.3 on its initializer instead of the `present` method.

## 21.13.0 2022-03-15
* [Changed] Binary framework distribution now requires Xcode 13. Carthage users using Xcode 12 need to add the `--no-use-binaries` flag.

### PaymentSheet
* [Fixed] Fixed potential crash when using PaymentSheet custom flow with SwiftUI.
* [Fixed] Fixed being unable to cancel native 3DS2 in PaymentSheet.
* [Fixed] The payment method icons will now use the correct colors when PaymentSheet is configured with `alwaysLight` or `alwaysDark`.
* [Fixed] A race condition when setting the `primaryButtonColor` on `PaymentSheet.Configuration`.
* [Added] PaymentSheet now supports Link (private beta).

### CardScan
* [Added] The `CardImageVerificationSheet` initializer can now take an additional `Configuration` object.

## 21.12.0 2022-02-14
* [Added] We now offer a 1MB Apple Pay SDK module intended for use in an App Clip. Visit [our App Clips docs](https://stripe.com/docs/apple-pay#app-clips) for details.
* `Stripe` now requires `StripeApplePay`. See `MIGRATING.md` for more info.
* [Added] Added a convenience initializer to create an STPCardParams from an STPPaymentMethodParams.

### PaymentSheet
* [Changed] The "save this card" checkbox in PaymentSheet is now unchecked by default in non-US countries.
* [Fixed] Fixes issue that could cause symbol name collisions when using Objective-C
* [Fixed] Fixes potential crash when using PaymentSheet with SwiftUI

## 21.11.1 2022-01-10
* Fixes a build warning in SPM caused by an invalid Package.swift file.

## 21.11.0 2022-01-04
* [Changed] The maximum `identity_document` file upload size has been increased, improving the quality of compressed images. See https://stripe.com/docs/file-upload
* [Fixed] The maximum `dispute_evidence` file upload size has been decreased to match server requirements, preventing the server from rejecting uploads that exceeded 5MB. See https://stripe.com/docs/file-upload
* [Added] PaymentSheet now supports Afterpay / Clearpay, EPS, Giropay, Klarna, Paypal (private beta), and P24.

## 21.10.0 2021-12-14
* Added API bindings for Klarna
* `StripeIdentity` now requires `StripeCameraCore`. See `MIGRATING.md` for more info.
* Releasing `StripeCardScan` Beta iOS SDK
* Fixes a bug where the text field would cause a crash when typing a space (U+0020) followed by pressing the backspace key on iPad. [#1907](https://github.com/stripe/stripe-ios/issues/1907) (Thanks [buhikon](https://github.com/buhikon)!)

## 21.9.1 2021-12-02
* Fixes a build warning caused by a duplicate NSURLComponents+Stripe.swift file.

## 21.9.0 2021-10-18
### PaymentSheet
This release adds several new features to PaymentSheet, our drop-in UI integration:

#### More supported payment methods
The list of supported payment methods depends on your integration.
If you’re using a PaymentIntent, we support:
- Card
- SEPA Debit, bancontact, iDEAL, sofort

If you’re using a PaymentIntent with `setup_future_usage` or a SetupIntent, we support:
- Card
- Apple/GooglePay

Note: To enable SEPA Debit and sofort, set `PaymentSheet.configuration.allowsDelayedPaymentMethods` to `true` on the client.
These payment methods can't guarantee you will receive funds from your customer at the end of the checkout because they take time to settle. Don't enable these if your business requires immediate payment (e.g., an on-demand service). See https://stripe.com/payments/payment-methods-guide

#### Pre-fill billing details
PaymentSheet collects billing details like name and email for certain payment methods. Pre-fill these fields to save customers time by setting `PaymentSheet.Configuration.defaultBillingDetails`.

#### Save payment methods on payment
> This is currently only available for cards + Apple/Google Pay.

PaymentSheet supports PaymentIntents with `setup_future_usage` set. This property tells us to save the payment method for future use (e.g., taking initial payment of a recurring subscription).
When set, PaymentSheet hides the 'Save this card for future use' checkbox and always saves.

#### SetupIntent support
> This is currently only available for cards + Apple/Google Pay.

Initialize PaymentSheet with a SetupIntent to set up cards for future use without charging.

#### Smart payment method ordering
When a customer is adding a new payment method, PaymentSheet uses information like the customers region to show the most relevant payment methods first.

#### Other changes
* Postal code collection for cards is now limited to US, CA, UK
* Fixed SwiftUI memory leaks [Issue #1881](https://github.com/stripe/stripe-ios/issues/1881)
* Added "hint" for error messages
* Adds many new localizations. The SDK now localizes in the following languages: bg-BG,ca-ES,cs-CZ,da,de,el-GR,en-GB,es-419,es,et-EE,fi,fil,fr-CA,fr,hr,hu,id,it,ja,ko,lt-LT,lv-LV,ms-MY,mt,nb,nl,nn-NO,pl-PL,pt-BR,pt-PT,ro-RO,ru,sk-SK,sl-SI,sv,tk,tr,vi,zh-Hans,zh-Hant,zh-HK
* `Stripe` and `StripeIdentity` now require `StripeUICore`. See `MIGRATING.md` for more info.

## 21.8.1 2021-08-10
* Fixes an issue with image loading when using Swift Package Manager.
* Temporarily disabled WeChat Pay support in PaymentMethods.
* The `Stripe` module now requires `StripeCore`. See `MIGRATING.md` for more info.

## 21.8.0 2021-08-04
* Fixes broken card scanning links. (Thanks [ricsantos](https://github.com/ricsantos))
* Fixes accessibilityLabel for postal code field. (Thanks [romanilchyshyndepop](https://github.com/romanilchyshyndepop))
* Improves compile time by 30% [#1846](https://github.com/stripe/stripe-ios/pull/1846) (Thanks [JonathanDowning](https://github.com/JonathanDowning)!)
* Releasing `StripeIdentity` iOS SDK for use with [Stripe Identity](https://stripe.com/identity).

## 21.7.0 2021-07-07
* Fixes an issue with `additionaDocument` field typo [#1833](https://github.com/stripe/stripe-ios/issues/1833)
* Adds support for WeChat Pay to PaymentMethods
* Weak-links SwiftUI [#1828](https://github.com/stripe/stripe-ios/issues/1828)
* Adds 3DS2 support for Cartes Bancaires
* Fixes an issue with camera rotation during card scanning on iPad
* Fixes an issue where PaymentSheet could cause conflicts when included in an app that also includes PanModal [#1818](https://github.com/stripe/stripe-ios/issues/1818)
* Fixes an issue with building on Xcode 13 [#1822](https://github.com/stripe/stripe-ios/issues/1822)
* Fixes an issue where overriding STPPaymentCardTextField's `brandImage()` func had no effect [#1827](https://github.com/stripe/stripe-ios/issues/1827)
* Fixes documentation typo. (Thanks [iAugux](https://github.com/iAugux))

## 21.6.0 2021-05-27
* Adds `STPCardFormView`, a UI component that collects card details
* Adds 'STPRadarSession'. Note this requires additional Stripe permissions to use.

## 21.5.1 2021-05-07
* Fixes the `PaymentSheet` API not being public.
* Fixes an issue with missing headers. (Thanks [jctrouble](https://github.com/jctrouble)!)

## 21.5.0 2021-05-06
* Adds the `PaymentSheet`(https://stripe.dev/stripe-ios/docs/Classes/PaymentSheet.html) API, a prebuilt payment UI.
* Fixes Mac Catalyst support in Xcode 12.5 [#1797](https://github.com/stripe/stripe-ios/issues/1797)
* Fixes `STPPaymentCardTextField` not being open [#1768](https://github.com/stripe/stripe-ios/issues/1797)

## 21.4.0 2021-04-08
* Fixed warnings in Xcode 12.5. [#1772](https://github.com/stripe/stripe-ios/issues/1772)
* Fixes a layout issue when confirming payments in SwiftUI. [#1761](https://github.com/stripe/stripe-ios/issues/1761) (Thanks [mvarie](https://github.com/mvarie)!)
* Fixes a potential race condition when finalizing 3DS2 confirmations.
* Fixes an issue where a 3DS2 transaction could result in an incorrect error message when the card number is incorrect. [#1778](https://github.com/stripe/stripe-ios/issues/1778)
* Fixes an issue where `STPPaymentHandler.shared().handleNextAction` sometimes didn't return a `handleActionError`. [#1769](https://github.com/stripe/stripe-ios/issues/1769)
* Fixes a layout issue when confirming payments in SwiftUI. [#1761](https://github.com/stripe/stripe-ios/issues/1761) (Thanks [mvarie](https://github.com/mvarie)!)
* Fixes an issue with opening URLs on Mac Catalyst
* Fixes an issue where OXXO next action is mistaken for a cancel in STPPaymentHandler
* SetupIntents for iDEAL, Bancontact, EPS, and Sofort will now send the required mandate information.
* Adds support for BLIK.
* Adds `decline_code` information to STPError. [#1755](https://github.com/stripe/stripe-ios/issues/1755)
* Adds support for SetupIntents to STPApplePayContext
* Allows STPPaymentCardTextField to be subclassed. [#1768](https://github.com/stripe/stripe-ios/issues/1768)

## 21.3.1 2021-03-25
* Adds support for Maestro in Apple Pay on iOS 12 or later.

## 21.3.0 2021-02-18
* Adds support for SwiftUI in custom integration using the `STPPaymentCardTextField.Representable` View and the `.paymentConfirmationSheet()` ViewModifier. See `IntegrationTester` for usage examples.
* Removes the UIViewController requirement from STPApplePayContext, allowing it to be used in SwiftUI.
* Fixes an issue where `STPPaymentOptionsViewController` could fail to register a card. [#1758](https://github.com/stripe/stripe-ios/issues/1758)
* Fixes an issue where some UnionPay test cards were marked as invalid. [#1759](https://github.com/stripe/stripe-ios/issues/1759)
* Updates tests to run on Carthage 0.37 with .xcframeworks.


## 21.2.1 2021-01-29
* Fixed an issue where a payment card text field could resize incorrectly on smaller devices or with certain languages. [#1600](https://github.com/stripe/stripe-ios/issues/1600)
* Fixed an issue where the SDK could always return English strings in certain situations. [#1677](https://github.com/stripe/stripe-ios/pull/1677) (Thanks [glaures-ioki](https://github.com/glaures-ioki)!)
* Fixed an issue where an STPTheme had no effect on the navigation bar. [#1753](https://github.com/stripe/stripe-ios/pull/1753) (Thanks  [@rbenna](https://github.com/rbenna)!)
* Fixed handling of nil region codes. [#1752](https://github.com/stripe/stripe-ios/issues/1752)
* Fixed an issue preventing card scanning from being disabled. [#1751](https://github.com/stripe/stripe-ios/issues/1751)
* Fixed an issue with enabling card scanning in an app with a localized Info.plist.[#1745](https://github.com/stripe/stripe-ios/issues/1745)
* Added a missing additionalDocument parameter to STPConnectAccountIndividualVerification.
* Added support for Afterpay/Clearpay.

## 21.2.0 2021-01-06
* Stripe3DS2 is now open source software under the MIT License.
* Fixed various issues with bundling Stripe3DS2 in Cocoapods and Swift Package Manager. All binary dependencies have been removed.
* Fixed an infinite loop during layout on small screen sizes. [#1731](https://github.com/stripe/stripe-ios/issues/1731)
* Fixed issues with missing image assets when using Cocoapods. [#1655](https://github.com/stripe/stripe-ios/issues/1655) [#1722](https://github.com/stripe/stripe-ios/issues/1722)
* Fixed an issue which resulted in unnecessary queries to the BIN information service.
* Adds the ability to `attach` and `detach` PaymentMethod IDs to/from a CustomerContext. [#1729](https://github.com/stripe/stripe-ios/issues/1729)
* Adds support for NetBanking.

## 21.1.0 2020-12-07
* Fixes a crash during manual confirmation of a 3DS2 payment. [#1725](https://github.com/stripe/stripe-ios/issues/1725)
* Fixes an issue that could cause some image assets to be missing in certain configurations. [#1722](https://github.com/stripe/stripe-ios/issues/1722)
* Fixes an issue with confirming Alipay transactions.
* Re-exposes `cardNumber` parameter in `STPPaymentCardTextField`.
* Adds support for UPI.

## 21.0.1 2020-11-19
* Fixes an issue with some initializers not being exposed publicly following the [conversion to Swift](https://stripe.com/docs/mobile/ios/sdk-21-migration).
* Updates GrabPay integration to support synchronous updates.

## 21.0.0 2020-11-18
* The SDK is now written in Swift, and some manual changes are required. Migration instructions are available at [https://stripe.com/docs/mobile/ios/sdk-21-migration](https://stripe.com/docs/mobile/ios/sdk-21-migration).
* Adds full support for Apple silicon.
* Xcode 12.2 is now required.

## 20.1.1 2020-10-23
* Fixes an issue when using Cocoapods 1.10 and Xcode 12. [#1683](https://github.com/stripe/stripe-ios/pull/1683)
* Fixes a warning when using Swift Package Manager. [#1675](https://github.com/stripe/stripe-ios/pull/1675)

## 20.1.0 2020-10-15
* Adds support for OXXO. [#1592](https://github.com/stripe/stripe-ios/pull/1592)
* Applies a workaround for various bugs in Swift Package Manager. [#1671](https://github.com/stripe/stripe-ios/pull/1671) Please see [#1673](https://github.com/stripe/stripe-ios/issues/1673) for additional notes when using Xcode 12.0.
* Card scanning now works when the device's orientation is unknown. [#1659](https://github.com/stripe/stripe-ios/issues/1659)
* The expiration date field's Simplified Chinese localization has been corrected. (Thanks [cythb](https://github.com/cythb)!) [#1654](https://github.com/stripe/stripe-ios/pull/1654)

## 20.0.0 2020-09-14
* [Card scanning](https://github.com/stripe/stripe-ios#card-scanning) is now built into STPAddCardViewController. Card.io support has been removed. [#1629](https://github.com/stripe/stripe-ios/pull/1629)
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

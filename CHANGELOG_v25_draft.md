## 25.0.0 2025-XX-YY
This major version introduces many small breaking changes. Please see [MIGRATING.md](https://github.com/stripe/stripe-ios/blob/master/MIGRATING.md) to help you migrate.

### All
* [Added] You can now access the HTTP status code of failed API requests by inspecting `userInfo[STPError.httpStatusCodeKey]` on the error.
* [Added] You can now access the Stripe request ID of failed API requests by inspecting `userInfo[STPError.stripeRequestIDKey]` on the error.
* [Changed] Most delegate protocols are now marked as `@MainActor @preconcurrency` to improve support for Swift strict concurrency. This includes: `STPApplePayContextDelegate`, `STPAuthenticationContext`, `STPPaymentCardTextFieldDelegate`, `STPCardFormViewDelegate`, `AddressViewControllerDelegate`, and `STPAUBECSDebitFormViewDelegate`.

### PaymentSheet
* [Fixed] PaymentSheet, PaymentSheet.FlowController, and EmbeddedPaymentElement return errors when loading with invalid configuration instead of loading in a degraded state.
* [Added] Added async versions of all completion-block-based PaymentSheet and PaymentSheet.FlowController methods.
* [Changed] Replaces `ExternalPaymentMethodConfirmHandler` with an async equivalent.
* [Changed] Replaced `IntentConfiguration.ConfirmHandler` with an async equivalent.
* [Changed] Replaces `PaymentSheet.ApplePayConfiguration.Handlers` completion-block based `authorizationResultHandler` with an async equivalent.
* [Changed] CustomerSessions is now generally available.
* [Changed] ConfirmationTokens is now generally available.
* [Removed] Removed `PaymentSheet.reset()` in favor of `PaymentSheet.resetCustomer()`.

### Financial Connections
* [Added] Added an async versions of `present(from:)` and `presentForToken(from:)`.

### CustomerSheet
* [Added] Added an async version of `present(from:)`.
* [Changed] CustomerSessions is now generally available.

### STPApplePayContext
* [Added] Added async delegate methods.
* [Changed] Replaces the `ApplePayContextDelegate.didCreatePaymentMethod` method with an async version.

### Payments
* [Changed] `STPPaymentIntent.paymentMethodTypes` and `STPSetupIntent.paymentMethodTypes` now return `[STPPaymentMethodType]` instead of `[NSNumber]` in Swift for better ergonomics.
* [Changed] `STPSetupIntentConfirmParams.useStripeSDK` now uses `Bool?` instead of `NSNumber?` in Swift for better ergonomics.
* [Changed] Renamed STPPaymentHandler's `confirm` and `handleNextAction` methods and added async versions.
* [Removed] Removed `requiresSource` and `requiresSourceAction` statuses from `STPPaymentIntentStatus`. Also removed `STPPaymentIntentSourceActionType`.
* [Removed] Removed deprecated `STPPaymentIntentParams.saveSourceToCustomer` property. Use `savePaymentMethod` instead.


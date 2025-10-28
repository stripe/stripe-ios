## 25.0.0 2025-XX-YY
This major version introduces many small breaking changes. Please see [MIGRATING.md](https://github.com/stripe/stripe-ios/blob/master/MIGRATING.md) to help you migrate.

### Financial Connections
* [Added] Added an async versions of `present(from:)` and `presentForToken(from:)`.

### PaymentSheet
* [Changed] Replaces `ExternalPaymentMethodConfirmHandler` with an async equivalent.
* [Changed] Replaced `IntentConfiguration.ConfirmHandler` with an async equivalent.
* [Changed] Replaces `PaymentSheet.ApplePayConfiguration.Handlers` completion-block based `authorizationResultHandler` with an async equivalent.
* [Added] Added async versions of all completion-block-based PaymentSheet and PaymentSheet.FlowController methods.

### CustomerSheet
* [Added] Added an async version of `present(from:)`.

### STPApplePayContext
* [Added] Added async delegate methods.
* [Changed] Replaces the `ApplePayContextDelegate.didCreatePaymentMethod` method with an async version.


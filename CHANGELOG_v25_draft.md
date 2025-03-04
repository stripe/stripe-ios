## 25.0.0 2025-XX-YY
This major version introduces many small breaking changes. Please see [MIGRATING.md](https://github.com/stripe/stripe-ios/blob/master/MIGRATING.md) to help you migrate.

### PaymentSheet
* [Changed] Replaced `ExternalPaymentMethodConfirmHandler` with an async equivalent.
* [Changed] Replaced `IntentConfiguration.ConfirmHandler` with an async equivalent.
* [Added] Added async versions of all completion-block-based PaymentSheet and PaymentSheet.FlowController methods.

### CustomerSheet
* [Added] Added an async version of `present(from:)`.



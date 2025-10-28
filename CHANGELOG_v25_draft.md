## 25.0.0 2025-XX-YY
### Financial Connections
* [Added] Added an async versions of `present(from:)` and `presentForToken(from:)`.

### PaymentSheet
* [Changed] Replaces `PaymentSheet.ApplePayConfiguration.Handlers` completion-block based `authorizationResultHandler` with an async equivalent.
* [Removed] Removed `PaymentSheet.reset()` in favor of `PaymentSheet.resetCustomer()`.
* [Changed] CustomerSessions is now generally available.
* [Changed] ConfirmationTokens is now generally available.

### CustomerSheet
* [Changed] CustomerSessions is now generally available.

### STPApplePayContext
* [Added] Added async delegate methods.
* [Changed] Replaces the `ApplePayContextDelegate.didCreatePaymentMethod` method with an async version.

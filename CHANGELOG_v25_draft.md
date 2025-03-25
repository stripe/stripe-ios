### All
* [Changed] Most delegate protocols are now marked as `@MainActor @preconcurrency` to improve support for Swift strict concurrency. This includes: `STPApplePayContextDelegate`, `STPAuthenticationContext`, `STPPaymentCardTextFieldDelegate`, `STPCardFormViewDelegate`, `AddressViewControllerDelegate`, and `STPAUBECSDebitFormViewDelegate`.

### Financial Connections
* [Added] Added an async versions of `present(from:)` and `presentForToken(from:)`.

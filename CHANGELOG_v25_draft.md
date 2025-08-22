### All
* [Added] You can now access the HTTP status code of failed API requests by inspecting `userInfo[STPError.httpStatusCodeKey]` on the error.
* [Added] You can now access the Stripe request ID of failed API requests by inspecting `userInfo[STPError.stripeRequestIDKey]` on the error.

### PaymentSheet
* [Fixed] PaymentSheet, PaymentSheet.FlowController, and EmbeddedPaymentElement return errors when loading with invalid configuration instead of loading in a degraded state.

### Financial Connections
* [Added] Added an async versions of `present(from:)` and `presentForToken(from:)`.


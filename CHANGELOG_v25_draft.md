### Financial Connections
* [Added] Added an async versions of `present(from:)` and `presentForToken(from:)`.

### PaymentSheet
- **[Changed]** The `PaymentSheet` types used by Mobile Payment Element have moved:
  - **Top-level** if they can be used with other Stripe Elements:
    - `PaymentSheet.UserInterfaceStyle` → **`UserInterfaceStyle`**
    - `PaymentSheet.Address` → **`Address`**
    - `PaymentSheet.BillingDetails` → **`BillingDetails`**
    - `PaymentSheet.Appearance` → **`Appearance`**
  - A new **`PaymentElement`** namespace for Payment Element–specific usage:  
    - `PaymentSheet.IntentConfiguration` → **`PaymentElement.IntentConfiguration`**
    - `PaymentSheet.SavePaymentMethodOptInBehavior` → **`PaymentElement.SavePaymentMethodOptInBehavior`**
    - `PaymentSheet.ApplePayConfiguration` → **`PaymentElement.ApplePayConfiguration`**
    - `PaymentSheet.CustomerConfiguration` → **`PaymentElement.CustomerConfiguration`**
    - `PaymentSheet.BillingDetailsCollectionConfiguration` → **`PaymentElement.BillingDetailsCollectionConfiguration`**
    - `PaymentSheet.ExternalPaymentMethodConfiguration` → **`PaymentElement.ExternalPaymentMethodConfiguration`**
    - `PaymentSheet.CardBrandAcceptance` → **`PaymentElement.CardBrandAcceptance`**
    - `PaymentSheetResult` → **`PaymentElement.ConfirmationResult`**
  - The old `PaymentSheet` type references remain available as typealiases for backwards compatibility.

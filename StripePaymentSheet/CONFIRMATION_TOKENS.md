# ConfirmationTokens for PaymentSheet (iOS)

ConfirmationTokens help transport client-side data collected by PaymentSheet to your server for confirming a PaymentIntent or SetupIntent. With ConfirmationTokens, PaymentSheet creates a token that encapsulates the buyer’s selected payment method details and optional shipping/return URL. Your server uses this token to confirm the intent.

This guide describes the iOS PaymentSheet API for ConfirmationTokens, how to integrate with both `PaymentSheet` and `PaymentSheet.FlowController`, and how to migrate from the legacy server-side confirmation callback that passed a `STPPaymentMethod`.

> Note
> This flow is intended for two-step confirmation experiences (review pages, business-rule checks) and for merchants migrating away from directly passing `PaymentMethod` IDs to their servers.

## Table of contents
<!-- NOTE: Use case-sensitive anchor links for docc compatibility -->
<!--ts-->
* [Overview](#Overview)
* [Requirements](#Requirements)
* [API surface](#API-surface)
  * [PaymentSheet.IntentConfiguration](#PaymentSheetIntentConfiguration)
  * [PaymentSheet.FlowController](#PaymentSheetFlowController)
  * [STPConfirmationToken](#STPConfirmationToken)
* [Integration](#Integration)
  * [PaymentSheet](#PaymentSheet)
  * [PaymentSheet.FlowController](#PaymentSheetFlowController-integration)
  * [Collecting shipping and return URL](#Collecting-shipping-and-return-URL)
* [Server examples](#Server-examples)
  * [PaymentIntent confirmation](#PaymentIntent-confirmation)
  * [SetupIntent confirmation](#SetupIntent-confirmation)
* [Migration](#Migration)
  * [From PaymentMethod-based confirm handler](#From-PaymentMethod-based-confirm-handler)
  * [Conditional setup_future_usage and capture_method](#Conditional-setup_future_usage-and-capture_method)
* [Limitations and notes](#Limitations-and-notes)
<!--te-->

## Overview

- Use PaymentSheet to collect payment details.
- PaymentSheet creates a ConfirmationToken on-device.
- Your app receives the ConfirmationToken ID and sends it to your server.
- Your server creates and confirms the intent using `confirmation_token`.
- If your server returns the intent’s client secret immediately, PaymentSheet can complete next actions in-app.

## Requirements

- iOS 13+
- Stripe iOS SDK `StripePaymentSheet`
- A backend server using Stripe’s official libraries

## API surface

### PaymentSheet.IntentConfiguration

Add a new confirmation handler variant that provides a `STPConfirmationToken` (instead of a `STPPaymentMethod`) for server-side confirmation.

```swift
/// Called when the buyer taps the pay/continue button.
/// Provide `confirmationToken` to your server to create & confirm an intent.
public typealias ConfirmationTokenConfirmHandler = (
    _ confirmationToken: STPConfirmationToken,
    _ shouldSavePaymentMethod: Bool,
    _ intentCreationCallback: @escaping (Result<String, Error>) -> Void
) -> Void

public struct IntentConfiguration {
    public init(
        mode: Mode,
        confirmHandler: @escaping ConfirmationTokenConfirmHandler
    )
}
```

- `confirmationToken`: Encapsulates payment method input and optional shipping/return URL.
- `shouldSavePaymentMethod`: Reflects the buyer’s choice to save their details.
- `intentCreationCallback`: Call with the intent client secret (string) if you confirm immediately on your server. If you show a review page and defer confirmation, call back later once the intent is created and confirmed.

### PaymentSheet.FlowController

FlowController exposes the same ConfirmationToken-based callback.

```swift
public final class PaymentSheetFlowController {
    public convenience init(
        intentConfiguration: PaymentSheet.IntentConfiguration,
        configuration: PaymentSheet.Configuration,
        completion: @escaping (Result<PaymentSheetFlowController, Error>) -> Void
    )

    // Internally, FlowController will invoke the same ConfirmationTokenConfirmHandler
    // when you call `confirm`.
}
```

Usage mirrors PaymentSheet’s integration; see examples below.

### STPConfirmationToken

A lightweight representation of the created ConfirmationToken.

Public definition (mirrors the ConfirmationToken API fields):

```swift
public final class STPConfirmationToken: NSObject {
    /// id — Unique identifier for the object (e.g. `ct_...`).
    public let stripeId: String

    /// object — String representing the object’s type. Always `"confirmation_token"`.
    public let object: String

    /// created — Time at which the object was created.
    public let created: Date

    /// expires_at — Time at which this ConfirmationToken expires.
    public let expiresAt: Date?

    /// livemode — True in live mode; false in test mode.
    public let livemode: Bool

    /// mandate_data — Data used for generating a Mandate.
    public let mandateData: STPConfirmationToken.MandateData?

    /// payment_intent — ID of the PaymentIntent this token was used to confirm.
    public let paymentIntentId: String?

    /// setup_intent — ID of the SetupIntent this token was used to confirm.
    public let setupIntentId: String?

    /// payment_method_options — Payment-method-specific configuration captured on the token.
    public let paymentMethodOptions: STPConfirmationToken.PaymentMethodOptions?

    /// payment_method_preview — Non-PII preview of payment details captured by the Payment Element.
    public let paymentMethodPreview: STPConfirmationToken.PaymentMethodPreview?

    /// return_url — Return URL used to confirm the intent for redirect-based methods.
    public let returnURL: String?

    /// setup_future_usage — Indicates intent to reuse the payment method.
    public let setupFutureUsage: STPIntentFutureUsage?

    /// shipping — Shipping information collected on this token.
    public let shipping: STPPaymentIntentShippingDetails?

    /// use_stripe_sdk — Indicates whether Stripe SDK is used to handle confirmation flow.
    public let useStripeSDK: Bool

    /// payment_method — ID of the PaymentMethod created upon confirmation (if available).
    public let paymentMethodId: String?
}
```

Nested types:

```swift
extension STPConfirmationToken {
    // MARK: - Mandate data
    public struct MandateData: Equatable {
        public let customerAcceptance: MandateCustomerAcceptance
    }

    public struct MandateCustomerAcceptance: Equatable {
        /// The type of customer acceptance information.
        public let type: String
        /// Online acceptance details if accepted online.
        public let online: MandateOnline?
    }

    public struct MandateOnline: Equatable {
        public let ipAddress: String?
        public let userAgent: String?
    }

    // MARK: - Payment method options
    public struct PaymentMethodOptions: Equatable {
        public let card: CardOptions?
    }

    public struct CardOptions: Equatable {
        public let cvcToken: String?
        public let installments: CardInstallments?
    }

    public struct CardInstallments: Equatable {
        public let plan: CardInstallmentsPlan?
    }

    public struct CardInstallmentsPlan: Equatable {
        public enum Interval: String { case month }
        public enum PlanType: String { case fixedCount = "fixed_count", bonus, revolving }
        public let count: Int?
        public let interval: Interval?
        public let type: PlanType
    }

    // MARK: - Payment method preview
    /// Mirrors the `payment_method_preview` object. Exposes top-level fields with
    /// a raw `details` dictionary to preserve future fields without SDK updates.
    public struct PaymentMethodPreview: Equatable {
        public let type: STPPaymentMethodType
        public let billingDetails: STPPaymentMethodBillingDetails?
        /// Per-payment-method-type details, exactly as returned by the API.
        public let details: [String: Any]
    }
}
```

> Note
> `STPConfirmationToken` is a client-side wrapper. The canonical object lives on your server via the Stripe API.

## Integration

### PaymentSheet

```swift
import StripePaymentSheet

final class CheckoutViewController: UIViewController {
    private var paymentSheet: PaymentSheet!

    func presentPayment() {
        var config = PaymentSheet.Configuration()
        config.returnURL = "your-app://stripe-redirect"

        let intentConfig = PaymentSheet.IntentConfiguration(
            mode: .payment(amount: 1099, currency: "USD")
        ) { confirmationToken, shouldSave, intentCreationCallback in
            // 1) Send the ConfirmationToken to your server to create & confirm the intent
            MyAPI.createAndConfirmPaymentIntent(
                amount: 1099,
                currency: "usd",
                confirmationTokenId: confirmationToken.stripeId,
                shouldSavePaymentMethod: shouldSave
            ) { result in
                // 2) Return the PaymentIntent client secret so PaymentSheet can handle next actions
                intentCreationCallback(result)
            }
        }

        paymentSheet = PaymentSheet(intentConfiguration: intentConfig, configuration: config)
        paymentSheet.present(from: self) { result in
            switch result {
            case .completed:
                // Show confirmation
                break
            case .canceled:
                break
            case .failed(let error):
                print(error)
            }
        }
    }
}
```

### PaymentSheet.FlowController integration

```swift
import StripePaymentSheet

final class FlowControllerCheckoutVC: UIViewController {
    private var flowController: PaymentSheetFlowController!

    func load() {
        var config = PaymentSheet.Configuration()
        config.returnURL = "your-app://stripe-redirect"

        let intentConfig = PaymentSheet.IntentConfiguration(
            mode: .payment(amount: 1099, currency: "USD")
        ) { confirmationToken, shouldSave, intentCreationCallback in
            MyAPI.createAndConfirmPaymentIntent(
                amount: 1099,
                currency: "usd",
                confirmationTokenId: confirmationToken.stripeId,
                shouldSavePaymentMethod: shouldSave
            ) { result in
                intentCreationCallback(result)
            }
        }

        PaymentSheet.FlowController.create(
            intentConfiguration: intentConfig,
            configuration: config
        ) { result in
            switch result {
            case .success(let controller):
                self.flowController = controller
                // Show your own UI; later call `confirm`.
            case .failure(let error):
                print(error)
            }
        }
    }

    func didTapPayButton(presentingVC: UIViewController) {
        flowController.confirm(from: presentingVC) { result in
            // Handle completion/cancellation/error
        }
    }
}
```

### Collecting shipping and return URL

- If you set `configuration.returnURL`, PaymentSheet writes the return URL to the ConfirmationToken so your server doesn’t need to provide it again.
- If you enable shipping collection in PaymentSheet (via your own UI or Address Element integration) and pass it to PaymentSheet, shipping is written to the ConfirmationToken and applied on confirmation.

## Server examples

> Important
> When confirming using a ConfirmationToken, provide `use_stripe_sdk: true` and set `automatic_payment_methods` according to your integration. If you already included `return_url` and `shipping` on the token, you do not need to include them again on the intent.

### PaymentIntent confirmation

Node (Express)

```javascript
app.post('/create-confirm-intent', async (req, res) => {
  try {
    const intent = await stripe.paymentIntents.create({
      confirm: true,
      amount: 1099,
      currency: 'usd',
      automatic_payment_methods: { enabled: true },
      use_stripe_sdk: true,
      confirmation_token: req.body.confirmationTokenId,
    });
    res.json({ client_secret: intent.client_secret, status: intent.status });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});
```

Ruby

```ruby
post '/create-confirm-intent' do
  intent = Stripe::PaymentIntent.create({
    confirm: true,
    amount: 1099,
    currency: 'usd',
    automatic_payment_methods: { enabled: true },
    use_stripe_sdk: true,
    confirmation_token: params[:confirmation_token_id],
  })
  { client_secret: intent.client_secret, status: intent.status }.to_json
end
```

Python (Flask)

```python
@app.route('/create-confirm-intent', methods=['POST'])
def create_confirm_intent():
  intent = stripe.PaymentIntent.create(
    confirm=True,
    amount=1099,
    currency='usd',
    automatic_payment_methods={ 'enabled': True },
    use_stripe_sdk=True,
    confirmation_token=request.json['confirmationTokenId'],
  )
  return jsonify(client_secret=intent.client_secret, status=intent.status)
```

### SetupIntent confirmation

Node

```javascript
app.post('/create-confirm-setup-intent', async (req, res) => {
  try {
    const si = await stripe.setupIntents.create({
      confirm: true,
      automatic_payment_methods: { enabled: true },
      use_stripe_sdk: true,
      confirmation_token: req.body.confirmationTokenId,
    });
    res.json({ client_secret: si.client_secret, status: si.status });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});
```

## Migration

### From PaymentMethod-based confirm handler

Before (legacy):

```swift
let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1099, currency: "USD")) { paymentMethod, shouldSave, intentCreationCallback in
    MyAPI.createAndConfirmPaymentIntent(
        paymentMethodId: paymentMethod.stripeId,
        shouldSavePaymentMethod: shouldSave
    ) { result in
        intentCreationCallback(result)
    }
}
```

After (ConfirmationTokens):

```swift
let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1099, currency: "USD")) { confirmationToken, shouldSave, intentCreationCallback in
    MyAPI.createAndConfirmPaymentIntent(
        confirmationTokenId: confirmationToken.stripeId,
        shouldSavePaymentMethod: shouldSave
    ) { result in
        intentCreationCallback(result)
    }
}
```

Key differences:
- No `stripe.createPaymentMethod` usage—PaymentSheet creates a ConfirmationToken for you.
- Shipping and `return_url` can be embedded in the token.
- Server confirms with `confirmation_token` instead of `payment_method`.

### Conditional `setup_future_usage` and `capture_method`

When migrating, do not set `setup_future_usage` or `capture_method` globally if you need per-payment-method behavior. Instead, use `payment_method_options[pm_type][setup_future_usage|capture_method]` on the intent.

Example:

```javascript
stripe.paymentIntents.create({
  amount: 100,
  currency: 'usd',
  payment_method_options: {
    card: { setup_future_usage: 'off_session', capture_method: 'manual' },
    ideal: { setup_future_usage: 'off_session' }
  }
});
```

## Limitations and notes

- This path does not support certain regional methods such as BLIK or ACSS pre-authorized debits.
- Always run server-side validations just before confirmation to ensure price integrity and inventory checks.
- For wallet or redirect-based methods, set a `return_url`. If provided via PaymentSheet configuration, it will be included on the ConfirmationToken.
- If you defer intent creation until after a review page, hold the `confirmationTokenId` and call your server when the buyer confirms. Then return the intent client secret to PaymentSheet so it can complete any next actions.

---

For more on designing your integration, see the PaymentSheet module README and the SDK reference.
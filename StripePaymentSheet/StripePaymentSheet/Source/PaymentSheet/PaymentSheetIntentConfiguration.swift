//
//  PaymentSheetIntentConfiguration.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 2/16/23.
//

import Foundation

public extension PaymentSheet {
    /// Contains information needed to render PaymentSheet
    /// The values are used to calculate the payment methods displayed and influence the UI.
    /// - Note: The PaymentIntent or SetupIntent you create on your server must have the same values or the payment/setup will fail.
    /// - Seealso: https://stripe.com/docs/payments/finalize-payments-on-the-server
    struct IntentConfiguration {

        /// Pass this into `intentCreationCallback` to force PaymentSheet to show success, dismiss the sheet, and return a PaymentSheetResult of `completed`.
        /// - Note: ⚠️ If provided, the SDK performs no action to complete the payment or setup - it doesn't confirm a PaymentIntent or SetupIntent or handle next actions.
        ///   You should only use this if your integration can't create a PaymentIntent or SetupIntent. It is your responsibility to ensure that you only pass this value if the payment or set up is successful. 
        @_spi(PaymentSheetSkipConfirmation) public static let COMPLETE_WITHOUT_CONFIRMING_INTENT = "COMPLETE_WITHOUT_CONFIRMING_INTENT"

        /// Called when the customer confirms payment.
        /// Your implementation should follow the [guide](https://stripe.com/docs/payments/finalize-payments-on-the-server) to create (and optionally confirm) PaymentIntent or SetupIntent on your server and call the `intentCreationCallback` with its client secret or an error if one occurred.
        /// - Note: You must create the PaymentIntent or SetupIntent with the same values used as the `IntentConfiguration` e.g. the same amount, currency, etc.
        /// - Parameters:
        ///   - paymentMethod: The `STPPaymentMethod` representing the customer's payment details.
        ///   If your server needs the payment method, send `paymentMethod.stripeId` to your server and have it fetch the PaymentMethod object. Otherwise, you can ignore this. Don't send other properties besides the ID to your server.
        ///   - shouldSavePaymentMethod: This is `true` if the customer selected the "Save this payment method for future use" checkbox.
        ///     If you confirm the PaymentIntent on your server, set `setup_future_usage` on the PaymentIntent to `off_session` if this is `true`. Otherwise, ignore this parameter.
        ///   - intentCreationCallback: Call this with the `client_secret` of the PaymentIntent or SetupIntent created by your server or the error that occurred. If you're using PaymentSheet, the error's localizedDescription will be displayed to the customer in the sheet. If you're using PaymentSheet.FlowController, the `confirm` method fails with the error.
        public typealias ConfirmHandler = (
            _ paymentMethod: STPPaymentMethod,
            _ shouldSavePaymentMethod: Bool,
            _ intentCreationCallback: @escaping ((Result<String, Error>) -> Void)
        ) -> Void

        /// Creates a `PaymentSheet.IntentConfiguration` with the given values
        /// - Parameters:
        ///   - mode: The mode of this intent, either payment or setup
        ///   - paymentMethodTypes: The payment method types for the intent
        ///   - onBehalfOf: The account (if any) for which the funds of the intent are intended
        ///   - paymentMethodConfigurationId: Configuration ID (if any) for the selected payment method configuration
        ///   - confirmHandler: A handler called with payment details when the user taps the primary button (e.g. the "Pay" or "Continue" button).
        ///   - requireCVCRecollection: If true, PaymentSheet recollects CVC for saved cards before confirmation (PaymentIntent only)
        public init(mode: Mode,
                    paymentMethodTypes: [String]? = nil,
                    onBehalfOf: String? = nil,
                    paymentMethodConfigurationId: String? = nil,
                    confirmHandler: @escaping ConfirmHandler,
                    requireCVCRecollection: Bool = false) {
            self.mode = mode
            self.paymentMethodTypes = paymentMethodTypes
            self.onBehalfOf = onBehalfOf
            self.paymentMethodConfigurationId = paymentMethodConfigurationId
            self.confirmHandler = confirmHandler
            self.requireCVCRecollection = requireCVCRecollection
            validate()
        }

        /// Information about the payment (PaymentIntent) or setup (SetupIntent).
        public var mode: Mode {
            didSet { validate() }
        }

        /// A list of payment method types to display to the customer. If nil, we dynamically determine the payment methods using your Stripe Dashboard settings.
        public var paymentMethodTypes: [String]?

        /// Called when the customer confirms payment.
        /// See the documentation for `ConfirmHandler` for more details.
        public var confirmHandler: ConfirmHandler

        /// The account (if any) for which the funds of the intent are intended.
        /// - Seealso: https://stripe.com/docs/api/payment_intents/object#payment_intent_object-on_behalf_of
        public var onBehalfOf: String?

        /// Optional configuration ID for the selected payment method configuration.
        /// See https://stripe.com/docs/payments/multiple-payment-method-configs for more information.
        public var paymentMethodConfigurationId: String?

        /// If true, PaymentSheet recollects CVC for saved cards before confirmation (PaymentIntents only)
        ///  - Seealso: https://docs.stripe.com/payments/accept-a-payment-deferred?platform=ios&type=payment#ios-cvc-recollection
        ///  - Note: Server-side confirmation is not supported.
        public var requireCVCRecollection: Bool

        /// Controls when the funds will be captured. 
        /// - Seealso: https://stripe.com/docs/api/payment_intents/create#create_payment_intent-capture_method
        public enum CaptureMethod: String {
            /// (Default) Stripe automatically captures funds when the customer authorizes the payment.
            case automatic = "automatic"

            /// Place a hold on the funds when the customer authorizes the payment, but don’t capture the funds until later. (Not all payment methods support this.)
            case manual = "manual"

            /// Asynchronously capture funds when the customer authorizes the payment.
            /// - Note: Recommended over `CaptureMethod.automatic` due to improved latency, but may require additional integration changes.
            /// - Seealso: https://stripe.com/docs/payments/payment-intents/asynchronous-capture-automatic-async
            case automaticAsync = "automatic_async"
        }

        /// Indicates that you intend to make future payments with this PaymentIntent’s payment method.
        /// - Seealso: https://stripe.com/docs/api/payment_intents/create#create_payment_intent-setup_future_usage
        public enum SetupFutureUsage: String {
            /// Use off_session if your customer may or may not be present in your checkout flow.
            case offSession = "off_session"

            /// Use this if you intend to only reuse the payment method when your customer is present in your checkout flow.
            case onSession = "on_session"

            /// Use this if you do not intend to reuse this payment method and want to override the top-level setup_future_usage value for this payment method.
            @_spi(PaymentMethodOptionsSetupFutureUsagePreview) case none = "none"
        }

        /// Additional information about the payment or setup
        public enum Mode {
            /// Payment method options
            public struct PaymentMethodOptions {
                var setupFutureUsageValues: [STPPaymentMethodType: SetupFutureUsage]?

                @_spi(PaymentMethodOptionsSetupFutureUsagePreview) public init(setupFutureUsageValues: [STPPaymentMethodType: SetupFutureUsage]? = nil) {
                    self.setupFutureUsageValues = setupFutureUsageValues
                }
            }

            /// Use this if your integration creates a PaymentIntent
            case payment(
                /// Amount intended to be collected in the smallest currency unit (e.g. 100 cents to charge $1.00). Shown in Apple Pay, Buy now pay later UIs, the Pay button, and influences available payment methods.
                /// - Seealso: https://stripe.com/docs/api/payment_intents/create#create_payment_intent-amount
                amount: Int,
                /// Three-letter ISO currency code. Filters out payment methods based on supported currency.
                /// - Seealso: https://stripe.com/docs/api/payment_intents/create#create_payment_intent-currency
                currency: String,
                /// Indicates that you intend to make future payments.
                /// - Seealso: https://stripe.com/docs/api/payment_intents/create#create_payment_intent-setup_future_usage
                setupFutureUsage: SetupFutureUsage? = nil,
                /// - Seealso: https://stripe.com/docs/api/payment_intents/create#create_payment_intent-capture_method
                captureMethod: CaptureMethod = .automatic,
                /// Additional payment method options params
                /// - Seealso: https://docs.stripe.com/api/payment_intents/create#create_payment_intent-payment_method_options
                paymentMethodOptions: PaymentMethodOptions? = nil

            )
            /// Use this if your integration creates a SetupIntent
            case setup(
                /// Three-letter ISO currency code. Optional - setting this ensures only valid payment methods are displayed.
                currency: String? = nil,
                /// Indicates how the payment method is intended to be used in the future.
                /// - Seealso: https://stripe.com/docs/api/setup_intents/create#create_setup_intent-usage
                setupFutureUsage: SetupFutureUsage = .offSession
            )
        }

        // MARK: - Internal

        /// An async version of `ConfirmHandler`.
        typealias AsyncConfirmHandler = (
            _ paymentMethod: STPPaymentMethod,
            _ shouldSavePaymentMethod: Bool
        ) async throws -> String

        /// An async version of the initializer. See the other initializer for documentation.
        init(
            mode: Mode,
            paymentMethodTypes: [String]? = nil,
            onBehalfOf: String? = nil,
            confirmHandler2: @escaping AsyncConfirmHandler
        ) {
            self.mode = mode
            self.paymentMethodTypes = paymentMethodTypes
            self.onBehalfOf = onBehalfOf
            self.confirmHandler = { paymentMethod, shouldSavePaymentMethod, callback in
                Task {
                    do {
                        let clientSecret = try await confirmHandler2(paymentMethod, shouldSavePaymentMethod)
                        callback(.success(clientSecret))
                    } catch {
                        callback(.failure(error))
                    }
                }
            }
            // TODO
            self.requireCVCRecollection = false
        }

        @discardableResult
        func validate() -> Error? {
            let errorMessage: String
            if case .payment(let amount, _, _, _, _) = mode, amount <= 0 {
                errorMessage = "The amount in `PaymentSheet.IntentConfiguration` must be non-zero! See https://docs.stripe.com/api/payment_intents/create#create_payment_intent-amount"
                return PaymentSheetError.intentConfigurationValidationFailed(message: errorMessage)
            }
            return nil
        }
    }
}

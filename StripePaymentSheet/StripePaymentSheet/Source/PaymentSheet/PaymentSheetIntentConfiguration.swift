//
//  PaymentSheetIntentConfiguration.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 2/16/23.
//

import Foundation

@_spi(ExperimentalPaymentSheetDecouplingAPI) public extension PaymentSheet {
    /// 🚧 Under construction
    /// Contains information needed to render PaymentSheet
    /// The values are used to calculate the payment methods displayed and influence the UI.
    /// - Note: The PaymentIntent or SetupIntent you create on your server must have the same values or the payment/setup will fail.
    struct IntentConfiguration {

        /// Called when the customer confirms payment.
        /// Your implementation should create a PaymentIntent or SetupIntent on your server and call the `intentCreationCallback` with its client secret or an error if one occurred.
        /// - Note: You must create the PaymentIntent or SetupIntent with the same values used as the `IntentConfiguration` e.g. the same amount, currency, etc.
        /// - Parameters:
        ///   - paymentMethodId: The id of the PaymentMethod representing the customer's payment details.
        ///     If you need to inspect payment method details, you can fetch the PaymentMethod object using this id on your server. Otherwise, you can ignore this.
        ///   - intentCreationCallback: Call this with the `client_secret` of the PaymentIntent or SetupIntent created by your server or the error that occurred. If you're using PaymentSheet, the error's localizedDescription will be displayed to the customer in the sheet. If you're using PaymentSheet.FlowController, the `confirm` method fails with the error.
        public typealias ConfirmHandler = (
            _ paymentMethodID: String,
            _ intentCreationCallback: @escaping ((Result<String, Error>) -> Void)
        ) -> Void

        /// For advanced users who need server-side confirmation.
        /// Called when the customer confirms payment.
        /// Your implementation should create and confirm a PaymentIntent or SetupIntent on your server and call the `intentCreationCallback` with its client secret or an error if one occurred.
        /// - Note: You must create the PaymentIntent or SetupIntent with the same values used as the `IntentConfiguration` e.g. the same amount, currency, etc.
        /// - Parameters:
        ///   - paymentMethodId: The id of the PaymentMethod representing the customer's payment details.
        ///     If you need to inspect payment method details, you can fetch the PaymentMethod object using this id on your server. Otherwise, you can ignore this.
        ///   - shouldSavePaymentMethod: This is `true` if the customer selected the "Save this payment method for future use" checkbox.
        ///     Set `setup_future_usage` on the PaymentIntent to `off_session` if this is `true`.
        ///   - intentCreationCallback: Call this with the `client_secret` of the PaymentIntent or SetupIntent created by your server or the error that occurred. If you're using PaymentSheet, the error's localizedDescription will be displayed to the customer in the sheet. If you're using PaymentSheet.FlowController, the `confirm` method fails with the error.
        public typealias ConfirmHandlerForServerSideConfirmation = (
          _ paymentMethodID: String,
          _ shouldSavePaymentMethod: Bool,
          _ intentCreationCallback: @escaping ((Result<String, Error>) -> Void)
        ) -> Void

        /// Creates a `PaymentSheet.IntentConfiguration` with the given values
        /// - Parameters:
        ///   - mode: The mode of this intent, either payment or setup
        ///   - paymentMethodTypes: The payment method types for the intent
        ///   - confirmHandler: The handler to be called when the user taps the "Pay" button
        public init(mode: Mode,
                    paymentMethodTypes: [String]? = nil,
                    confirmHandler: @escaping ConfirmHandler) {
            self.mode = mode
            self.paymentMethodTypes = paymentMethodTypes
            self.confirmHandler = confirmHandler
        }

        /// Creates a `PaymentSheet.IntentConfiguration` with the given values
        /// - Parameters:
        ///   - mode: The mode of this intent, either payment or setup
        ///   - paymentMethodTypes: The payment method types for the intent
        ///   - confirmHandlerForServerSideConfirmation: The handler to be called when the user taps the "Pay" button
        public init(mode: Mode,
                    paymentMethodTypes: [String]? = nil,
                    confirmHandlerForServerSideConfirmation: @escaping ConfirmHandlerForServerSideConfirmation) {
            self.mode = mode
            self.paymentMethodTypes = paymentMethodTypes
            self.confirmHandlerForServerSideConfirmation = confirmHandlerForServerSideConfirmation
        }

        /// Information about the payment (PaymentIntent) or setup (SetupIntent).
        public var mode: Mode
        /// A list of payment method types to display to the customer. If nil, we dynamically determine the payment methods using your Stripe Dashboard settings.
        public var paymentMethodTypes: [String]?

        /// Called when the customer confirms payment.
        /// Your implementation should create a PaymentIntent or SetupIntent on the server and call the `intentCreationCallback` with its client secret or an error if one occurred.
        /// - Note: You must create the PaymentIntent or SetupIntent with the same values used as the `IntentConfiguration` e.g. the same amount, currency, etc.
        public var confirmHandler: ConfirmHandler?

        /// For advanced users who need server-side confirmation.
        /// Called when the customer confirms payment.
        /// Your implementation should create and confirm a PaymentIntent or SetupIntent on the server and call the `intentCreationCallback` with its client secret or an error if one occurred.
        /// - Note: You must create the PaymentIntent or SetupIntent with the same values used as the `IntentConfiguration` e.g. the same amount, currency, etc.
        public var confirmHandlerForServerSideConfirmation: ConfirmHandlerForServerSideConfirmation?

        /// Controls when the funds will be captured. 
        /// - Seealso: https://stripe.com/docs/api/payment_intents/create#create_payment_intent-capture_method
        public enum CaptureMethod: String {
            /// (Default) Stripe automatically captures funds when the customer authorizes the payment.
            case automatic

            /// Place a hold on the funds when the customer authorizes the payment, but don’t capture the funds until later. (Not all payment methods support this.)
            case manual
        }

        /// Indicates that you intend to make future payments with this PaymentIntent’s payment method.
        /// - Seealso: https://stripe.com/docs/api/payment_intents/create#create_payment_intent-setup_future_usage
        public enum SetupFutureUsage: String {
            /// Use off_session if your customer may or may not be present in your checkout flow.
            case offSession = "off_session"

            /// Use this if you intend to only reuse the payment method when your customer is present in your checkout flow.
            case onSession = "on_session"
        }

        /// Additional information about the payment or setup
        public enum Mode {
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
                captureMethod: CaptureMethod = .automatic
            )
            /// Use this if your integration creates a SetupIntent
            case setup(
                /// Three-letter ISO currency code. Optional - setting this ensures only valid payment methods are displayed.
                currency: String?,
                /// Indicates how the payment method is intended to be used in the future.
                /// - Seealso: https://stripe.com/docs/api/setup_intents/create#create_setup_intent-usage
                setupFutureUsage: SetupFutureUsage = .offSession
            )
        }
    }
}

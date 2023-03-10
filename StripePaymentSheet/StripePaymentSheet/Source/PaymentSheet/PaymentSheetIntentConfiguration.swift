//
//  PaymentSheetIntentConfiguration.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 2/16/23.
//

import Foundation

@_spi(STP) public extension PaymentSheet {
    /// 🚧 Under construction
    struct IntentConfiguration {

        /// - Parameters:
        ///   - paymentMethodId: The id of the PaymentMethod representing the customer's payment details.
        ///     If you need to inspect payment method details, you can fetch the PaymentMethod object using this id on your server. Otherwise, you can ignore this.
        ///   - intentCreationCallback: Call this with the `client_secret` of the PaymentIntent or SetupIntent created by your server or the error that occurred. If you're using PaymentSheet, the error's localizedDescription will be displayed to the customer in the sheet. If you're using PaymentSheet.FlowController, the `confirm` method fails with the error.
        public typealias ConfirmHandler = (
            _ paymentMethodID: String,
            _ intentCreationCallback: @escaping ((Result<String, Error>) -> Void)
        ) -> Void

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
        ///   - captureMethod: The capture method of this intent, either automatic or manual, defaults to automatic
        ///   - paymentMethodTypes: The payment method types for the intent
        ///   - confirmHandler: The handler to be called when the user taps the "Pay" button
        public init(mode: Mode,
                    captureMethod: CaptureMethod = .automatic,
                    paymentMethodTypes: [String]? = nil,
                    confirmHandler: @escaping ConfirmHandler) {
            self.mode = mode
            self.captureMethod = captureMethod
            self.paymentMethodTypes = paymentMethodTypes
            self.confirmHandler = confirmHandler
        }

        /// Creates a `PaymentSheet.IntentConfiguration` with the given values
        /// - Parameters:
        ///   - mode: The mode of this intent, either payment or setup
        ///   - captureMethod: The capture method of this intent, either automatic or manual, defaults to automatic
        ///   - paymentMethodTypes: The payment method types for the intent
        ///   - confirmHandlerForServerSideConfirmation: The handler to be called when the user taps the "Pay" button
        public init(mode: Mode,
                    captureMethod: CaptureMethod = .automatic,
                    paymentMethodTypes: [String]? = nil,
                    confirmHandlerForServerSideConfirmation: @escaping ConfirmHandlerForServerSideConfirmation) {
            self.mode = mode
            self.captureMethod = captureMethod
            self.paymentMethodTypes = paymentMethodTypes
            self.confirmHandlerForServerSideConfirmation = confirmHandlerForServerSideConfirmation
        }

        /// Filters out payment methods based on intended use.
        public var mode: Mode
        /// Filters out payment methods based on their support for manual capture.
        public var captureMethod: CaptureMethod?
        /// An explicit list of payment method types displayed to the customer.
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

        /// Controls when the funds will be captured from the customer’s account.
        public enum CaptureMethod: String {
            /// Stripe automatically captures funds when the customer authorizes the payment.
            case automatic

            /// Place a hold on the funds when the customer authorizes the payment, but don’t capture the funds until later. (Not all payment methods support this.)
            case manual
        }

        /// Indicates that you intend to make future payments with this Intents’s payment method.
        public enum SetupFutureUsage: String {
            /// Indicating your customer may or may not be in your checkout flow.
            case offSession = "off_session"

            /// Indicating you intend to only reuse the payment method when your customer is present in your checkout flow.
            case onSession = "on_session"
        }

        /// Filters out payment methods based on intended use.
        public enum Mode {
            case payment(
                /// Shown in Apple Pay, Buy now pay later UIs, the Pay button, and influences available payment methods.
                amount: Int,
                /// Filters out payment methods based on supported currency.
                currency: String,
                /// Indicates that you intend to make future payments with this Intents’s payment method.
                setupFutureUsage: SetupFutureUsage? = nil
            )
            case setup(
                /// Filters out payment methods based on supported currency.
                currency: String?,
                /// Indicates that you intend to make future payments with this Intents’s payment method.
                setupFutureUsage: SetupFutureUsage
            )
        }
    }
}

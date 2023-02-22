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

        /// Creates a `PaymentSheet.IntentConfiguration` with the given values
        /// - Parameters:
        ///   - mode: The mode of this intent, either payment or setup
        ///   - captureMethod: The capture method of this intent, either automatic or manual, defaults to automatic
        ///   - paymentMethodTypes: The payment method types for the intent
        public init(mode: Mode, captureMethod: CaptureMethod = .automatic, paymentMethodTypes: [String]? = nil) {
            self.mode = mode
            self.captureMethod = captureMethod
            self.paymentMethodTypes = paymentMethodTypes
        }

        /// Filters out payment methods based on intended use.
        var mode: Mode
        /// Filters out payment methods based on their support for manual capture.
        var captureMethod: CaptureMethod?
        /// An explicit list of payment method types displayed to the customer.
        var paymentMethodTypes: [String]?

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

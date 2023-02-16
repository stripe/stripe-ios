//
//  PaymentSheetIntentConfiguration.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 2/16/23.
//

import Foundation

@_spi(STP) public extension PaymentSheet {
    struct IntentConfiguration {
        var mode: Mode
        /// Filters out payment methods based on their support for manual capture.
        var captureMethod: CaptureMethod? = nil
        /// An explicit list of payment method types displayed to the customer.
        var paymentMethodTypes: [String]? = nil

        /// TODO
        enum CaptureMethod {
            case automatic
            case manual
        }

        /// TODO
        enum SetupFutureUsage {
            case offSession
            case onSession
        }

        enum Mode {
            case payment(
                /// Shown in Apple Pay, Buy now pay later UIs, the Pay button, and influences available payment methods.
                amount: Int,
                /// Filters out payment methods based on supported currency.
                currency: String,
                setupFutureUsage: SetupFutureUsage? = nil
            )
            case setup(
              /// Filters out payment methods based on supported currency.
              currency: String?,
              setupFutureUsage: SetupFutureUsage
            )
        }
    }
}

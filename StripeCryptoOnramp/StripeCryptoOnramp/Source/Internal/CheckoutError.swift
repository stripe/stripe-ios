//
//  CheckoutError.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/18/25.
//

import Foundation

/// Errors that can occur during checkout.
enum CheckoutError: LocalizedError {

    /// The payment method is missing from the PaymentIntent.
    case missingPaymentMethod

    /// The payment failed.
    case paymentFailed

    /// The user canceled the payment.
    case userCanceled

    /// An unexpected error occurred.
    case unexpectedError

    var errorDescription: String? {
        switch self {
        case .missingPaymentMethod:
            return "The payment method is missing from the PaymentIntent."
        case .paymentFailed:
            return "The payment failed."
        case .userCanceled:
            return "The user canceled the payment."
        case .unexpectedError:
            return "An unexpected error occurred during checkout."
        }
    }
}

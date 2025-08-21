//
//  CheckoutError.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/18/25.
//

import Foundation

/// Errors that can occur during checkout.
enum CheckoutError: Error {

    /// The payment method is missing from the PaymentIntent.
    case missingPaymentMethod

    /// The payment failed.
    case paymentFailed

    /// The user canceled the payment.
    case userCanceled

    /// The maximum number of attempts to complete the payment has been exceeded.
    case maximumAttemptsExceeded

    /// An unexpected error occurred.
    case unexpectedError
}

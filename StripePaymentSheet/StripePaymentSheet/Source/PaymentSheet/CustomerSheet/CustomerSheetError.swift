//
//  CustomerSheetError.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
import StripePayments

public enum CustomerSheetError: Error {
    /// Error while fetching saved payment methods attached to a customer
    case errorFetchingSavedPaymentMethods(Error)
    /// Error if an unsupported payment method type is specified
    case unsupportedPaymentMethodType(paymentMethodTypes: [String])
    /// An unknown error.
    case unknown(debugDescription: String)
}

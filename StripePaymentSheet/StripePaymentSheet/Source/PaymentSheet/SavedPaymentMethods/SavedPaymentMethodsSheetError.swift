//
//  SavedPaymentMethodsSheetError.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
import StripePayments

@_spi(PrivateBetaSavedPaymentMethodsSheet) public enum SavedPaymentMethodsSheetError: Error {
    /// Error while fetching saved payment methods attached to a customer
    case errorFetchingSavedPaymentMethods(Error)
    /// An unknown error.
    case unknown(debugDescription: String)
}

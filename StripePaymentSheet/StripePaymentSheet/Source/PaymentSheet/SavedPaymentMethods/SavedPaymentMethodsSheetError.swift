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

    /// When calling the setupIntentHandler, the completion block passed back an invalid setup Intent client secret.
    case setupIntentClientSecretInvalid

    /// Unable to fetch setup intent using client secret
    case setupIntentFetchError(Error)

    /// Unable to create payment method
    case createPaymentMethod(Error)

    /// Unable to attach a payment method to the customer
    case attachPaymentMethod(Error)

    /// Unable to detach a payment method to the customer
    case detachPaymentMethod(Error)

    /// Unable to persist the selected Payment Method
    case setSelectedPaymentMethodOption(Error)

    /// Error on retrieving selected Payment Method
    case retrieveSelectedPaymenMethodOption(Error)

    /// An unknown error.
    case unknown(debugDescription: String)
}

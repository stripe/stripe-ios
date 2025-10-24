//
//  PMME+Internal.swift
//  StripePaymentSheet
//
//  Created by George Birch on 10/23/25.
//

import Foundation

enum PaymentMethodMessagingElementError: Error, LocalizedError {
    case missingPublishableKey
    case unexpectedResponseFromStripeAPI

    public var debugDescription: String {
        switch self {
        case .missingPublishableKey: return "The publishable key is missing from the API client."
        case .unexpectedResponseFromStripeAPI: return "Unexpected response from Stripe API."
        }
    }
}

//
//  CheckoutError.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 2/25/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

/// An error returned by ``Checkout``.
@_spi(STP)
@_spi(ReactNativeSDK)
public enum CheckoutError: Error, LocalizedError, Sendable {
    /// The client secret provided to ``Checkout`` is empty.
    case invalidClientSecret

    /// A payment sheet or form is currently presented. Dismiss it before making changes.
    case sheetCurrentlyPresented

    /// A pending Checkout operation did not complete before the timeout elapsed.
    case timedOut

    case invalidShippingCountry(countryCode: String)

    /// The Stripe API returned an error with the given message.
    case apiError(message: String)

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .invalidClientSecret:
            return "Checkout was initialized with an empty client secret."
        case .sheetCurrentlyPresented:
            return "A payment sheet or form is currently presented. Dismiss it before making changes."
        case .timedOut:
            return "Timed out waiting for a Checkout operation to complete."
        case .invalidShippingCountry(let countryCode):
            return "Country code '\(countryCode)' is not in allowedShippingCountries"
        case .apiError(let message):
            return message
        }
    }
}

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

    /// The provided shipping country is not in the session's list of allowed shipping countries.
    case invalidShippingCountry(countryCode: String)

    /// The Apple Pay configuration is missing from ``Checkout/Configuration``.
    case applePayNotConfigured

    /// Apple Pay could not be presented. The device may not support Apple Pay or no payment cards are set up in Wallet.
    case applePayUnavailable

    /// The Stripe API returned an error with the given message.
    case apiError(message: String)

    /// An unexpected error occurred in the Checkout SDK.
    case unknown(debugDescription: String)

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
        case .applePayNotConfigured:
            return "Apple Pay configuration is missing. Set applePayConfiguration on Checkout.Configuration."
        case .applePayUnavailable:
            return "Apple Pay could not be presented. The device may not support Apple Pay or no payment cards are set up in Wallet."
        case .apiError(let message):
            return message
        case .unknown(let debugDescription):
            return debugDescription
        }
    }
}

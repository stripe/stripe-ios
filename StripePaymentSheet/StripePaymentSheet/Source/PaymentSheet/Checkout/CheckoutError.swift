//
//  CheckoutError.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 2/25/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore

/// An error returned by ``CheckoutElementsController``.
enum CheckoutError: Error, LocalizedError, Sendable {
    /// The client secret provided to ``CheckoutElementsController`` is empty.
    case invalidClientSecret

    /// A payment sheet or form is currently presented. Dismiss it before making changes.
    case sheetCurrentlyPresented

    /// A pending Checkout operation did not complete before the timeout elapsed.
    case timedOut

    /// Polling reported failed confirmation, and retrieving the Session for error details failed.
    case pollFailedAndSessionRetrievalFailed

    /// The total changed while the Apple Pay sheet was presented, after the customer could no longer see it.
    case totalChanged

    /// The provided shipping country is not in the session's list of allowed shipping countries.
    case invalidShippingCountry(countryCode: String)

    /// The device can't currently make Apple Pay payments, for example because its cards or payment restrictions changed.
    case applePayUnavailable

    /// PassKit didn't present the Apple Pay sheet, usually because of the app's Apple Pay setup.
    case applePayPresentationFailed

    /// The Stripe API returned an error with the given message.
    case apiError(message: String, underlyingError: Error? = nil)

    /// An unexpected error occurred in the Checkout SDK.
    case unknown(debugDescription: String)

    // MARK: - LocalizedError

    /// The message merchants display to customers.
    var errorDescription: String? {
        switch self {
        case .apiError(let message, _):
            return message
        default:
            // Errors that don't come from the Stripe API use a generic message, because their details are only meaningful
            // to developers. `debugDescription` explains what went wrong.
            return NSError.stp_unexpectedErrorMessage()
        }
    }
}

// MARK: - CustomDebugStringConvertible

extension CheckoutError: CustomDebugStringConvertible {

    /// A description of what went wrong, for developers. Don't display it to customers.
    var debugDescription: String {
        switch self {
        case .invalidClientSecret:
            return "Checkout was initialized with an empty client secret."
        case .sheetCurrentlyPresented:
            return "A payment sheet or form is currently presented. Dismiss it before making changes."
        case .timedOut:
            return "Timed out waiting for a Checkout operation to complete."
        case .pollFailedAndSessionRetrievalFailed:
            return "Polling reported failed confirmation, and retrieving the Checkout Session for error details failed."
        case .totalChanged:
            return "The total changed while the Apple Pay sheet was presented, after the customer could no longer see it."
        case .invalidShippingCountry(let countryCode):
            return "Country code '\(countryCode)' is not in allowedShippingCountries"
        case .applePayUnavailable:
            return "Apple Pay is unavailable on this device. Check device support and payment restrictions."
        case .applePayPresentationFailed:
            return """
                Could not present Apple Pay. Check Apple Pay setup in Wallet and that the merchant ID matches an ID \
                in the app's Apple Pay entitlements and provisioning profile. Ensure the app is active, \
                the presenting window is visible, and no other presentation or dismissal is in progress.
                """
        case .apiError(let message, let underlyingError):
            guard let underlyingError else { return message }
            return "\(message) Underlying error: \(String(reflecting: underlyingError))"
        case .unknown(let debugDescription):
            return debugDescription
        }
    }
}

// MARK: - AnalyticLoggableError

extension CheckoutError: AnalyticLoggableError {

    /// The qualified type name, which is what analytics logged before this conformance.
    var analyticsErrorType: String {
        return String(reflecting: Self.self)
    }

    /// The case name. The default would log `debugDescription` for cases without associated values.
    var analyticsErrorCode: String {
        switch self {
        case .invalidClientSecret:
            return "invalidClientSecret"
        case .sheetCurrentlyPresented:
            return "sheetCurrentlyPresented"
        case .timedOut:
            return "timedOut"
        case .pollFailedAndSessionRetrievalFailed:
            return "pollFailedAndSessionRetrievalFailed"
        case .totalChanged:
            return "totalChanged"
        case .invalidShippingCountry:
            return "invalidShippingCountry"
        case .applePayUnavailable:
            return "applePayUnavailable"
        case .applePayPresentationFailed:
            return "applePayPresentationFailed"
        case .apiError:
            return "apiError"
        case .unknown:
            return "unknown"
        }
    }

    var additionalNonPIIErrorDetails: [String: Any] {
        return [:]
    }
}

extension CheckoutError {
    /// Preserve the original API error for analytics while keeping the displayed message.
    var analyticsError: Error {
        guard case .apiError(_, let underlyingError) = self, let underlyingError else {
            return self
        }
        return (underlyingError as? CheckoutError)?.analyticsError ?? underlyingError
    }
}

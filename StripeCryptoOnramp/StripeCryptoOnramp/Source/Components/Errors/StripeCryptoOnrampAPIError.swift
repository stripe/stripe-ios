//
//  StripeCryptoOnrampAPIError.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 5/28/26.
//

import Foundation

/// A rich Crypto Onramp error backed by a Stripe API error.
@_spi(CryptoOnrampAlpha)
public protocol StripeCryptoOnrampAPIError: StripeCryptoOnrampError {

    /// The backend `reason` value associated with this error, if one is available.
    var reason: String? { get }

    /// The SDK operation that was running when this error occurred.
    var operation: String { get }

    /// The bundle identifier for the app using the SDK, if one is available.
    var appIdentifier: String? { get }

    /// The Stripe mode associated with this error, if it can be determined.
    var mode: String? { get }

    /// The backend API error type associated with this error, if one is available.
    var type: String? { get }

    /// The Stripe API request ID associated with this error, if one is available.
    var requestID: String? { get }

    /// The backend developer-facing API error message associated with this error, if one is available.
    var apiMessage: String? { get }

    /// The backend user-facing API error message associated with this error, if one is available.
    var apiUserMessage: String? { get }
}

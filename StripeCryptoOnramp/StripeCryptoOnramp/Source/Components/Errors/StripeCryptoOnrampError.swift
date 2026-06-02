//
//  StripeCryptoOnrampError.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 5/28/26.
//

import Foundation
@_spi(STP) import StripeCore

/// A rich Crypto Onramp error with separate app-user and developer-facing surfaces.
@_spi(CryptoOnrampAlpha)
public protocol StripeCryptoOnrampError: Error, LocalizedError, CustomDebugStringConvertible {

    /// A stable code identifying this error.
    var code: String { get }

    /// A localized message that can be shown to the app user.
    var userMessage: String { get }

    /// A developer-facing description with diagnostic details and suggested next steps.
    var developerMessage: String { get }

    /// A URL to documentation for this error, if one is available.
    var docURL: URL? { get }

    /// The original error that was mapped to this error, if one is available.
    var underlyingError: Swift.Error? { get }

    /// The Stripe iOS SDK version.
    var sdkVersion: String { get }
}

/// Default surfaces for rich Crypto Onramp errors.
@_spi(CryptoOnrampAlpha)
public extension StripeCryptoOnrampError {

    // MARK: - StripeCryptoOnrampError

    /// The Stripe iOS SDK version.
    var sdkVersion: String {
        return STPAPIClient.STPSDKVersion
    }

    // MARK: - LocalizedError

    /// A localized message that can be shown to the app user.
    var errorDescription: String? {
        return userMessage
    }

    // MARK: - CustomDebugStringConvertible

    /// A developer-facing description with diagnostic details and suggested next steps.
    var debugDescription: String {
        return developerMessage
    }
}

//
//  StripeCryptoOnrampError.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 5/28/26.
//

import Foundation
@_spi(STP) import StripeCore

/// A wrapper SDK name and version pair included in developer diagnostics.
///
/// Do not use this type for the Stripe iOS SDK version. Stripe iOS is always included automatically.
@_spi(CryptoOnrampAlpha)
public struct SDKVersion: CustomDebugStringConvertible, Equatable {

    /// The SDK name.
    public let name: String

    /// The SDK version.
    public let version: String

    static let stripeIOS = SDKVersion(name: "stripe-ios", version: STPAPIClient.STPSDKVersion)

    /// Creates an SDK version from a name and version.
    ///
    /// - Parameters:
    ///   - name: The SDK name.
    ///   - version: The SDK version.
    public init(name: String, version: String) {
        self.name = name
        self.version = version
    }

    /// A developer-facing SDK version description.
    public var debugDescription: String {
        return "\(name)@\(version)"
    }
}

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
}

/// Default surfaces for rich Crypto Onramp errors.
@_spi(CryptoOnrampAlpha)
public extension StripeCryptoOnrampError {

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

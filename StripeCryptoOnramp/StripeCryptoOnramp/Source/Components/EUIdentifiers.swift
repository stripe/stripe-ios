//
//  EUIdentifiers.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 4/22/26.
//

import Foundation

/// An EU identifier collected for MICA or CRS/CARF compliance.
@_spi(CryptoOnrampAlpha)
public struct EUIdentifier: Codable, Equatable {

    /// The two-letter country code associated with the identifier (ISO 3166-1 alpha-2).
    public let country: String

    /// The national identifier or tax identification number value.
    public let identifier: String

    /// Creates an `EUIdentifier`.
    /// - Parameters:
    ///   - country: The two-letter country code associated with the identifier (ISO 3166-1 alpha-2).
    ///   - identifier: The national identifier or tax identification number value.
    public init(country: String, identifier: String) {
        self.country = country
        self.identifier = identifier
    }
}

/// EU identifiers collected for MICA and CRS/CARF compliance.
@_spi(CryptoOnrampAlpha)
public struct EUIdentifiers: Equatable {

    /// National identifiers collected for MICA compliance.
    public let mica: [EUIdentifier]

    /// Tax identification numbers collected for CRS/CARF compliance.
    public let carf: [EUIdentifier]

    /// Creates an `EUIdentifiers` value.
    /// - Parameters:
    ///   - mica: National identifiers collected for MICA compliance.
    ///   - carf: Tax identification numbers collected for CRS/CARF compliance.
    public init(
        mica: [EUIdentifier] = [],
        carf: [EUIdentifier] = []
    ) {
        self.mica = mica
        self.carf = carf
    }
}

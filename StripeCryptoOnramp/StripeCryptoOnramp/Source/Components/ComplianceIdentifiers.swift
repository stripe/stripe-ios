//
//  ComplianceIdentifiers.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 4/30/26.
//

import Foundation

/// The regulation requiring a compliance identifier.
@_spi(CryptoOnrampAlpha)
public enum ComplianceRegulation: String, Codable, Equatable, Hashable {

    /// Common Reporting Standard (CRS) and Crypto-Asset Reporting Framework (CARF).
    case euCARF = "eu_carf"

    /// Markets in Crypto-Assets Regulation (MICA).
    case euMICA = "eu_mica"
}

/// A compliance identifier collected for MICA or CRS/CARF compliance.
@_spi(CryptoOnrampAlpha)
public struct ComplianceIdentifier: Codable, Equatable, Hashable {

    /// The type of identifier provided.
    public let type: String

    /// The identifier value.
    public let value: String

    /// Creates a `ComplianceIdentifier`.
    /// - Parameters:
    ///   - type: The type of identifier provided.
    ///   - value: The identifier value.
    public init(type: String, value: String) {
        self.type = type
        self.value = value
    }
}

/// A compliance identifier the customer still needs to provide.
@_spi(CryptoOnrampAlpha)
public struct ComplianceIdentifierRequirement: Decodable, Equatable, Hashable {

    /// The type of identifier required.
    public let type: String

    /// The regulation requiring this identifier.
    public let regulation: ComplianceRegulation

    /// Creates a `ComplianceIdentifierRequirement`.
    /// - Parameters:
    ///   - type: The type of identifier required.
    ///   - regulation: The regulation requiring this identifier.
    public init(type: String, regulation: ComplianceRegulation) {
        self.type = type
        self.regulation = regulation
    }
}

/// A group describing alternative identifier types that may satisfy a requirement.
@_spi(CryptoOnrampAlpha)
public struct ComplianceIdentifierAlternativeGroup: Decodable, Equatable, Hashable {

    /// The original identifier types required.
    public let originalMissingIdentifiers: [String]

    /// Alternative identifier types that may satisfy the original requirement.
    public let alternativeMissingIdentifiers: [String]

    /// Creates a `ComplianceIdentifierAlternativeGroup`.
    /// - Parameters:
    ///   - originalMissingIdentifiers: The original identifier types required.
    ///   - alternativeMissingIdentifiers: Alternative identifier types that may satisfy the original requirement.
    public init(
        originalMissingIdentifiers: [String],
        alternativeMissingIdentifiers: [String]
    ) {
        self.originalMissingIdentifiers = originalMissingIdentifiers
        self.alternativeMissingIdentifiers = alternativeMissingIdentifiers
    }

    private enum CodingKeys: String, CodingKey {
        case originalMissingIdentifiers = "original_missing_identifiers"
        case alternativeMissingIdentifiers = "alternative_missing_identifiers"
    }
}

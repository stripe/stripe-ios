//
//  ComplianceIdentifierAlternativeGroup.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 5/4/26.
//

import Foundation

/// A group describing alternative identifier types that may satisfy a requirement.
@_spi(CryptoOnrampAlpha)
public struct ComplianceIdentifierAlternativeGroup: Decodable, Equatable, Hashable {

    /// The original identifier types required.
    public let originalMissingIdentifiers: [ComplianceIdentifierType]

    /// Alternative identifier types that may satisfy the original requirement.
    public let alternativeMissingIdentifiers: [ComplianceIdentifierType]

    /// Creates a `ComplianceIdentifierAlternativeGroup`.
    /// - Parameters:
    ///   - originalMissingIdentifiers: The original identifier types required.
    ///   - alternativeMissingIdentifiers: Alternative identifier types that may satisfy the original requirement.
    public init(
        originalMissingIdentifiers: [ComplianceIdentifierType],
        alternativeMissingIdentifiers: [ComplianceIdentifierType]
    ) {
        self.originalMissingIdentifiers = originalMissingIdentifiers
        self.alternativeMissingIdentifiers = alternativeMissingIdentifiers
    }

    // MARK: - Decodable

    private enum CodingKeys: String, CodingKey {
        case originalMissingIdentifiers = "original_missing_identifiers"
        case alternativeMissingIdentifiers = "alternative_missing_identifiers"
    }
}

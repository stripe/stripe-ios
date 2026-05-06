//
//  ComplianceIdentifierRequirements.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 4/30/26.
//

import Foundation

/// The compliance identifiers a customer still needs to provide.
@_spi(CryptoOnrampAlpha)
public struct ComplianceIdentifierRequirements: Decodable, Equatable, Hashable {

    /// Required identifier types and the regulations requiring them.
    public let identifiers: [ComplianceIdentifierRequirement]

    /// Alternative identifier groups that may satisfy one or more requirements.
    public let alternatives: [ComplianceIdentifierAlternativeGroup]

    /// Creates a `ComplianceIdentifierRequirements`.
    /// - Parameters:
    ///   - identifiers: Required identifier types and the regulations requiring them.
    ///   - alternatives: Alternative identifier groups that may satisfy one or more requirements.
    public init(
        identifiers: [ComplianceIdentifierRequirement],
        alternatives: [ComplianceIdentifierAlternativeGroup]
    ) {
        self.identifiers = identifiers
        self.alternatives = alternatives
    }

    // MARK: - Decodable

    private enum CodingKeys: String, CodingKey {
        case identifiers
        case alternatives
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identifiers = try container.decodeIfPresent([ComplianceIdentifierRequirement].self, forKey: .identifiers) ?? []
        alternatives = try container.decodeIfPresent([ComplianceIdentifierAlternativeGroup].self, forKey: .alternatives) ?? []
    }
}

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

    /// Required MiCA identifier types and the regulations requiring them.
    public let identifiers: [ComplianceIdentifierRequirement]

    /// Alternative MiCA identifier groups that may satisfy one or more requirements.
    public let alternatives: [ComplianceIdentifierAlternativeGroup]

    /// Whether at least one CRS/CARF tax identification number still needs to be collected.
    public let carfTinRequired: Bool

    /// Creates a `ComplianceIdentifierRequirements`.
    /// - Parameters:
    ///   - identifiers: Required MiCA identifier types and the regulations requiring them.
    ///   - alternatives: Alternative MiCA identifier groups that may satisfy one or more requirements.
    ///   - carfTinRequired: Whether at least one CRS/CARF tax identification number still needs to be collected.
    public init(
        identifiers: [ComplianceIdentifierRequirement],
        alternatives: [ComplianceIdentifierAlternativeGroup],
        carfTinRequired: Bool
    ) {
        self.identifiers = identifiers
        self.alternatives = alternatives
        self.carfTinRequired = carfTinRequired
    }

    // MARK: - Decodable

    private enum CodingKeys: String, CodingKey {
        case identifiers
        case alternatives
        case carfTinRequired = "carf_tin_required"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identifiers = try container.decodeIfPresent([ComplianceIdentifierRequirement].self, forKey: .identifiers) ?? []
        alternatives = try container.decodeIfPresent([ComplianceIdentifierAlternativeGroup].self, forKey: .alternatives) ?? []
        carfTinRequired = try container.decodeIfPresent(Bool.self, forKey: .carfTinRequired) ?? false
    }
}

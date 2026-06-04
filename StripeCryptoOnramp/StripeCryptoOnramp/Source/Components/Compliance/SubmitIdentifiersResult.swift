//
//  SubmitIdentifiersResult.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 4/30/26.
//

import Foundation

/// The result of submitting compliance identifiers for MiCA and CRS/CARF compliance.
@_spi(CryptoOnrampAlpha)
public struct SubmitIdentifiersResult: Decodable, Equatable {

    /// Whether all required MiCA identifiers and CRS/CARF tax identification numbers have been submitted.
    public let completed: Bool

    /// Any MiCA identifiers that still need to be collected.
    public let identifiers: [ComplianceIdentifierRequirement]

    /// Alternative MiCA identifier groups that may satisfy one or more requirements.
    public let alternatives: [ComplianceIdentifierAlternativeGroup]

    /// Whether at least one CRS/CARF tax identification number still needs to be collected.
    public let carfTinRequired: Bool

    /// Submitted identifier types whose values were invalid.
    public let invalidIdentifiers: [ComplianceIdentifierType]

    // MARK: - Decodable

    private enum CodingKeys: String, CodingKey {
        case completed
        case identifiers
        case alternatives
        case carfTinRequired = "carf_tin_required"
        case invalidIdentifiers = "invalid_identifiers"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        completed = try container.decodeIfPresent(Bool.self, forKey: .completed) ?? false
        identifiers = try container.decodeIfPresent([ComplianceIdentifierRequirement].self, forKey: .identifiers) ?? []
        alternatives = try container.decodeIfPresent([ComplianceIdentifierAlternativeGroup].self, forKey: .alternatives) ?? []
        carfTinRequired = try container.decodeIfPresent(Bool.self, forKey: .carfTinRequired) ?? false
        invalidIdentifiers = try container.decodeIfPresent([ComplianceIdentifierType].self, forKey: .invalidIdentifiers) ?? []
    }
}

//
//  SubmitIdentifiersResult.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 4/30/26.
//

import Foundation

/// The result of submitting compliance identifiers for MICA and CRS/CARF compliance.
@_spi(CryptoOnrampAlpha)
public struct SubmitIdentifiersResult: Decodable, Equatable {

    /// Whether all required identifiers were accepted.
    public let valid: Bool

    /// Any identifiers that still need to be collected.
    public let identifiers: [ComplianceIdentifierRequirement]

    /// Alternative identifier groups that may satisfy one or more requirements.
    public let alternatives: [ComplianceIdentifierAlternativeGroup]

    /// Submitted identifier types whose values were invalid.
    public let invalidIdentifiers: [ComplianceIdentifierType]

    private enum CodingKeys: String, CodingKey {
        case valid
        case identifiers
        case alternatives
        case invalidIdentifiers = "invalid_identifiers"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        valid = try container.decodeIfPresent(Bool.self, forKey: .valid) ?? true
        identifiers = try container.decodeIfPresent([ComplianceIdentifierRequirement].self, forKey: .identifiers) ?? []
        alternatives = try container.decodeIfPresent([ComplianceIdentifierAlternativeGroup].self, forKey: .alternatives) ?? []
        invalidIdentifiers = try container.decodeIfPresent([ComplianceIdentifierType].self, forKey: .invalidIdentifiers) ?? []
    }
}

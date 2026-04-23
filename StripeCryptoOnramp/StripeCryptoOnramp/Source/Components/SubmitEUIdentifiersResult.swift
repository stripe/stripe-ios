//
//  SubmitEUIdentifiersResult.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 4/22/26.
//

import Foundation

/// The result of submitting EU identifiers for MICA and CRS/CARF compliance.
@_spi(CryptoOnrampAlpha)
public struct SubmitEUIdentifiersResult: Decodable, Equatable {

    /// Whether all required identifiers were accepted.
    public let valid: Bool

    /// Any identifiers that still need to be collected.
    public let missingIdentifiers: MissingEUIdentifiers?

    /// Country codes whose submitted identifiers were invalid.
    public let errors: [String]?

    private enum CodingKeys: String, CodingKey {
        case valid
        case missingIdentifiers = "missing_identifiers"
        case errors
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        valid = try container.decodeIfPresent(Bool.self, forKey: .valid) ?? true
        let nestedMissingIdentifiers = try container.decodeIfPresent(MissingEUIdentifiers.self, forKey: .missingIdentifiers)
        let topLevelMissingIdentifiers = try? MissingEUIdentifiers(from: decoder)
        missingIdentifiers = nestedMissingIdentifiers ?? topLevelMissingIdentifiers?.nilIfEmpty
        errors = try container.decodeIfPresent([String].self, forKey: .errors)
    }
}

private extension MissingEUIdentifiers {
    var nilIfEmpty: MissingEUIdentifiers? {
        if missingIdentifiersMICA.isEmpty && missingIdentifiersCARF.isEmpty {
            return nil
        }
        return self
    }
}

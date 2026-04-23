//
//  MissingEUIdentifiers.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 4/22/26.
//

import Foundation

/// The EU identifiers a customer still needs to provide for MICA and CRS/CARF compliance.
@_spi(CryptoOnrampAlpha)
public struct MissingEUIdentifiers: Decodable, Equatable {

    /// Country codes requiring national identifiers for MICA compliance.
    public let missingIdentifiersMICA: [String]

    /// Country codes requiring tax identification numbers for CRS/CARF compliance.
    public let missingIdentifiersCARF: [String]

    private enum CodingKeys: String, CodingKey {
        case missingIdentifiersMICA = "missing_identifiers_mica"
        case missingIdentifiersCARF = "missing_identifiers_carf"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        missingIdentifiersMICA = try container.decodeIfPresent([String].self, forKey: .missingIdentifiersMICA) ?? []
        missingIdentifiersCARF = try container.decodeIfPresent([String].self, forKey: .missingIdentifiersCARF) ?? []
    }
}

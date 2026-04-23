//
//  EUIdentifiersRequest.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 4/22/26.
//

import Foundation

/// Encodable model passed to the `/v1/crypto/internal/eu_identifiers` endpoint.
struct EUIdentifiersRequest: Encodable {

    /// Contains credentials required to make the request.
    let credentials: Credentials

    /// EU identifiers collected for MICA and CRS/CARF compliance.
    let identifiers: EUIdentifiers

    private enum CodingKeys: String, CodingKey {
        case credentials
        case identifiersMICA = "identifiers_mica"
        case identifiersCARF = "identifiers_carf"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(credentials, forKey: .credentials)

        if !identifiers.mica.isEmpty {
            try container.encode(identifiers.mica, forKey: .identifiersMICA)
        }

        if !identifiers.carf.isEmpty {
            try container.encode(identifiers.carf, forKey: .identifiersCARF)
        }
    }
}

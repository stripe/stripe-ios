//
//  UserAttestation.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 4/22/26.
//

import Foundation

/// Decodable model representing the attestation returned by `/v1/crypto/internal/crs_carf_declaration`.
struct UserAttestation: Decodable, Equatable {

    /// The attestation HTML to present to the customer.
    let html: String

    /// The attestation version.
    let version: String

    private enum CodingKeys: String, CodingKey {
        case html = "text"
        case version
    }
}

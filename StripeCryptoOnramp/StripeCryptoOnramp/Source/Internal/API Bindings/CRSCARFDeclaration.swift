//
//  CRSCARFDeclaration.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 4/22/26.
//

import Foundation

/// Decodable model representing the declaration returned by `/v1/crypto/internal/crs_carf_declaration`.
struct CRSCARFDeclaration: Decodable, Equatable {

    /// The declaration HTML to present to the customer.
    let html: String

    /// The declaration version.
    let version: String

    private enum CodingKeys: String, CodingKey {
        case html = "text"
        case version
    }
}

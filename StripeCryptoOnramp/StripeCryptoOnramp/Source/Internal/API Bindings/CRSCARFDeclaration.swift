//
//  CRSCARFDeclaration.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 4/22/26.
//

import Foundation

/// Decodable model representing the declaration returned by `/v1/crypto/internal/crs_carf_declaration`.
struct CRSCARFDeclaration: Decodable, Equatable {

    /// The declaration text to present to the customer.
    let text: String

    /// The declaration version.
    let version: String
}

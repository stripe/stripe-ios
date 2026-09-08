//
//  RetrievePartnerTermsRequest.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/1/26.
//

import Foundation

/// Encodable model passed to the `/v1/crypto/internal/partner_terms` endpoint.
struct RetrievePartnerTermsRequest: Encodable {

    /// The type of declaration to retrieve.
    let declarationType: PartnerDeclarationType

    // MARK: - Encodable

    private enum CodingKeys: String, CodingKey {
        case declarationType = "declaration_type"
    }
}

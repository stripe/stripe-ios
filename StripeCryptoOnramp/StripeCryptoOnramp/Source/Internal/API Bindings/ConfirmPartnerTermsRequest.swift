//
//  ConfirmPartnerTermsRequest.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/27/26.
//

import Foundation

/// Encodable model passed when recording acceptance with the `/v1/crypto/internal/partner_terms` endpoint.
struct ConfirmPartnerTermsRequest: Encodable {

    /// The unique identifier of the declaration accepted by the customer.
    let declarationId: String

    // MARK: - Encodable

    private enum CodingKeys: String, CodingKey {
        case declarationId = "declaration_id"
    }
}

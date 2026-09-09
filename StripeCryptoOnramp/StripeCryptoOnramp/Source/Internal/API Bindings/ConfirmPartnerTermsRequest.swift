//
//  ConfirmPartnerTermsRequest.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/27/26.
//

import Foundation

/// Encodable model passed when recording acceptance with the `/v1/crypto/internal/partner_terms` endpoint.
struct ConfirmPartnerTermsRequest: Encodable {

    /// Contains credentials required to make the request.
    let credentials: Credentials

    /// The unique identifier of the declaration accepted by the customer.
    let declarationId: String

    // MARK: - Encodable

    private enum CodingKeys: String, CodingKey {
        case credentials
        case declarationId = "declaration_id"
    }
}

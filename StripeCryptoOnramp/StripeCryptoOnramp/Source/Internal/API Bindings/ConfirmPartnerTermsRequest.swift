//
//  ConfirmPartnerTermsRequest.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/27/26.
//

import Foundation

/// Encodable model passed to the `/v1/crypto/internal/confirm_partner_terms` endpoint.
struct ConfirmPartnerTermsRequest: Encodable {

    /// Contains credentials required to make the request.
    let credentials: Credentials

    /// The partner whose declaration the customer accepted.
    let partner: CryptoOnrampPartner

    /// The version of the declaration accepted by the customer.
    let version: String

    /// The unique identifier of the declaration accepted by the customer.
    let declarationId: String

    // MARK: - Encodable

    private enum CodingKeys: String, CodingKey {
        case credentials
        case partner
        case version
        case declarationId = "declaration_id"
    }
}

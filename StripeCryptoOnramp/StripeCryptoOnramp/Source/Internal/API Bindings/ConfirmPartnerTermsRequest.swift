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

    /// The version of the terms and conditions accepted by the customer.
    let version: String
}

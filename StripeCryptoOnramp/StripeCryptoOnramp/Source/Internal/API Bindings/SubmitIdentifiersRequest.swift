//
//  SubmitIdentifiersRequest.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 4/30/26.
//

import Foundation

/// Encodable model passed to the `/v1/crypto/internal/eu_identifiers` endpoint.
struct SubmitIdentifiersRequest: Encodable {

    /// Contains credentials required to make the request.
    let credentials: Credentials

    /// Compliance identifiers collected for MICA and CRS/CARF compliance.
    let identifiers: [ComplianceIdentifier]
}

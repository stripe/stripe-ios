//
//  CustomerRequest.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 7/17/25.
//

import Foundation

/// Codable model passed to the `crypto/internal/customers` endpoint.
struct CustomerRequest: Codable {

    /// Client secret provided by the Link account’s consumer session.
    let consumerSessionClientSecret: String

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case consumerSessionClientSecret = "consumer_session_client_secret"
    }
}

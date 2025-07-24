//
//  CustomerRequest.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 7/17/25.
//

import Foundation

/// Encodable model passed to the `/v1/crypto/internal/customers` endpoint.
struct CustomerRequest: Encodable {

    /// Container for credentials required to make the request
    struct Credentials: Codable {

        /// Client secret provided by the Link account’s consumer session.
        let consumerSessionClientSecret: String

        // MARK: - Codable

        enum CodingKeys: String, CodingKey {
            case consumerSessionClientSecret = "consumer_session_client_secret"
        }
    }

    /// Contains credentials required to make the request.
    let credentials: Credentials

    /// Creates a new `CustomerRequest` instance.
    /// - Parameter consumerSessionClientSecret: Contains credentials required to make the request.
    init(consumerSessionClientSecret: String) {
        credentials = Credentials(consumerSessionClientSecret: consumerSessionClientSecret)
    }
}

//
//  Credentials.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/4/25.
//

import Foundation

/// Container for credentials required to make the request
struct Credentials: Codable {

    /// Client secret provided by the Link account’s consumer session.
    let consumerSessionClientSecret: String

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case consumerSessionClientSecret = "consumer_session_client_secret"
    }
}

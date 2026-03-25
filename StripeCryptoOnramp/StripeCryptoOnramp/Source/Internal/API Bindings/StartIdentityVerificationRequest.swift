//
//  StartIdentityVerificationRequest.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/5/25.
//

import Foundation

/// Encodable model passed to the `/v1/crypto/internal/start_identity_verification` endpoint.
struct StartIdentityVerificationRequest: Encodable {

    /// Contains credentials required to make the request.
    let credentials: Credentials

    /// When `true`, the response will contain an `ephemeral_key` used to initialize the Identity SDK.
    let isMobile: Bool = true

    /// Creates a new `StartIdentityVerificationRequest` instance.
    /// - Parameters:
    ///   - consumerSessionClientSecret: Contains credentials required to make the request.
    init(consumerSessionClientSecret: String) {
        credentials = Credentials(consumerSessionClientSecret: consumerSessionClientSecret)
    }

    // MARK: - Encodable

    enum CodingKeys: String, CodingKey {
        case credentials
        case isMobile = "is_mobile"
    }
}

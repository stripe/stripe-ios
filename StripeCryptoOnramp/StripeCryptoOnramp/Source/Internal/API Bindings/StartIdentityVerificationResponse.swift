//
//  StartIdentityVerificationResponse.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/5/25.
//

import Foundation

/// Codable model representing a response from the `/v1/crypto/internal/start_identity_verification`.
struct StartIdentityVerificationResponse: Codable {

    /// The identifier for the resulting identity session.
    let id: String

    /// The hosted Identity Page for redirecting users for Hosted Onramp
    let url: URL

    /// Used to authenticate the mobile Identity SDK.
    /// - NOTE: Present only if `is_mobile` was `true` in the request. `nil` otherwise.
    let ephemeralKey: String?

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case id
        case url
        case ephemeralKey = "ephemeral_key"
    }
}

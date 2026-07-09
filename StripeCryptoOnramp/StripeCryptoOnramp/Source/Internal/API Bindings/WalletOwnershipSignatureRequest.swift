//
//  WalletOwnershipSignatureRequest.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 6/17/26.
//

import Foundation

/// Encodable model passed to the `/v1/crypto/internal/wallet_ownership_verification` endpoint.
struct WalletOwnershipSignatureRequest: Encodable {

    /// Opaque identifier returned by `getWalletOwnershipChallenge`.
    let challengeId: String

    /// Signature produced by the merchant's wallet stack over the exact challenge message.
    let signature: String

    /// Contains credentials required to make the request.
    let credentials: Credentials

    /// Creates a new `WalletOwnershipSignatureRequest` instance.
    /// - Parameters:
    ///   - challengeId: Opaque identifier returned by `getWalletOwnershipChallenge`.
    ///   - signature: Signature produced by the merchant's wallet stack over the exact challenge message.
    ///   - consumerSessionClientSecret: Contains credentials required to make the request.
    init(challengeId: String, signature: String, consumerSessionClientSecret: String) {
        self.challengeId = challengeId
        self.signature = signature
        self.credentials = Credentials(consumerSessionClientSecret: consumerSessionClientSecret)
    }

    // MARK: - Encodable

    private enum CodingKeys: String, CodingKey {
        case challengeId = "challenge_id"
        case signature
        case credentials
    }
}

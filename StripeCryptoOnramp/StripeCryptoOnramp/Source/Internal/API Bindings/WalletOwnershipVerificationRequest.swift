//
//  WalletOwnershipVerificationRequest.swift
//  StripeCryptoOnramp
//

import Foundation

/// Encodable model passed to the `/v1/crypto/internal/wallet_ownership_verification` endpoint.
struct WalletOwnershipVerificationRequest: Encodable {
    /// The identifier of the challenge to verify.
    let challenge_id: String

    /// The signature over the challenge message.
    let signature: String

    /// Contains credentials required to make the request.
    let credentials: Credentials

    /// Creates a new `WalletOwnershipVerificationRequest` instance.
    /// - Parameters:
    ///   - challengeId: The identifier of the challenge to verify.
    ///   - signature: The signature over the challenge message.
    ///   - consumerSessionClientSecret: Contains credentials required to make the request.
    init(challengeId: String, signature: String, consumerSessionClientSecret: String) {
        self.challenge_id = challengeId
        self.signature = signature
        self.credentials = Credentials(consumerSessionClientSecret: consumerSessionClientSecret)
    }
}

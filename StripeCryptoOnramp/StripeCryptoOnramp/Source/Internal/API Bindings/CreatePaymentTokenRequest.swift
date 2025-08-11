//
//  CreatePaymentTokenRequest.swift
//  StripeCryptoOnramp
//
//  Created by Mat Schmid on 8/9/25.
//

import Foundation

/// Encodable model passed to the `/v1/crypto/internal/payment_token` endpoint.
struct CreatePaymentTokenRequest: Encodable {
    /// The crypto wallet address to register.
    let id: String

    /// Contains credentials required to make the request.
    let credentials: Credentials

    init(id: String, consumerSessionClientSecret: String) {
        self.id = id
        self.credentials = Credentials(consumerSessionClientSecret: consumerSessionClientSecret)
    }
}

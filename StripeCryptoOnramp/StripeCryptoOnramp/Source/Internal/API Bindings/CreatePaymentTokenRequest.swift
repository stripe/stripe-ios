//
//  CreatePaymentTokenRequest.swift
//  StripeCryptoOnramp
//
//  Created by Mat Schmid on 8/19/25.
//

import Foundation

/// Encodable model passed to the `/v1/crypto/internal/payment_token` endpoint.
struct CreatePaymentTokenRequest: Encodable {
    let paymentMethod: String
    let cryptoCustomerId: String
    let uiMode: String = "headless"
}

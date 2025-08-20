//
//  CreatePaymentTokenResponse.swift
//  StripeCryptoOnramp
//
//  Created by Mat Schmid on 8/9/25.
//

import Foundation

/// Codable model representing a response from the `/v1/crypto/internal/payment_token` endpoint.
struct CreatePaymentTokenResponse: Codable {

    /// The created crypto wallet's unique identifier.
    let id: String
}

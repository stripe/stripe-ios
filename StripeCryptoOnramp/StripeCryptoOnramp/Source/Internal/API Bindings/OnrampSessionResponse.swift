//
//  OnrampSessionResponse.swift
//  StripeCryptoOnramp
//
//  Created by Mat Schmid on 8/21/25.
//

import Foundation

/// Codable model representing a response from the `/v1/crypto/internal/onramp_session` endpoint.
struct OnrampSessionResponse: Codable {

    /// The onramp session's unique identifier.
    /// `cos_XXXXXXXXX`
    let id: String

    /// The onramp session client secret.
    /// `cos_XXXXXXXXX_secret_XXXXXXXXX`
    let clientSecret: String

    /// The PaymentIntent client secret associated with this onramp session.
    let paymentIntentClientSecret: String

    private enum CodingKeys: String, CodingKey {
        case id
        case clientSecret = "client_secret"
        case paymentIntentClientSecret = "payment_intent_client_secret"
    }
}

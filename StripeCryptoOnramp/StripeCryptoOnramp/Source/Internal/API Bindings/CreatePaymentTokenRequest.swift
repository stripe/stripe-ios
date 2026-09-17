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

    /// An optional two-letter country code (ISO 3166-1 alpha-2) used to help select a merchant of record
    /// when the customer does not yet have an established KYC region. Omitted from the request when `nil`.
    let countryHint: String?
}

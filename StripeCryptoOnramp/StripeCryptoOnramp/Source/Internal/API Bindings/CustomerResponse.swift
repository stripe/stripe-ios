//
//  CustomerResponse.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 7/17/25.
//

/// Codable model representing a response from the `/v1/crypto/internal/customers` endpoint.
struct CustomerResponse: Codable {

    /// The created crypto customer’s unique identifier.
    let id: String
}

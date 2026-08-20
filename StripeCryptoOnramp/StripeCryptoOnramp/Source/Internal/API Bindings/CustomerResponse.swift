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

    /// Partner-specific KYC requirements associated with the customer.
    let requirements: AdditionalKYCRequirements?

    /// Creates a customer response.
    /// - Parameters:
    ///   - id: The created crypto customer’s unique identifier.
    ///   - requirements: Partner-specific KYC requirements associated with the customer.
    init(id: String, requirements: AdditionalKYCRequirements? = nil) {
        self.id = id
        self.requirements = requirements
    }
}

//
//  RetrieveKYCRequirementsResponse.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/3/26.
//

import Foundation

/// A response from `/v1/crypto/internal/kyc_requirements` containing the authenticated customer's additional KYC requirements.
struct RetrieveKYCRequirementsResponse: Decodable, Equatable {

    /// The customer's current additional KYC requirements, keyed by requirement name (e.g. `proof_of_address`, `source_of_funds`).
    /// An empty dictionary indicates that the customer has no outstanding requirements or no account with the partner.
    let requirements: [String: AdditionalKYCRequirement]
}

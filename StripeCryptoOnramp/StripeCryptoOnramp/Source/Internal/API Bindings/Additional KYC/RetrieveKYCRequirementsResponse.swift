//
//  RetrieveKYCRequirementsResponse.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/3/26.
//

import Foundation

/// A response from `/v1/crypto/internal/kyc_requirements` containing the authenticated customer's additional KYC requirements.
struct RetrieveKYCRequirementsResponse: Decodable, Equatable {

    /// A collection of partner-specific KYC requirements returned for an authenticated customer.
    struct Requirements: Decodable, Equatable {

        /// The individual requirements associated with the customer.
        let entries: [AdditionalKYCRequirement]
    }

    /// The customer's current additional KYC requirements.
    let requirements: Requirements
}

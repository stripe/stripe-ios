//
//  AdditionalKYCRequirements.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/20/26.
//

import Foundation

/// A collection of partner-specific KYC requirements returned for a CryptoCustomer.
struct AdditionalKYCRequirements: Codable, Equatable {

    /// The individual requirements associated with the customer.
    let entries: [AdditionalKYCRequirement]
}

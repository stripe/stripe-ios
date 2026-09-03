//
//  RetrieveCryptoCustomerResponse.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/3/26.
//

import Foundation

/// A response from `/v1/crypto/internal/customer` containing the authenticated customer's additional KYC requirements.
struct RetrieveCryptoCustomerResponse: Decodable, Equatable {

    /// The customer's current additional KYC requirements.
    let requirements: AdditionalKYCRequirements
}

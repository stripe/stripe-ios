//
//  KYCDataCollectionResponse.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/4/25.
//

import Foundation

/// Codable model representing a response from the `/v1/crypto/internal/kyc_data_collection` endpoint.
struct KYCDataCollectionResponse: Codable {
    let personId: String
    let firstName: String
    let lastName: String
    let nationalities: [String]
    let residenceCountry: String

    // MARK: - Decodable

    private enum CodingKeys: String, CodingKey {
        case personId = "person_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case nationalities
        case residenceCountry = "residence_country"
    }
}

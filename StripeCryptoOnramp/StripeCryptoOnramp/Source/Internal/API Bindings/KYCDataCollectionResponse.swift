//
//  KYCDataCollectionResponse.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/4/25.
//

import Foundation

/// Codable model representing a response from the `/v1/crypto/internal/kyc_data_collection` endpoint.
struct KYCDataCollectionResponse: Codable {

    /// The identifier of the user.
    let personId: String

    /// The user’s first name.
    let firstName: String?

    /// The user’s last name.
    let lastName: String?

    /// A list of the user’s nationalities, if any were provided.
    let nationalities: [String]?

    /// The country in which the user currently resides.
    let residenceCountry: String?

    // MARK: - Decodable

    private enum CodingKeys: String, CodingKey {
        case personId = "person_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case nationalities
        case residenceCountry = "residence_country"
    }
}

//
//  KYCDataCollectionRequest.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/4/25.
//

import Foundation

/// Encodable model passed to the `/v1/crypto/internal/kyc_data_collection` endpoint.
struct KYCDataCollectionRequest: Encodable {

    /// Contains credentials required to make the request.
    let credentials: Credentials

    /// KYC information required for crypto operations.
    let kycInfo: KycInfo

    // MARK: - Encodable

    enum CodingKeys: String, CodingKey {
        case credentials
        case firstName = "first_name"
        case lastName = "last_name"
        case idNumber = "id_number"
        case idType = "id_type"
        case line1
        case line2
        case city
        case state
        case zip
        case country
        case dob
        case birthCountry = "birth_country"
        case birthCity = "birth_city"
        case nationalities
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(credentials, forKey: .credentials)

        let firstName = kycInfo.firstName?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let firstName, !firstName.isEmpty {
            try container.encode(firstName, forKey: .firstName)
        }

        let lastName = kycInfo.lastName?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let lastName, !lastName.isEmpty {
            try container.encode(lastName, forKey: .lastName)
        }

        try container.encodeIfPresent(kycInfo.idNumber, forKey: .idNumber)
        if kycInfo.idNumber != nil {
            try container.encode(kycInfo.idType.rawValue, forKey: .idType)
        }

        try container.encodeIfPresent(kycInfo.address?.line1, forKey: .line1)
        try container.encodeIfPresent(kycInfo.address?.line2, forKey: .line2)
        try container.encodeIfPresent(kycInfo.address?.city, forKey: .city)
        try container.encodeIfPresent(kycInfo.address?.state, forKey: .state)
        try container.encodeIfPresent(kycInfo.address?.postalCode, forKey: .zip)
        try container.encodeIfPresent(kycInfo.address?.country, forKey: .country)
        try container.encodeIfPresent(kycInfo.dateOfBirth, forKey: .dob)
        try container.encodeIfPresent(kycInfo.birthCountry, forKey: .birthCountry)
        try container.encodeIfPresent(kycInfo.birthCity, forKey: .birthCity)

        let nationalities = kycInfo.nationalities?
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if let nationalities, !nationalities.isEmpty {
            try container.encode(nationalities, forKey: .nationalities)
        }
    }
}

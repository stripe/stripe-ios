//
//  KYCRefreshRequest.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 10/27/25.
//

import Foundation

/// Encodable model passed to the `/v1/crypto/internal/refresh_consumer_person` endpoint.
struct KYCRefreshRequest: Encodable {

    /// Contains credentials required to make the request.
    let credentials: Credentials

    /// KYC-related info required to make the request.
    let kycInfo: KYCRefreshInfo

    // MARK: - Encodable

    enum CodingKeys: String, CodingKey {
        case credentials
        case firstName = "first_name"
        case lastName = "last_name"
        case idNumberLast4 = "id_number_last4"
        case idType = "id_type"
        case line1
        case line2
        case city
        case state
        case zip
        case country
        case dob
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(credentials, forKey: .credentials)
        try container.encode(kycInfo.firstName, forKey: .firstName)
        try container.encode(kycInfo.lastName, forKey: .lastName)
        try container.encode(kycInfo.dateOfBirth, forKey: .dob)
        try container.encode(kycInfo.idNumberLast4, forKey: .idNumberLast4)
        try container.encode(kycInfo.idType, forKey: .idType)
        try container.encodeIfPresent(kycInfo.address.line1, forKey: .line1)
        try container.encodeIfPresent(kycInfo.address.line2, forKey: .line2)
        try container.encodeIfPresent(kycInfo.address.city, forKey: .city)
        try container.encodeIfPresent(kycInfo.address.state, forKey: .state)
        try container.encodeIfPresent(kycInfo.address.postalCode, forKey: .zip)
        try container.encodeIfPresent(kycInfo.address.country, forKey: .country)
    }
}


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

    /// The calendar to use to convert the user’s date of birth (`KycInfo.dateOfBirth`) to components compatible with the API.
    let calendar: Calendar

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
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(credentials, forKey: .credentials)

        try container.encode(kycInfo.firstName, forKey: .firstName)
        try container.encode(kycInfo.lastName, forKey: .lastName)

        try container.encode(kycInfo.idNumber, forKey: .idNumber)
        try container.encode(kycInfo.idType.rawValue, forKey: .idType)

        try container.encodeIfPresent(kycInfo.address.line1, forKey: .line1)
        try container.encodeIfPresent(kycInfo.address.line2, forKey: .line2)
        try container.encodeIfPresent(kycInfo.address.city, forKey: .city)
        try container.encodeIfPresent(kycInfo.address.state, forKey: .state)
        try container.encodeIfPresent(kycInfo.address.postalCode, forKey: .zip)
        try container.encodeIfPresent(kycInfo.address.country, forKey: .country)

        let dateOfBirth = DateOfBirth(from: kycInfo.dateOfBirth, calendar: calendar)
        try container.encode(dateOfBirth, forKey: .dob)
    }
}

/// Intermediate model for custom `Date` encoding.
/// - Note:`StripeJSONEncoder` does not implement `nestedContainer(keyedBy:)` to keep the implementation contained in `KYCDataCollectionRequest`, so we use a separate model to split apart the date components.
private struct DateOfBirth: Encodable {
    let day: Int
    let month: Int
    let year: Int

    init(from date: Date, calendar: Calendar) {
        let components = calendar.dateComponents([.day, .month, .year], from: date)
        self.day = components.day ?? 0
        self.month = components.month ?? 0
        self.year = components.year ?? 0
    }
}

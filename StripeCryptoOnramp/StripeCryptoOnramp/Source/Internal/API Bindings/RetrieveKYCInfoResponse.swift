//
//  RetrieveKYCInfoResponse.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 10/27/25.
//

import Foundation

/// Decodable model representing a response from the `/v1/crypto/internal/kyc_data_retrieve` endpoint.
struct RetrieveKYCInfoResponse: Decodable {

    /// The KYC info retrieved from the API.
    let kycInfo: KycRefreshInfo

    // MARK: - Decodable

    private enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case dob
        case address
        case idNumberLast4 = "id_number_last4"
        case idType = "id_type"
    }

    private enum AddressKeys: String, CodingKey {
        case line1, line2, city, state, zip, country
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let firstName = try container.decode(String.self, forKey: .firstName)
        let lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        let dateOfBirth = try container.decode(KycInfo.DateOfBirth.self, forKey: .dob)
        let idNumberLast4 = try container.decode(String.self, forKey: .idNumberLast4)
        let idType = try container.decode(IdType.self, forKey: .idType)
        let addressContainer = try container.nestedContainer(keyedBy: AddressKeys.self, forKey: .address)

        let address = Address(
            city: try addressContainer.decode(String.self, forKey: .city),
            country: try addressContainer.decode(String.self, forKey: .country),
            line1: try addressContainer.decode(String.self, forKey: .line1),
            line2: try addressContainer.decodeIfPresent(String.self, forKey: .line2),
            postalCode: try addressContainer.decode(String.self, forKey: .zip),
            state: try addressContainer.decode(String.self, forKey: .state)
        )

        kycInfo = KycRefreshInfo(
            firstName: firstName,
            lastName: lastName,
            dateOfBirth: dateOfBirth,
            address: address,
            idNumberLast4: idNumberLast4,
            idType: idType
        )
    }
}

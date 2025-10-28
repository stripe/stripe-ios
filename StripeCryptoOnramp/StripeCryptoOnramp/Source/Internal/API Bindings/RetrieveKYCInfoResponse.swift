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
    let kycInfo: KYCRefreshInfo

    /// Creates a new instance of `RetrieveKYCInfoResponse`.
    /// - Parameter kycInfo: The `KYCRefreshInfo` instance containing the user’s information.
    init(kycInfo: KYCRefreshInfo) {
        self.kycInfo = kycInfo
    }

    // MARK: - Decodable

    private enum CodingKeys: String, CodingKey {
        case firstName
        case lastName
        case dob
        case address
        case idNumberLast4 = "id_number_last4"
        case idType
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let firstName = try container.decode(String.self, forKey: .firstName)
        let lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        let dateOfBirth = try container.decode(KycInfo.DateOfBirth.self, forKey: .dob)
        let idNumberLast4 = try container.decode(String.self, forKey: .idNumberLast4)
        let idType = try container.decode(IdType.self, forKey: .idType)
        let address = try container.decode(Address.self, forKey: .address)

        kycInfo = KYCRefreshInfo(
            firstName: firstName,
            lastName: lastName,
            dateOfBirth: dateOfBirth,
            address: address,
            idNumberLast4: idNumberLast4,
            idType: idType
        )
    }
}

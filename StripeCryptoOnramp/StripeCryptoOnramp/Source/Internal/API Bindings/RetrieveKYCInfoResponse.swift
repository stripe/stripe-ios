//
//  RetrieveKYCInfoResponse.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 10/27/25.
//

import Foundation

/// Decodable model representing a response from the `/v1/crypto/internal/kyc_data_retrieve` endpoint.
struct RetrieveKYCInfoResponse: Decodable {

    /// Represents a user’s address.
    struct Address: Decodable {

        /// Address line 1 (e.g., street, PO Box, or company name).
        let line1: String

        /// Address line 2 (e.g., apartment, suite, unit, or building).
        let line2: String?

        /// City, district, suburb, town, or village.
        let city: String

        /// State, county, province, or region.
        let state: String

        /// Zip or postal code.
        let zip: String

        /// Two-letter country code (ISO 3166-1 alpha-2).
        let country: String
    }

    /// The user’s first name.
    let firstName: String

    /// The user’s last name.
    let lastName: String?

    /// The user’s birth date in the format: //TODO: inspect response
    let dob: String

    /// The user’s address.
    let address: Address

    /// The last four digits of the user’s id number.
    let idNumberLast4: String

    /// The type of the id number.
    let idType: String

    // MARK: - Decodable

    private enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case dob
        case address
        case idNumberLast4 = "id_number_last4"
        case idType = "id_type"
    }
}

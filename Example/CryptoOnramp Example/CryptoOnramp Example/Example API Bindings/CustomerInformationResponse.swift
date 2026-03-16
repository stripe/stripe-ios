//
//  CustomerInformationResponse.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 8/19/25.
//

import Foundation

struct CustomerInformationResponse: Decodable {
    struct Verification: Decodable {
        let errors: [String]
        let name: String
        let status: String
    }

    let id: String
    let object: String
    let providedFields: [String]
    let verifications: [Verification]
}

extension CustomerInformationResponse {
    private static let level0RequiredFields: Set<String> = [
        "first_name",
        "last_name",
        "address_line_1",
        "address_city",
        "address_state",
        "address_postal_code",
        "address_country",
    ]

    private static let level1AdditionalFields: Set<String> = [
        "dob",
        "id_number",
    ]

    private static let level2AdditionalFields: Set<String> = [
        "id_document",
        "selfie",
    ]

    var isIdDocumentVerified: Bool {
        verifications.contains { $0.name == "id_document_verified" && $0.status == "verified" }
    }

    var isKycVerified: Bool {
        verifications.contains { $0.name == "kyc_verified" && $0.status == "verified" }
    }

    /// The KYC level implied solely by the fields the customer has already provided.
    var providedKYCLevel: KYCLevel {
        let providedFieldSet = Set(providedFields)

        guard providedFieldSet.isSuperset(of: Self.level0RequiredFields) else {
            return .none
        }

        guard providedFieldSet.isSuperset(of: Self.level1AdditionalFields) else {
            return .level0
        }

        guard providedFieldSet.isSuperset(of: Self.level2AdditionalFields) else {
            return .level1
        }

        return .level2
    }

    /// The current effective KYC level, accounting for verification state where needed.
    var kycLevel: KYCLevel {
        switch providedKYCLevel {
        case .none, .level0:
            providedKYCLevel
        case .level1, .level2:
            isIdDocumentVerified ? .level2 : .level1
        }
    }
}

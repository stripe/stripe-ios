//
//  CustomerInformationResponse.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 8/19/25.
//

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

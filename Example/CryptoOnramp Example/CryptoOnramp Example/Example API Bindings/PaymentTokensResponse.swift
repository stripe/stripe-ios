//
//  PaymentTokensResponse.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 8/19/25.
//

import Foundation

struct PaymentTokensResponse: Decodable {
    struct Card: Decodable {
        let brand: String
        let expMonth: Int
        let expYear: Int
        let funding: String
        let last4: String
        let wallet: String?
    }

    struct PaymentToken: Decodable {
        let id: String
        let object: String
        let card: Card?
        let type: String
        let usBankAccount: String?
    }

    let object: String
    let data: [PaymentToken]
}

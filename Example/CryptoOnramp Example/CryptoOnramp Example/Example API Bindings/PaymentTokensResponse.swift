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

    struct BankAccount: Decodable {
        let accountType: String
        let bankName: String
        let last4: String
    }

    struct PaymentToken: Decodable, Identifiable {
        let id: String
        let object: String
        let card: Card?
        let type: String
        let usBankAccount: BankAccount?
    }

    let object: String
    let data: [PaymentToken]
}

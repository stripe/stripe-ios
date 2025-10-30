//
//  UserInformationResponse.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 8/19/25.
//

import Foundation

struct UserInformationResponse: Decodable {
    struct OAuth: Decodable {
        let clientId: String
        let scopes: String
    }

    let id: String
    let state: String
    let oauth: OAuth
    let createdAt: Date
    let expiresAt: Date
    let email: String
}

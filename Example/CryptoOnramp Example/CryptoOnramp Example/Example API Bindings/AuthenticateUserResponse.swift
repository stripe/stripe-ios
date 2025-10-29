//
//  AuthenticateUserResponse.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 8/18/25.
//

import Foundation

struct AuthenticateUserResponse: Decodable {
    struct DataBlock: Decodable {
        let id: String
        let expiresAt: Date
    }

    let data: DataBlock
    let token: String
}

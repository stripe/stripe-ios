//
//  SignUpResponse.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 10/15/25.
//

import Foundation

typealias LogInResponse = SignUpResponse

struct SignUpResponse: Decodable {
    struct User: Decodable {
        let userId: Int
        let email: String
        let createdAt: Date
    }

    let success: Bool
    let token: String
    let user: User
}

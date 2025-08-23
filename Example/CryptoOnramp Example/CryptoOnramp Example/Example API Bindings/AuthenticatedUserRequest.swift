//
//  AuthenticatedUserRequest.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 8/19/25.
//

import Foundation

struct AuthenticateUserRequest: Encodable {
    let email: String
    let oauthScopes: String = "userinfo:read"

    enum CodingKeys: String, CodingKey {
        case email
        case oauthScopes = "oauth_scopes"
    }
}

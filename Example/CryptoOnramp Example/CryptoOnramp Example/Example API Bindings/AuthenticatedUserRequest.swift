//
//  AuthenticatedUserRequest.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 8/19/25.
//

import Foundation

struct AuthenticateUserRequest: Encodable {
    let email: String
    let oauthScopes: String

    enum CodingKeys: String, CodingKey {
        case email
        case oauthScopes = "oauth_scopes"
    }

    init(email: String, oauthScopes: [String] = AuthenticateUserRequest.allScopes) {
        self.email = email
        self.oauthScopes = oauthScopes.joined(separator: ",")
    }
}

extension AuthenticateUserRequest {
    static let allScopes: [String] = [
        "userinfo:read",
        "userinfo.addresses:read",
        "kyc.status:read",
        "kyc:write",
        "kyc:read",
        "kyc:share",
        "auth.persist_login:read",
        "payment_methods:read",
        "payment_methods.bank_accounts:read",
        "read_email",
        "read_phone",
        "share_full_name",
        "share_full_name",
        "share_email",
        "share_address",
    ]
}

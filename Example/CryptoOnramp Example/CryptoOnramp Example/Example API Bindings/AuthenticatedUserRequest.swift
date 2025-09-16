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
    let livemode: Bool

    enum CodingKeys: String, CodingKey {
        case email
        case oauthScopes = "oauth_scopes"
        case livemode
    }

    init(
        email: String,
        oauthScopes: [OAuthScopes] = OAuthScopes.requiredScopes,
        livemode: Bool
    ) {
        self.email = email
        self.oauthScopes = oauthScopes.map(\.rawValue).joined(separator: ",")
        self.livemode = livemode
    }
}

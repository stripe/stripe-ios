//
//  APIClient+Auth.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 8/18/25.
//

import Foundation

extension APIClient {
    func authenticateUser(with email: String) async throws -> AuthenticateUserResponse {
        try await request("auth_intent/create", method: .POST, body: AuthenticateUserRequest(email: email))
    }
}

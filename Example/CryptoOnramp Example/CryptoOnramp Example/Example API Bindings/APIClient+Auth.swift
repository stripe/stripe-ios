//
//  APIClient+Auth.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 8/18/25.
//

import Foundation

extension APIClient {
    func authenticateUser(
        with email: String,
        oauthScopes: [OAuthScopes] = OAuthScopes.requiredScopes,
        livemode: Bool
    ) async throws -> AuthenticateUserResponse {
        let response: AuthenticateUserResponse = try await request(
            "auth_intent/create",
            method: .POST,
            body: AuthenticateUserRequest(
                email: email,
                oauthScopes: oauthScopes,
                livemode: livemode
            )
        )
        setAuthToken(response.token)
        return response
    }

    func fetchUserInformation() async throws -> UserInformationResponse {
        guard let token = authToken else { throw APIError.missingAuthToken }
        return try await request("auth_intent/read", method: .GET, bearerToken: token)
    }
}

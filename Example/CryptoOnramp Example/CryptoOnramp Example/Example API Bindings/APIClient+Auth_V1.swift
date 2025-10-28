//
//  APIClient+Auth_V1.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 10/15/25.
//

import Foundation

extension APIClient {
    @discardableResult
    func signUp(email: String, password: String, livemode: Bool) async throws -> SignUpResponse {
        let signUpRequest = SignUpRequest(email: email, password: password, livemode: livemode)
        let response: SignUpResponse = try await request("v1/auth/signup", method: .POST, body: signUpRequest)
        setAuthToken(response.token)
        return response
    }

    @discardableResult
    func logIn(email: String, password: String, livemode: Bool) async throws -> LogInResponse {
        let logInRequest = LogInRequest(email: email, password: password, livemode: livemode)
        let response: LogInResponse = try await request("v1/auth/login", method: .POST, body: logInRequest)
        setAuthToken(response.token)
        return response
    }

    func createAuthIntent(oauthScopes: [OAuthScopes] = OAuthScopes.requiredScopes) async throws -> CreateAuthIntentResponse {
        guard let token = authToken else { throw APIError.missingAuthToken }
        let createAuthIntentRequest = CreateAuthIntentRequest(oauthScopes: oauthScopes)
        let response: CreateAuthIntentResponse = try await request(
            "v1/auth/create",
            method: .POST,
            body: createAuthIntentRequest,
            bearerToken: token
        )
        setAuthTokenWithLAI(response.token)
        return response
    }

    @discardableResult
    func saveUser(cryptoCustomerId: String) async throws -> SaveUserResponse {
        guard let token = authTokenWithLAI else { throw APIError.missingAuthTokenWithLAI }
        let saveUserRequest = SaveUserRequest(cryptoCustomerId: cryptoCustomerId)
        return try await request("v1/auth/save_user", method: .POST, body: saveUserRequest, bearerToken: token)
    }

    func createLinkAuthToken() async throws -> CreateLinkAuthTokenResponse {
        guard let token = authTokenWithLAI else { throw APIError.missingAuthTokenWithLAI }
        return try await request("v1/auth/create_link_auth_token", method: .POST, bearerToken: token)
    }

    func fetchCryptoCustomerId() async throws -> CryptoCustomerIdResponse {
        guard let token = authTokenWithLAI else { throw APIError.missingAuthTokenWithLAI }
        return try await request("v1/auth/crypto_customer", bearerToken: token)
    }
}

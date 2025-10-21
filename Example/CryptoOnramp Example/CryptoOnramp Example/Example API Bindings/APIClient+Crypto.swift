//
//  APIClient+Crypto.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 8/19/25.
//

import Foundation

extension APIClient {
    func fetchCustomerInfo(cryptoCustomerToken: String) async throws -> CustomerInformationResponse {
        guard let token = authToken else { throw APIError.missingAuthToken }
        return try await request("customer_info", bearerToken: token, queryItems: [.cryptoCustomerToken(cryptoCustomerToken)])
    }

    func fetchCustomerWallets(cryptoCustomerToken: String) async throws -> CustomerWalletsResponse {
        guard let token = authToken else { throw APIError.missingAuthToken }
        return try await request("customer_wallets", bearerToken: token, queryItems: [
            .cryptoCustomerToken(cryptoCustomerToken),
            .pageSize(50),
        ])
    }

    func fetchPaymentTokens(cryptoCustomerToken: String) async throws -> PaymentTokensResponse {
        guard let token = authToken else { throw APIError.missingAuthToken }
        return try await request("payment_tokens", bearerToken: token, queryItems: [
            .cryptoCustomerToken(cryptoCustomerToken),
            .pageSize(50),
        ])
    }

    func createOnrampSession(requestObject: CreateOnrampSessionRequest, useV1API: Bool = false) async throws -> CreateOnrampSessionResponse {
        let path = useV1API ? "v1/create_onramp_session" : "create_onramp_session"
        let token = useV1API ? authTokenWithLAI : authToken
        guard let token else { throw useV1API ? APIError.missingAuthTokenWithLAI : APIError.missingAuthToken }
        return try await request(path, method: .POST, body: requestObject, bearerToken: token)
    }

    @discardableResult
    func refreshQuote(onrampSessionId: String, useV1API: Bool = false) async throws -> QuoteResponse {
        let path = useV1API ? "v1/quote" : "quote"
        let token = useV1API ? authTokenWithLAI : authToken
        guard let token else { throw useV1API ? APIError.missingAuthTokenWithLAI : APIError.missingAuthToken }
        return try await request(path, method: .POST, body: QuoteRequest(cryptoOnrampSessionId: onrampSessionId), bearerToken: token)
    }

    func checkout(onrampSessionId: String, useV1API: Bool = false) async throws -> CheckoutResponse {
        let path = useV1API ? "v1/checkout" : "checkout"
        let token = useV1API ? authTokenWithLAI : authToken
        guard let token else { throw useV1API ? APIError.missingAuthTokenWithLAI : APIError.missingAuthToken }
        return try await request(path, method: .POST, body: CheckoutRequest(cryptoOnrampSessionId: onrampSessionId), bearerToken: token)
    }

    func fetchSessionStatus(cryptoOnrampSessionId: String) async throws -> SessionStatusResponse {
        guard let token = authToken else { throw APIError.missingAuthToken }
        let path = "session_status/\(cryptoOnrampSessionId)"
        return try await request(path, bearerToken: token)
    }
}

private extension URLQueryItem {
    static func cryptoCustomerToken(_ value: String) -> URLQueryItem {
        URLQueryItem(name: "crypto_customer_token", value: value)
    }

    static func pageSize(_ value: Int) -> URLQueryItem {
        URLQueryItem(name: "limit", value: String(value))
    }
}

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

    func createOnrampSession(requestObject: CreateOnrampSessionRequest) async throws -> CreateOnrampSessionResponse {
        guard let token = authToken else { throw APIError.missingAuthToken }
        return try await request("create_onramp_session", method: .POST, body: requestObject, bearerToken: token)
    }

    func createQuote(requestObject: QuoteRequest) async throws -> QuoteResponse {
        guard let token = authToken else { throw APIError.missingAuthToken }
        return try await request("quote", method: .POST, body: requestObject, bearerToken: token)
    }

    func checkout(requestObject: CheckoutRequest) async throws -> CheckoutResponse {
        guard let token = authToken else { throw APIError.missingAuthToken }
        return try await request("checkout", method: .POST, body: requestObject, bearerToken: token)
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

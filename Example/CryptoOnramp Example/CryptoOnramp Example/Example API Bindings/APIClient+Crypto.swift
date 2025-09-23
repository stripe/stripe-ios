//
//  APIClient+Crypto.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 8/19/25.
//

import Foundation

extension APIClient {

    /// No-cache headers to ensure fresh data
    private var noCacheHeaders: [String: String] {
        [
            "Cache-Control": "no-cache, no-store, must-revalidate",
            "Pragma": "no-cache",
            "Expires": "0",
        ]
    }
    func fetchCustomerInfo(cryptoCustomerToken: String) async throws -> CustomerInformationResponse {
        guard let token = authToken else { throw APIError.missingAuthToken }
        return try await request("customer_info", bearerToken: token, headers: noCacheHeaders, queryItems: [.cryptoCustomerToken(cryptoCustomerToken)])
    }

    func fetchCustomerWallets(cryptoCustomerToken: String) async throws -> CustomerWalletsResponse {
        guard let token = authToken else { throw APIError.missingAuthToken }
        return try await request("customer_wallets", bearerToken: token, headers: noCacheHeaders, queryItems: [
            .cryptoCustomerToken(cryptoCustomerToken),
            .pageSize(50),
        ])
    }

    func fetchPaymentTokens(cryptoCustomerToken: String) async throws -> PaymentTokensResponse {
        guard let token = authToken else { throw APIError.missingAuthToken }
        return try await request("payment_tokens", bearerToken: token, headers: noCacheHeaders, queryItems: [
            .cryptoCustomerToken(cryptoCustomerToken),
            .pageSize(50),
        ])
    }

    func createOnrampSession(requestObject: CreateOnrampSessionRequest) async throws -> CreateOnrampSessionResponse {
        guard let token = authToken else { throw APIError.missingAuthToken }
        return try await request("create_onramp_session", method: .POST, body: requestObject, bearerToken: token, headers: noCacheHeaders)
    }

    @discardableResult
    func refreshQuote(onrampSessionId: String) async throws -> QuoteResponse {
        guard let token = authToken else { throw APIError.missingAuthToken }
        return try await request("quote", method: .POST, body: QuoteRequest(cryptoOnrampSessionId: onrampSessionId), bearerToken: token, headers: noCacheHeaders)
    }

    func checkout(onrampSessionId: String) async throws -> CheckoutResponse {
        guard let token = authToken else { throw APIError.missingAuthToken }
        return try await request("checkout", method: .POST, body: CheckoutRequest(cryptoOnrampSessionId: onrampSessionId), bearerToken: token, headers: noCacheHeaders)
    }

    func fetchSessionStatus(cryptoOnrampSessionId: String) async throws -> SessionStatusResponse {
        guard let token = authToken else { throw APIError.missingAuthToken }
        let path = "session_status/\(cryptoOnrampSessionId)"
        return try await request(path, bearerToken: token, headers: noCacheHeaders)
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

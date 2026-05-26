//
//  APIClient+Crypto_V1.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 10/15/25.
//

import Foundation

extension APIClient {
    func fetchCustomerInfo() async throws -> CustomerInformationResponse {
        guard let token = authTokenWithLAI else { throw APIError.missingAuthTokenWithLAI }
        return try await request("v1/customer_info", bearerToken: token)
    }

    func fetchCustomerWallets() async throws -> CustomerWalletsResponse {
        guard let token = authTokenWithLAI else { throw APIError.missingAuthTokenWithLAI }
        return try await request("v1/customer_wallets", bearerToken: token, queryItems: [.pageSize(50)])
    }

    func fetchPaymentTokens() async throws -> PaymentTokensResponse {
        guard let token = authTokenWithLAI else { throw APIError.missingAuthTokenWithLAI }
        return try await request("v1/payment_tokens", bearerToken: token, queryItems: [.pageSize(50)])
    }

    func createOnrampSession(requestObject: CreateOnrampSessionRequest) async throws -> CreateOnrampSessionResponse {
        guard let token = authTokenWithLAI else { throw APIError.missingAuthTokenWithLAI }
        return try await request("v1/create_onramp_session", method: .POST, body: requestObject, bearerToken: token)
    }

    @discardableResult
    func refreshQuote(onrampSessionId: String) async throws -> QuoteResponse {
        guard let token = authTokenWithLAI else { throw APIError.missingAuthTokenWithLAI }
        return try await request("v1/quote", method: .POST, body: QuoteRequest(cryptoOnrampSessionId: onrampSessionId), bearerToken: token)
    }

    func checkout(onrampSessionId: String) async throws -> CheckoutResponse {
        guard let token = authTokenWithLAI else { throw APIError.missingAuthTokenWithLAI }
        return try await request("v1/checkout", method: .POST, body: CheckoutRequest(cryptoOnrampSessionId: onrampSessionId), bearerToken: token)
    }
}

private extension URLQueryItem {
    static func pageSize(_ value: Int) -> URLQueryItem {
        URLQueryItem(name: "limit", value: String(value))
    }
}

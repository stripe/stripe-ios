//
//  APIClient+Crypto_V1.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 10/15/25.
//

import Foundation

extension APIClient {
    func fetchCustomerInfo() async throws -> CustomerInformationResponse {
        try await withLinkAuthorization { token in
            try await request("v1/customer_info", bearerToken: token)
        }
    }

    func fetchCustomerWallets() async throws -> CustomerWalletsResponse {
        try await withLinkAuthorization { token in
            try await request("v1/customer_wallets", bearerToken: token, queryItems: [.pageSize(50)])
        }
    }

    func fetchPaymentTokens() async throws -> PaymentTokensResponse {
        try await withLinkAuthorization { token in
            try await request("v1/payment_tokens", bearerToken: token, queryItems: [.pageSize(50)])
        }
    }

    func createOnrampSession(requestObject: CreateOnrampSessionRequest) async throws -> CreateOnrampSessionResponse {
        try await withLinkAuthorization(retryAfterReauthorization: false) { token in
            try await request("v1/create_onramp_session", method: .POST, body: requestObject, bearerToken: token)
        }
    }

    @discardableResult
    func refreshQuote(onrampSessionId: String) async throws -> QuoteResponse {
        try await withLinkAuthorization(retryAfterReauthorization: false) { token in
            try await request("v1/quote", method: .POST, body: QuoteRequest(cryptoOnrampSessionId: onrampSessionId), bearerToken: token)
        }
    }

    func checkout(onrampSessionId: String) async throws -> CheckoutResponse {
        try await withLinkAuthorization(retryAfterReauthorization: false) { token in
            try await request("v1/checkout", method: .POST, body: CheckoutRequest(cryptoOnrampSessionId: onrampSessionId), bearerToken: token)
        }
    }
}

private extension URLQueryItem {
    static func pageSize(_ value: Int) -> URLQueryItem {
        URLQueryItem(name: "limit", value: String(value))
    }
}

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
        return try await request("customer_info", bearerToken: token, queryItems: [
            URLQueryItem(name: "crypto_customer_token", value: cryptoCustomerToken)
        ])
    }
}


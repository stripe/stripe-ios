//
//  FCLiteAPIClient.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 2025-03-12.
//

import Foundation
@_spi(STP) import StripeCore

struct FCLiteAPIClient {
    private enum Endpoint {
        case synchronize
        case sessionReceipt

        var path: String {
            switch self {
            case .synchronize: "financial_connections/sessions/synchronize"
            case .sessionReceipt: "link_account_sessions/session_receipt"
            }
        }
    }

    private let backingAPIClient: STPAPIClient

    init(backingAPIClient: STPAPIClient) {
        self.backingAPIClient = backingAPIClient
    }

    private func get<T: Decodable>(
        endpoint: Endpoint,
        parameters: [String: Any]
    ) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            backingAPIClient.get(
                resource: endpoint.path,
                parameters: parameters,
                completion: { (result: Result<T, Error>) in
                    switch result {
                    case .success(let response):
                        continuation.resume(returning: response)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            )
        }
    }

    private func post<T: Decodable>(
        endpoint: Endpoint,
        parameters: [String: Any]
    ) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            backingAPIClient.post(
                resource: endpoint.path,
                parameters: parameters,
                completion: { (result: Result<T, Error>) in
                    switch result {
                    case .success(let response):
                        continuation.resume(returning: response)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            )
        }
    }
}

extension FCLiteAPIClient {
    func synchronize(
        clientSecret: String,
        returnUrl: URL
    ) async throws -> SynchronizePayload {
        let mobileParameters: [String: Any] = [
            "fullscreen": true,
            "app_return_url": returnUrl,
            "mobile_sdk_type": "FC_LITE",
        ]
        let parameters: [String: Any] = [
            "client_secret": clientSecret,
            "mobile": mobileParameters,
        ]
        return try await post(endpoint: .synchronize, parameters: parameters)
    }

    func sessionReceipt(
        clientSecret: String
    ) async throws -> FinancialConnectionsSession {
        let parameters: [String: Any] = [
            "client_secret": clientSecret,
        ]
        return try await get(endpoint: .sessionReceipt, parameters: parameters)
    }
}

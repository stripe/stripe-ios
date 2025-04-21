//
//  FCLiteApiClient.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 2025-03-19.
//

import Foundation
@_spi(STP) import StripeCore

struct FCLiteAPIClient {
    private enum Endpoint {
        case synchronize
        case sessionReceipt
        case complete

        var path: String {
            switch self {
            case .synchronize: "financial_connections/sessions/synchronize"
            case .sessionReceipt: "link_account_sessions/session_receipt"
            case .complete: "link_account_sessions/complete"
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
        returnUrl: URL?
    ) async throws -> SynchronizePayload {
        var mobileParameters: [String: Any] = [
            "fullscreen": true,
            "mobile_sdk_type": "FC_LITE",
        ]
        mobileParameters["app_return_url"] = returnUrl

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

    func complete(
        clientSecret: String
    ) async throws -> FinancialConnectionsSession {
        let parameters: [String: Any] = [
            "client_secret": clientSecret,
        ]
        return try await post(endpoint: .complete, parameters: parameters)
    }
}

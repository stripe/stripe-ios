//
//  STPAPIClient+Concurrency.swift
//  StripeIdentity
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

extension STPAPIClient {
    func get<T: Decodable>(
        resource: String,
        parameters: [String: Any],
        ephemeralKeySecret: String? = nil,
        consumerPublishableKey: String? = nil
    ) async throws -> T {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<T, Error>) in
            get(
                resource: resource,
                parameters: parameters,
                ephemeralKeySecret: ephemeralKeySecret,
                consumerPublishableKey: consumerPublishableKey,
                completion: { result in
                    continuation.resume(with: result)
                }
            )
        }
    }

    func post<T: Decodable>(
        resource: String,
        parameters: [String: Any],
        ephemeralKeySecret: String? = nil,
        consumerPublishableKey: String? = nil
    ) async throws -> T {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<T, Error>) in
            post(
                resource: resource,
                parameters: parameters,
                ephemeralKeySecret: ephemeralKeySecret,
                consumerPublishableKey: consumerPublishableKey,
                completion: { result in
                    continuation.resume(with: result)
                }
            )
        }
    }

    func post<I: Encodable, O: Decodable>(
        resource: String,
        object: I,
        ephemeralKeySecret: String? = nil
    ) async throws -> O {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<O, Error>) in
            post(
                resource: resource,
                object: object,
                ephemeralKeySecret: ephemeralKeySecret,
                completion: { result in
                    continuation.resume(with: result)
                }
            )
        }
    }
}

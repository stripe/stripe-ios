//
//  STPAPIClient+USPaperChecks.swift
//  StripePayments
//
//  Created by Martin Gordon on 8/6/25.
//  Copyright © 2025 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

extension STPAPIClient {
    /// Creates a US Paper Check.
    ///
    /// - Note: See https://docs.stripe.com/api/us_paper_checks/create
    ///
    /// - Parameters:
    ///    - params: The parameters for creating the paper check
    ///    - completion: The callback to run with the returned `STPUSPaperCheck` (and any errors that may have occurred).
    @_spi(STP) public func createUSPaperCheck(
        with params: STPUSPaperCheckCreateParams,
        ephemeralKeySecret: String,
        completion: @escaping STPUSPaperCheckCompletionBlock
    ) {
        self.post(resource: APIEndpointUSPaperChecks, object: params, ephemeralKeySecret: ephemeralKeySecret) { (result: Result<STPUSPaperCheck, Error>) in
            switch result {
            case .success(let paperCheck):
                completion(paperCheck, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
    
    /// Async helper version of `createUSPaperCheck`
    @_spi(STP) public func createUSPaperCheck(
        with params: STPUSPaperCheckCreateParams,
        ephemeralKeySecret: String
    ) async throws -> STPUSPaperCheck {
        return try await withCheckedThrowingContinuation { continuation in
            createUSPaperCheck(with: params, ephemeralKeySecret: ephemeralKeySecret) { paperCheck, error in
                if let paperCheck = paperCheck {
                    continuation.resume(with: .success(paperCheck))
                } else {
                    continuation.resume(with: .failure(error ?? NSError.stp_genericFailedToParseResponseError()))
                }
            }
        }
    }
}

@_spi(STP) public let APIEndpointUSPaperChecks = "us_paper_checks"

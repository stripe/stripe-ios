//
//  STPAPIClient+Identity.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 10/26/21.
//

import Foundation
@_spi(STP) import StripeCore

extension STPAPIClient {
    func postIdentityVerificationPage(
        clientSecret: String
    ) -> Promise<VerificationPage> {
        let promise = Promise<VerificationPage>()
        let completion: (Result<VerificationPage, Error>) -> Void = { result in
            switch result {
            case .success(let response):
                promise.resolve(with: response)
            case .failure(let error):
                promise.reject(with: error)
            }
        }
        self.post(
            resource: APIEndpointVerificationPage,
            parameters: ["client_secret": clientSecret],
            completion: completion
        )
        return promise
    }
}

private let APIEndpointVerificationPage = "identity/verification_pages"

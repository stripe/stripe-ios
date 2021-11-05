//
//  VerificationSheetController.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 10/7/21.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

final class VerificationSheetController {

    let addressSpecProvider: AddressSpecProvider
    var apiClient: IdentityAPIClient

    private(set) var verificationPage: VerificationPage?
    private(set) var lastError: Error?

    init(apiClient: IdentityAPIClient = STPAPIClient.shared,
         addressSpecProvider: AddressSpecProvider = .shared) {
        self.addressSpecProvider = addressSpecProvider
        self.apiClient = apiClient
    }

    func load(
        clientSecret: String,
        completion: @escaping () -> Void
    ) {
        // Start API request
        let verificationPagePromise = apiClient.postIdentityVerificationPage(clientSecret: clientSecret)

        // Start loading address specs
        addressSpecProvider.loadAddressSpecs().chained { _ in
            // Loading address spec finished.
            // API request may or may not have finished at this point, but returning
            // the API request promise means it's result will be observed below.
            return verificationPagePromise
        }.observe { [weak self] result in
            // API request finished
            guard let self = self else { return }

            switch result {
            case .success(let response):
                self.verificationPage = response
            case .failure(let error):
                // Error could be from any of the above chained promises
                self.lastError = error
            }

            // TODO(IDPROD-2539): Update initial screen with response data or error
            completion()
        }
    }
}

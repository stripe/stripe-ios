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
    let apiClient: STPAPIClient

    // TODO(mludowise|IDPROD-2734): Remove this property when endpoint is live
    private lazy var mockResponseLoadQueue = DispatchQueue(label: "com.stripe.StripeIdentity.VerificationSheetController", qos: .userInitiated)

    /**
     If using native iOS components (in development), load mock data from the local file system instead of making a live request.

     TODO(mludowise|IDPROD-2734): Remove this property when endpoint is live
     */
    var mockResponseFileURL: URL?

    private(set) var verificationPage: VerificationPage?
    private(set) var lastError: Error?

    init(apiClient: STPAPIClient = .shared,
         addressSpecProvider: AddressSpecProvider = .shared) {
        self.addressSpecProvider = addressSpecProvider
        self.apiClient = apiClient
    }

    func load(
        clientSecret: String,
        completion: @escaping () -> Void
    ) {
        // Start API request
        let verificationPagePromise = postIdentityVerificationPage(clientSecret: clientSecret)

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

    /*
     Helper function to load a mock response until our endpoint exists

     TODO(mludowise|IDPROD-2734): Remove this property when endpoint is live
     */
    private func postIdentityVerificationPage(clientSecret: String) -> Promise<VerificationPage> {
        guard let url = mockResponseFileURL else {
            return apiClient.postIdentityVerificationPage(clientSecret: clientSecret)
        }

        let promise = Promise<VerificationPage>()
        mockResponseLoadQueue.async {
            do {
                let mockData = try Data(contentsOf: url)
                let result: Result<VerificationPage, Error> = STPAPIClient.decodeResponse(data: mockData, error: nil)

                switch result {
                case .success(let verificationPage):
                    promise.resolve(with: verificationPage)
                case .failure(let error):
                    promise.reject(with: error)
                }
            } catch {
                promise.reject(with: error)
            }
        }
        return promise
    }
}

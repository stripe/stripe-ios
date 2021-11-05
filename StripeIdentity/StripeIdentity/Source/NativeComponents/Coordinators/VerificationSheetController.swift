//
//  VerificationSheetController.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 10/7/21.
//

import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

final class VerificationSheetController {

    let addressSpecProvider: AddressSpecProvider
    var apiClient: IdentityAPIClient
    let flowController = VerificationSheetFlowController()
    let dataStore = VerificationSessionDataStore()

    #if DEBUG
    // Make apiContent settable from tests

    /// Content returned from the API
    var apiContent = VerificationSheetAPIContent()
    #else
    private(set) var apiContent = VerificationSheetAPIContent()
    #endif

    init(apiClient: IdentityAPIClient = STPAPIClient.shared,
         addressSpecProvider: AddressSpecProvider = .shared) {
        self.addressSpecProvider = addressSpecProvider
        self.apiClient = apiClient
    }

    /// Makes API calls to load the verification sheet. When the API response is complete, transitions to the first screen in the flow.
    func loadAndUpdateUI(
        clientSecret: String
    ) {
        load(clientSecret: clientSecret) {
            self.flowController.transitionToFirstScreen(apiContent: self.apiContent, sheetController: self)
        }
    }

    /**
     Makes API calls to load the verification sheet.
     - Note: `completion` block is always executed on the main thread.
     */
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
        }.observe { result in
            DispatchQueue.main.async { [weak self] in
                // API request finished
                guard let self = self else { return }
                self.apiContent.setStaticContent(result: result)
                completion()
            }
        }
    }

    /**
     Saves the values in `dataStore` to server
     - Note
     */
    func saveData(
        completion: @escaping (VerificationSheetAPIContent) -> Void
    ) {
        guard let staticContent = apiContent.staticContent else {
            let apiContent = self.apiContent
            DispatchQueue.main.async {
                completion(apiContent)
            }
            return
        }

        apiClient.postIdentityVerificationSessionData(
            id: staticContent.id,
            updating: dataStore.toAPIModel,
            ephemeralKeySecret: staticContent.ephemeralApiKey
        ).observe { [weak self] result in
            DispatchQueue.main.async {
                self?.apiContent.setSessionData(result: result)

                // Always call completion block even if `self` has been deinitialized
                completion(self?.apiContent ?? VerificationSheetAPIContent())
            }
        }
    }
}

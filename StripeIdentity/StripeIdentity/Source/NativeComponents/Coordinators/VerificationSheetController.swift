//
//  VerificationSheetController.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 10/7/21.
//

import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

protocol VerificationSheetControllerDelegate: AnyObject {
    /**
     Invoked when the user has closed the flow.
     - Parameters:
       - controller: The `VerificationSheetController` that determined the flow result.
       - result: The result of the user's verification flow.
                 Value is `.flowCompleted` if the user successfully completed the flow.
                 Value is `.flowCanceled` if the user closed the view controller prior to completing the flow.
     */
    func verificationSheetController(
        _ controller: VerificationSheetControllerProtocol,
        didFinish result: IdentityVerificationSheet.VerificationFlowResult
    )
}

protocol VerificationSheetControllerProtocol: AnyObject {
    var flowController: VerificationSheetFlowControllerProtocol { get }
    var dataStore: VerificationSessionDataStore { get }
    var mockCameraFeed: MockIdentityDocumentCameraFeed? { get }

    func loadAndUpdateUI(
        clientSecret: String
    )

    func uploadDocument(image: UIImage) -> Future<String>

    func saveData(
        completion: @escaping (VerificationSheetAPIContent) -> Void
    )

    func submit(
        completion: @escaping (VerificationSheetAPIContent) -> Void
    )
}

final class VerificationSheetController: VerificationSheetControllerProtocol {

    weak var delegate: VerificationSheetControllerDelegate?

    let addressSpecProvider: AddressSpecProvider
    var apiClient: IdentityAPIClient
    let flowController: VerificationSheetFlowControllerProtocol
    let dataStore = VerificationSessionDataStore()
    var mockCameraFeed: MockIdentityDocumentCameraFeed?

    /// Content returned from the API
    var apiContent = VerificationSheetAPIContent()

    init(apiClient: IdentityAPIClient = STPAPIClient.shared,
         addressSpecProvider: AddressSpecProvider = .shared,
         flowController: VerificationSheetFlowControllerProtocol = VerificationSheetFlowController()) {
        self.addressSpecProvider = addressSpecProvider
        self.apiClient = apiClient
        self.flowController = flowController
        
        flowController.delegate = self
    }

    /// Makes API calls to load the verification sheet. When the API response is complete, transitions to the first screen in the flow.
    func loadAndUpdateUI(
        clientSecret: String
    ) {
        load(clientSecret: clientSecret) {
            self.flowController.transitionToNextScreen(
                apiContent: self.apiContent,
                sheetController: self
            )
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
        let verificationPagePromise = apiClient.createIdentityVerificationPage(clientSecret: clientSecret)

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

        apiClient.updateIdentityVerificationSessionData(
            id: staticContent.id,
            updating: dataStore.toAPIModel,
            ephemeralKeySecret: staticContent.ephemeralApiKey
        ).observe { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else {
                    // Always call completion block even if `self` has been deinitialized
                    completion(VerificationSheetAPIContent())
                    return
                }
                self.apiContent.setSessionData(result: result)

                completion(self.apiContent)
            }
        }
    }

    /// Uploads a document image and returns a Future containing the ID of the uploaded file
    func uploadDocument(image: UIImage) -> Future<String> {
        // TODO(mludowise|IDPROD-2482): Crop and downscale image for faster upload times
        return apiClient.uploadImage(image, purpose: .identityDocument).chained { file in
            return Promise(value: file.id)
        }
    }

    func submit(
        completion: @escaping (VerificationSheetAPIContent) -> Void
    ) {
        guard let staticContent = apiContent.staticContent else {
            let apiContent = self.apiContent
            DispatchQueue.main.async {
                completion(apiContent)
            }
            return
        }

        apiClient.submitIdentityVerificationSession(
            id: staticContent.id,
            ephemeralKeySecret: staticContent.ephemeralApiKey
        ).observe { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else {
                    // Always call completion block even if `self` has been deinitialized
                    completion(VerificationSheetAPIContent())
                    return
                }
                self.apiContent.setSessionData(result: result)

                completion(self.apiContent)
            }
        }
    }
}

// MARK: - VerificationSheetFlowControllerDelegate

extension VerificationSheetController: VerificationSheetFlowControllerDelegate {
    func verificationSheetFlowControllerDidDismiss(_ flowController: VerificationSheetFlowControllerProtocol) {
        let result: IdentityVerificationSheet.VerificationFlowResult =
            (apiContent.submitted == true) ? .flowCompleted : .flowCanceled
        delegate?.verificationSheetController(self, didFinish: result)
    }
}

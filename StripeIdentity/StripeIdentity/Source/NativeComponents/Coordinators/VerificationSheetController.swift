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
    var apiClient: IdentityAPIClient { get }
    var flowController: VerificationSheetFlowControllerProtocol { get }
    var mlModelLoader: IdentityMLModelLoaderProtocol { get }
    var collectedData: VerificationPageCollectedData { get }

    var delegate: VerificationSheetControllerDelegate? { get set }

    func loadAndUpdateUI()

    func saveAndTransition(
        collectedData: VerificationPageCollectedData,
        completion: @escaping () -> Void
    )

    func saveDocumentFileDataAndTransition(
        documentUploader: DocumentUploaderProtocol,
        completion: @escaping () -> Void
    )

    func submit(
        completion: @escaping (VerificationSheetAPIContent) -> Void
    )
}

@available(iOS 13, *)
final class VerificationSheetController: VerificationSheetControllerProtocol {

    weak var delegate: VerificationSheetControllerDelegate?

    let apiClient: IdentityAPIClient
    let flowController: VerificationSheetFlowControllerProtocol
    let mlModelLoader: IdentityMLModelLoaderProtocol

    /// Cache of the data that's been sent to the server
    private(set) var collectedData = VerificationPageCollectedData()

    /// Content returned from the API
    var apiContent = VerificationSheetAPIContent()

    init(
        apiClient: IdentityAPIClient,
        flowController: VerificationSheetFlowControllerProtocol,
        mlModelLoader: IdentityMLModelLoaderProtocol
    ) {
        self.apiClient = apiClient
        self.flowController = flowController
        self.mlModelLoader = mlModelLoader

        flowController.delegate = self
    }

    /// Makes API calls to load the verification sheet. When the API response is complete, transitions to the first screen in the flow.
    func loadAndUpdateUI() {
        load {
            self.flowController.transitionToNextScreen(
                apiContent: self.apiContent,
                sheetController: self,
                completion: { }
            )
        }
    }

    /**
     Makes API calls to load the verification sheet.
     - Note: `completion` block is always executed on the main thread.
     */
    func load(
        completion: @escaping () -> Void
    ) {
        // Start API request
        apiClient.getIdentityVerificationPage().observe(on: .main) { [weak self] result in
            // API request finished
            guard let self = self else { return }
            self.apiContent.setStaticContent(result: result)
            self.startLoadingMLModels()
            completion()
        }
    }

    func startLoadingMLModels() {
        guard let staticContent = apiContent.staticContent else {
            return
        }

        mlModelLoader.startLoadingDocumentModels(
            from: staticContent.documentCapture.models
        )
    }

    /**
     Saves the `collectedData` to the server and caches the saved fields if successful
     - Note: `completion` block is always executed on the main thread.
     */
    func saveAndTransition(
        collectedData: VerificationPageCollectedData,
        completion: @escaping () -> Void
    ) {
        apiClient.updateIdentityVerificationPageData(
            updating: .init(
                clearData: .init(clearFields: flowController.uncollectedFields),
                collectedData: collectedData,
                _additionalParametersStorage: nil
            )
        ).observe(on: .main) { [weak self] result in
            self?.cacheDataAndTransition(
                collectedData: collectedData,
                dataUpdateResult: result,
                completion: completion
            )
        }
    }

    /**
     Waits until documents are done uploading then saves front and back of document to the server
     - Note: `completion` block is always executed on the main thread.
     */
    func saveDocumentFileDataAndTransition(
        documentUploader: DocumentUploaderProtocol,
        completion: @escaping () -> Void
    ) {
        var optionalCollectedData: VerificationPageCollectedData?
        documentUploader.frontBackUploadFuture.chained { [weak flowController, apiClient] (front, back) -> Future<VerificationPageData> in
            let collectedData = VerificationPageCollectedData(
                idDocumentFront: front,
                idDocumentBack: back
            )
            optionalCollectedData = collectedData
            return apiClient.updateIdentityVerificationPageData(
                updating: VerificationPageDataUpdate(
                    clearData: .init(clearFields: flowController?.uncollectedFields ?? []),
                    collectedData: collectedData,
                    _additionalParametersStorage: nil
                )
            )
        }.observe(on: .main) { [weak self] result in
            self?.cacheDataAndTransition(
                collectedData: optionalCollectedData,
                dataUpdateResult: result,
                completion: completion
            )
        }
    }

    private func cacheDataAndTransition(
        collectedData: VerificationPageCollectedData?,
        dataUpdateResult: Result<VerificationPageData, Error>,
        completion: @escaping () -> Void
    ) {
        if case .success = dataUpdateResult,
        let collectedData = collectedData {
            self.collectedData.merge(collectedData)
        }
        apiContent.setSessionData(result: dataUpdateResult)

        flowController.transitionToNextScreen(
            apiContent: apiContent,
            sheetController: self,
            completion: completion
        )
    }

    /**
     Submits the VerificationSession
     - Note: `completion` block is always executed on the main thread.
     */
    func submit(
        completion: @escaping (VerificationSheetAPIContent) -> Void
    ) {
        apiClient.submitIdentityVerificationPage().observe(on: .main) { [weak self] result in
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

// MARK: - VerificationSheetFlowControllerDelegate

@available(iOS 13, *)
extension VerificationSheetController: VerificationSheetFlowControllerDelegate {
    func verificationSheetFlowControllerDidDismiss(_ flowController: VerificationSheetFlowControllerProtocol) {
        let result: IdentityVerificationSheet.VerificationFlowResult =
            (apiContent.submitted == true) ? .flowCompleted : .flowCanceled
        delegate?.verificationSheetController(self, didFinish: result)
    }
}

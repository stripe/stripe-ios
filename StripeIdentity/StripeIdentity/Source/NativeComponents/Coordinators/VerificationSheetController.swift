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
    var analyticsClient: IdentityAnalyticsClient { get }
    var collectedData: StripeAPI.VerificationPageCollectedData { get }
    var verificationPageResponse: Result<StripeAPI.VerificationPage, Error>? { get }

    var delegate: VerificationSheetControllerDelegate? { get set }

    func loadAndUpdateUI()

    func saveAndTransition(
        from fromScreen: IdentityAnalyticsClient.ScreenName,
        collectedData: StripeAPI.VerificationPageCollectedData,
        completion: @escaping () -> Void
    )

    func saveDocumentFileDataAndTransition(
        from fromScreen: IdentityAnalyticsClient.ScreenName,
        documentUploader: DocumentUploaderProtocol,
        completion: @escaping () -> Void
    )

    func saveSelfieFileDataAndTransition(
        from fromScreen: IdentityAnalyticsClient.ScreenName,
        selfieUploader: SelfieUploaderProtocol,
        capturedImages: FaceCaptureData,
        trainingConsent: Bool,
        completion: @escaping () -> Void
    )
}

@available(iOS 13, *)
final class VerificationSheetController: VerificationSheetControllerProtocol {

    weak var delegate: VerificationSheetControllerDelegate?

    let apiClient: IdentityAPIClient
    let flowController: VerificationSheetFlowControllerProtocol
    let mlModelLoader: IdentityMLModelLoaderProtocol
    let analyticsClient: IdentityAnalyticsClient

    /// Cache of the data that's been sent to the server
    private(set) var collectedData = StripeAPI.VerificationPageCollectedData()

    // MARK: API Response Properties

    #if DEBUG
    // Make settable for tests only
    var verificationPageResponse: Result<StripeAPI.VerificationPage, Error>?
    #else
    /// Static content returned from the initial API request describing how to
    /// configure the verification flow experience
    private(set) var verificationPageResponse: Result<StripeAPI.VerificationPage, Error>?
    #endif

    /// If the VerificationPage was successfully submitted
    /// - Note: This value should not be modified outside of this class except in tests
    var isVerificationPageSubmitted = false {
        didSet {
            guard oldValue != isVerificationPageSubmitted else {
                return
            }
            if isVerificationPageSubmitted {
                analyticsClient.logVerificationSucceeded(sheetController: self)
            }
        }
    }


    // MARK: - Init

    init(
        apiClient: IdentityAPIClient,
        flowController: VerificationSheetFlowControllerProtocol,
        mlModelLoader: IdentityMLModelLoaderProtocol,
        analyticsClient: IdentityAnalyticsClient
    ) {
        self.apiClient = apiClient
        self.flowController = flowController
        self.mlModelLoader = mlModelLoader
        self.analyticsClient = analyticsClient

        flowController.delegate = self
    }

    // MARK: - Load

    /// Makes API calls to load the verification sheet. When the API response is complete, transitions to the first screen in the flow.
    func loadAndUpdateUI() {
        load().observe(on: .main) { result in
            self.flowController.transitionToNextScreen(
                staticContentResult: result,
                updateDataResult: nil,
                sheetController: self,
                completion: { }
            )
        }
    }

    func load() -> Future<StripeAPI.VerificationPage> {
        let returnedPromise = Promise<StripeAPI.VerificationPage>()
        // Only update `verificationPageResponse` on main
        apiClient.getIdentityVerificationPage().observe(on: .main) { [weak self] result in
            self?.verificationPageResponse = result
            if case let .success(verificationPage) = result {
                self?.startLoadingMLModels(from: verificationPage)
            }
            returnedPromise.fullfill(with: result)
        }
        return returnedPromise
    }

    func startLoadingMLModels(from verificationPage: StripeAPI.VerificationPage) {
        mlModelLoader.startLoadingDocumentModels(
            from: verificationPage.documentCapture
        )
        if let selfiePageConfig = verificationPage.selfie {
            mlModelLoader.startLoadingFaceModels(from: selfiePageConfig)
        }
    }

    // MARK: - Save

    /**
     Saves the `collectedData` to the server and caches the saved fields if successful
     - Note: `completion` block is always executed on the main thread.
     */
    func saveAndTransition(
        from fromScreen: IdentityAnalyticsClient.ScreenName,
        collectedData: StripeAPI.VerificationPageCollectedData,
        completion: @escaping () -> Void
    ) {
        analyticsClient.startTrackingTimeToScreen(from: fromScreen)
        apiClient.updateIdentityVerificationPageData(
            updating: .init(
                clearData: .init(clearFields: flowController.uncollectedFields),
                collectedData: collectedData
            )
        ).observe(on: .main) { [weak self] result in
            self?.saveCheckSubmitAndTransition(
                collectedData: collectedData,
                updateDataResult: result,
                completion: completion
            )
        }
    }

    /**
     Waits until documents are done uploading then saves front and back of document to the server
     - Note: `completion` block is always executed on the main thread.
     */
    func saveDocumentFileDataAndTransition(
        from fromScreen: IdentityAnalyticsClient.ScreenName,
        documentUploader: DocumentUploaderProtocol,
        completion: @escaping () -> Void
    ) {
        analyticsClient.startTrackingTimeToScreen(from: fromScreen)
        var optionalCollectedData: StripeAPI.VerificationPageCollectedData?
        documentUploader.frontBackUploadFuture.chained { [weak flowController, apiClient] (front, back) -> Future<StripeAPI.VerificationPageData> in
            let collectedData = StripeAPI.VerificationPageCollectedData(
                idDocumentBack: back,
                idDocumentFront: front
            )
            optionalCollectedData = collectedData
            return apiClient.updateIdentityVerificationPageData(
                updating: StripeAPI.VerificationPageDataUpdate(
                    clearData: .init(clearFields: flowController?.uncollectedFields ?? []),
                    collectedData: collectedData
                )
            )
        }.observe(on: .main) { [weak self] result in
            self?.saveCheckSubmitAndTransition(
                collectedData: optionalCollectedData,
                updateDataResult: result,
                completion: completion
            )
        }
    }

    func saveSelfieFileDataAndTransition(
        from fromScreen: IdentityAnalyticsClient.ScreenName,
        selfieUploader: SelfieUploaderProtocol,
        capturedImages: FaceCaptureData,
        trainingConsent: Bool,
        completion: @escaping () -> Void
    ) {
        analyticsClient.startTrackingTimeToScreen(from: fromScreen)
        var optionalCollectedData: StripeAPI.VerificationPageCollectedData?
        selfieUploader.uploadFuture?.chained { [weak flowController, apiClient] uploadedFiles -> Future<StripeAPI.VerificationPageData> in
            let collectedData = StripeAPI.VerificationPageCollectedData(
                face: .init(
                    uploadedFiles: uploadedFiles,
                    capturedImages: capturedImages,
                    bestFrameExifMetadata: capturedImages.bestMiddle.cameraExifMetadata,
                    trainingConsent: trainingConsent
                )
            )
            optionalCollectedData = collectedData
            return apiClient.updateIdentityVerificationPageData(
                updating: StripeAPI.VerificationPageDataUpdate(
                    clearData: .init(clearFields: flowController?.uncollectedFields ?? []),
                    collectedData: collectedData
                )
            )
        }.observe(on: .main) { [weak self] result in
            self?.saveCheckSubmitAndTransition(
                collectedData: optionalCollectedData,
                updateDataResult: result,
                completion: completion
            )
        }
    }

    /**
     1. If the save was successful, caches the collectedData
     2. If all fields have been collected, submits the verification page
     3. Transitions to the next screen
     */
    private func saveCheckSubmitAndTransition(
        collectedData: StripeAPI.VerificationPageCollectedData?,
        updateDataResult: Result<StripeAPI.VerificationPageData, Error>,
        completion: @escaping () -> Void
    ) {
        // Only mutate properties on the main thread
        assert(Thread.isMainThread)

        guard let verificationPageResponse = verificationPageResponse else {
            assertionFailure("verificationPageResponse is nil")
            return
        }

        // Setup block to transition to next screen with a given result
        let transitionBlock: (Result<StripeAPI.VerificationPageData, Error>?) -> Void = { [weak self] result in
            guard let self = self else { return }

            self.flowController.transitionToNextScreen(
                staticContentResult: verificationPageResponse,
                updateDataResult: result,
                sheetController: self,
                completion: completion
            )
        }

        // Check if result is a failure
        guard case .success = updateDataResult,
              case .success(let verificationPage) = verificationPageResponse
        else {
            transitionBlock(updateDataResult)
            return
        }

        // Cache collected data if response is a success
        if let collectedData = collectedData {
            self.collectedData.merge(collectedData)
        }

        // Check if more data needs to be collected
        guard flowController.isFinishedCollectingData(for: verificationPage) else {
            transitionBlock(updateDataResult)
            return
        }

        // Submit VerificationPage and transition
        apiClient.submitIdentityVerificationPage().observe(on: .main) { [weak self] result in
            self?.isVerificationPageSubmitted = (try? result.get())?.submitted == true
            transitionBlock(result)
        }
    }
}

// MARK: - VerificationSheetFlowControllerDelegate

@available(iOS 13, *)
extension VerificationSheetController: VerificationSheetFlowControllerDelegate {
    func verificationSheetFlowControllerDidDismissNativeView(_ flowController: VerificationSheetFlowControllerProtocol) {
        delegate?.verificationSheetController(
            self,
            didFinish: self.isVerificationPageSubmitted ? .flowCompleted : .flowCanceled
        )
    }

    func verificationSheetFlowControllerDidDismissWebView(_ flowController: VerificationSheetFlowControllerProtocol) {
        // Check the submission status after the user closes the web view to
        // see if they completed the flow or canceled
        apiClient.getIdentityVerificationPage().observe(on: .main) { [weak self] result in
            guard let self = self else { return }
            self.isVerificationPageSubmitted = (try? result.get())?.submitted == true
            self.delegate?.verificationSheetController(
                self,
                didFinish: self.isVerificationPageSubmitted ? .flowCompleted : .flowCanceled
            )
        }
    }
}

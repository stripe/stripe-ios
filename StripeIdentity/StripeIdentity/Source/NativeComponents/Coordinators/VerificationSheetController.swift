//
//  VerificationSheetController.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 10/7/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

protocol VerificationSheetControllerDelegate: AnyObject {
    /// Invoked when the user has closed the flow.
    /// - Parameters:
    ///   - controller: The `VerificationSheetController` that determined the flow result.
    ///   - result: The result of the user's verification flow.
    ///             Value is `.flowCompleted` if the user successfully completed the flow.
    ///             Value is `.flowCanceled` if the user closed the view controller prior to completing the flow.
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
    var collectedData: StripeAPI.VerificationPageCollectedData { get set }
    var verificationPageResponse: Result<StripeAPI.VerificationPage, Error>? { get }

    var delegate: VerificationSheetControllerDelegate? { get set }

    func loadAndUpdateUI()

    func saveAndTransition(
        from fromScreen: IdentityAnalyticsClient.ScreenName,
        collectedData: StripeAPI.VerificationPageCollectedData,
        completion: @escaping () -> Void
    )

    func saveDocumentFrontAndDecideBack(
        from fromScreen: IdentityAnalyticsClient.ScreenName,
        documentUploader: DocumentUploaderProtocol,
        onCompletion: @escaping (_ isBackRequired: Bool) -> Void
    )

    func saveDocumentBackAndTransition(
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

    /// Transition to CountryNotListedViewController without any API request
    func transitionToCountryNotListed(
        missingType: IndividualFormElement.MissingType
    )

    /// Transition to IndividualViewController without any API request
    func transitionToIndividual()
}

final class VerificationSheetController: VerificationSheetControllerProtocol {

    weak var delegate: VerificationSheetControllerDelegate?

    let apiClient: IdentityAPIClient
    let flowController: VerificationSheetFlowControllerProtocol
    let mlModelLoader: IdentityMLModelLoaderProtocol
    let analyticsClient: IdentityAnalyticsClient

    /// Cache of the data that's been sent to the server
    var collectedData = StripeAPI.VerificationPageCollectedData()

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
                completion: {}
            )
        }
    }

    func load() -> Future<StripeAPI.VerificationPage> {
        let returnedPromise = Promise<StripeAPI.VerificationPage>()
        // Only update `verificationPageResponse` on main
        apiClient.getIdentityVerificationPage().observe(on: .main) { [weak self] result in
            self?.verificationPageResponse = result
            if case .success(let verificationPage) = result {
                self?.startLoadingMLModels(from: verificationPage)
                // if result success and requires address, load address spec before continue
                if verificationPage.requirements.missing.contains(.address) {
                    AddressSpecProvider.shared.loadAddressSpecs {
                        returnedPromise.fullfill(with: result)
                    }
                } else {
                    returnedPromise.fullfill(with: result)
                }
            } else {
                // result not success
                returnedPromise.fullfill(with: result)
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

    /// Saves the `collectedData` to the server and caches the saved fields if successful
    /// - Note: `completion` block is always executed on the main thread.
    func saveAndTransition(
        from fromScreen: IdentityAnalyticsClient.ScreenName,
        collectedData: StripeAPI.VerificationPageCollectedData,
        completion: @escaping () -> Void
    ) {
        analyticsClient.startTrackingTimeToScreen(from: fromScreen)
        apiClient.updateIdentityVerificationPageData(
            updating: .init(
                clearData: calculateClearData(dataToBeCollected: collectedData),
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

    /// 1. Check If all fields have been collected, submits the verification page
    /// 2. Transition to the next screen
    private func checkSubmitAndTransition(
        updateDataResult: Result<StripeAPI.VerificationPageData, Error>,
        completion: @escaping () -> Void
    ) {
        guard case .success(let updateData) = updateDataResult
        else {
            // Transition to generic error screen
            transitionWithVerificaionPageDataResult(
                nil,
                completion: completion
            )
            return
        }
        // If finished collecting, submit and transition
        if updateData.requirements.missing.isEmpty {
            apiClient.submitIdentityVerificationPage().observe(on: .main) { [weak self] result in
                self?.isVerificationPageSubmitted = (try? result.get())?.submitted == true
                self?.transitionWithVerificaionPageDataResult(
                    result,
                    completion: completion
                )
            }
        } else {
            transitionWithVerificaionPageDataResult(updateDataResult, completion: completion)
        }
    }

    /// Save update VerificationPage with document front, checks if back is needed
    /// If back is needed, invokes onNeedBack
    /// Otherwise submit the Verification session, transition and invokes onNotNeedBack
    func saveDocumentFrontAndDecideBack(
        from fromScreen: IdentityAnalyticsClient.ScreenName,
        documentUploader: DocumentUploaderProtocol,
        onCompletion: @escaping (_ isBackRequired: Bool) -> Void
    ) {

        var optionalCollectedData: StripeAPI.VerificationPageCollectedData?
        documentUploader.frontUploadFuture?.chained {
            [weak self, apiClient] front -> Future<StripeAPI.VerificationPageData> in
            let collectedData = StripeAPI.VerificationPageCollectedData(
                idDocumentFront: front
            )
            optionalCollectedData = collectedData
            return apiClient.updateIdentityVerificationPageData(
                updating: StripeAPI.VerificationPageDataUpdate(
                    clearData: self?.calculateClearData(dataToBeCollected: collectedData),
                    collectedData: collectedData
                )
            )
        }.observe(on: .main) { result in
            switch result {
            case .success(let resultData):
                guard resultData.requirements.errors.isEmpty else {
                    self.transitionWithVerificaionPageDataResult(result)
                    return
                }

                if let optionalCollectedData = optionalCollectedData {
                    self.collectedData.merge(optionalCollectedData)
                }
                guard !resultData.requirements.missing.contains(.idDocumentBack) else {
                    onCompletion(true)
                    return
                }

                self.analyticsClient.startTrackingTimeToScreen(from: fromScreen)
                self.checkSubmitAndTransition(updateDataResult: result) {
                    onCompletion(false)
                }
            case .failure:
                self.transitionWithVerificaionPageDataResult(result)
            }
        }
    }

    /// Waits until document back are done uploading then saves back of document to the server
    /// - Note: `completion` block is always executed on the main thread.
    func saveDocumentBackAndTransition(
        from fromScreen: IdentityAnalyticsClient.ScreenName,
        documentUploader: DocumentUploaderProtocol,
        completion: @escaping () -> Void
    ) {
        analyticsClient.startTrackingTimeToScreen(from: fromScreen)
        var optionalCollectedData: StripeAPI.VerificationPageCollectedData?
        documentUploader.backUploadFuture?.chained {
            [weak self, apiClient] back -> Future<StripeAPI.VerificationPageData> in
            let collectedData = StripeAPI.VerificationPageCollectedData(
                idDocumentBack: back
            )
            optionalCollectedData = collectedData
            return apiClient.updateIdentityVerificationPageData(
                updating: StripeAPI.VerificationPageDataUpdate(
                    clearData: self?.calculateClearData(dataToBeCollected: collectedData),
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

    // MARK: - Transition without save
    func transitionToCountryNotListed(missingType: IndividualFormElement.MissingType) {

        guard let verificationPageResponse = verificationPageResponse else {
            assertionFailure("verificationPageResponse is nil")
            return
        }

        flowController.transitionToCountryNotListedScreen(
            staticContentResult: verificationPageResponse,
            sheetController: self,
            missingType: missingType
        )
    }

    func transitionToIndividual() {
        guard let verificationPageResponse = verificationPageResponse else {
            assertionFailure("verificationPageResponse is nil")
            return
        }

        flowController.transitionToIndividualScreen(
            staticContentResult: verificationPageResponse,
            sheetController: self
        )
    }

    /// * Assert verificationPageResponse to be correct, then transition with the PageDataResult.
    private func transitionWithVerificaionPageDataResult(
        _ result: Result<StripeAPI.VerificationPageData, Error>?,
        completion: @escaping () -> Void = {}
    ) {
        // Only mutate properties on the main thread
        assert(Thread.isMainThread)

        guard let verificationPageResponse = verificationPageResponse else {
            assertionFailure("verificationPageResponse is nil")
            return
        }

        flowController.transitionToNextScreen(
            staticContentResult: verificationPageResponse,
            updateDataResult: result,
            sheetController: self,
            completion: completion
        )
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
        selfieUploader.uploadFuture?.chained {
            [weak self, apiClient] uploadedFiles -> Future<StripeAPI.VerificationPageData> in
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
                    clearData: self?.calculateClearData(dataToBeCollected: collectedData),
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

    /// 1. If the save was successful, caches the collectedData
    /// 2. If all fields have been collected, submits the verification page
    /// 3. Transitions to the next screen
    private func saveCheckSubmitAndTransition(
        collectedData: StripeAPI.VerificationPageCollectedData?,
        updateDataResult: Result<StripeAPI.VerificationPageData, Error>,
        completion: @escaping () -> Void
    ) {
        guard case .success(let resultData) = updateDataResult
        else {
            transitionWithVerificaionPageDataResult(updateDataResult, completion: completion)
            return
        }

        // Only merge when updateDatResult is successful and has no errors
        if let collectedData = collectedData, resultData.requirements.errors.isEmpty {
            self.collectedData.merge(collectedData)
        }

        checkSubmitAndTransition(
            updateDataResult: updateDataResult,
            completion: completion
        )
    }

    /// Calculate the clearData parameter from the collectedData to be generated by the following
    ///    allTypes - typesAlreadyCollected - typesToBeCollected
    private func calculateClearData(
        dataToBeCollected: StripeAPI.VerificationPageCollectedData
    ) -> StripeAPI.VerificationPageClearData {
        return .init(
            clearFields: Set(StripeAPI.VerificationPageFieldType.allCases).subtracting(
                collectedData.collectedTypes
            ).subtracting(dataToBeCollected.collectedTypes)
        )
    }

}

// MARK: - VerificationSheetFlowControllerDelegate

extension VerificationSheetController: VerificationSheetFlowControllerDelegate {
    func verificationSheetFlowControllerDidDismissNativeView(
        _ flowController: VerificationSheetFlowControllerProtocol
    ) {
        delegate?.verificationSheetController(
            self,
            didFinish: self.isVerificationPageSubmitted ? .flowCompleted : .flowCanceled
        )
    }

    func verificationSheetFlowControllerDidDismissWebView(
        _ flowController: VerificationSheetFlowControllerProtocol
    ) {
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

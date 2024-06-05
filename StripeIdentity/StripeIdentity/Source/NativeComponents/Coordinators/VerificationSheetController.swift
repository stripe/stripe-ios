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

    func loadAndUpdateUI(skipTestMode: Bool)

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

    func forceDocumentFrontAndDecideBack(
        from fromScreen: IdentityAnalyticsClient.ScreenName,
        onCompletion: @escaping (_ isBackRequired: Bool) -> Void
    )

    func forceDocumentBackAndTransition(
        from fromScreen: IdentityAnalyticsClient.ScreenName,
        completion: @escaping () -> Void
    )

    func saveSelfieFileDataAndTransition(
        from fromScreen: IdentityAnalyticsClient.ScreenName,
        selfieUploader: SelfieUploaderProtocol,
        capturedImages: FaceCaptureData,
        trainingConsent: Bool,
        completion: @escaping () -> Void
    )

    /// Submit OTP with VerificationPageData API and transition if OTP is valid or request failed.
    /// Call invalidOtp callback when the request is successful but OTP is invalid.
    func saveOtpAndMaybeTransition(
        from fromScreen: IdentityAnalyticsClient.ScreenName,
        otp otpValue: String,
        completion: @escaping () -> Void,
        invalidOtp: @escaping () -> Void
    )

    func verifyAndTransition(
        simulateDelay: Bool,
        completion: @escaping () -> Void
    )

    func unverifyAndTransition(
        simulateDelay: Bool,
        completion: @escaping () -> Void
    )

    /// Request a new phoneOtp, transition to error view controller if request failed, callback on successCallback otherwise.
    func generatePhoneOtp(using successCallback: @escaping (StripeAPI.VerificationPageData) -> Void)

    /// Send the cannotVerifyPhoneOtp request and transition accordingly.
    func sendCannotVerifyPhoneOtpAndTransition(
        completion: @escaping () -> Void
    )

    /// Transition to CountryNotListedViewController without any API request
    func transitionToCountryNotListed(
        missingType: IndividualFormElement.MissingType
    )

    /// Transition to IndividualViewController without any API request
    func transitionToIndividual()

    /// Clear a certain type from collected data
    func clearCollectedData(field: StripeAPI.VerificationPageFieldType)

    /// Override return result for testMode
    func overrideTestModeReturnValue(result: IdentityVerificationSheet.VerificationFlowResult)

    /// Transition to DocumentCaptureViewController without any API request
    func transitionToSelfieCapture()

    /// Transition to DocumentCaptureViewController without any API request
    func transitionToDocumentCapture()
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

    var testModeReturnValue: IdentityVerificationSheet.VerificationFlowResult?

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
    func loadAndUpdateUI(skipTestMode: Bool) {
        load().observe(on: .main) { result in
            self.flowController.transitionToNextScreen(
                skipTestMode: skipTestMode,
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
            guard let self = self else { return }
            self.verificationPageResponse = result
            if case .success(let verificationPage) = result {
                self.startLoadingMLModels(from: verificationPage)
                self.isVerificationPageSubmitted = verificationPage.submitted
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
            from: verificationPage.documentCapture,
            with: self
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
        analyticsClient.startTrackingTimeToScreen(from: fromScreen, sheetController: self)
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
                updateDataResult,
                completion: completion
            )
            return
        }

        // If finished collecting, submit and transition
        if updateData.requirements.missing.isEmpty {
            apiClient.submitIdentityVerificationPage().observe(on: .main) { [weak self] submittedData in
                guard let self = self else { return }
                self.isVerificationPageSubmitted = (try? submittedData.get())?.submittedAndClosed() == true

                // Checking the response of submit
                guard case .success(let resultData) = submittedData
                else {
                    self.isVerificationPageSubmitted = false
                    self.transitionWithVerificaionPageDataResult(submittedData, completion: completion)
                    return
                }

                self.isVerificationPageSubmitted = resultData.submitted == true && resultData.closed == true

                if resultData.needsFallback() {
                    // Checking the buffered VerificationPageResponse, update its missings with the new missings
                    guard let verificationPageResponse = try? self.verificationPageResponse?.get() else {
                        assertionFailure("Fail to get VerificationPageResponse is nil")
                        return
                    }
                    self.verificationPageResponse = .success(verificationPageResponse.copyWithNewMissings(newMissings: resultData.requirements.missing))
                    // clear collected data
                    self.collectedData = StripeAPI.VerificationPageCollectedData()

                }
                self.transitionWithVerificaionPageDataResult(
                    submittedData,
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
        saveDocumentFront(
            from: fromScreen,
            forceConfirm: false,
            documentUploader: documentUploader,
            onCompletion: onCompletion
        )
    }

    /// Waits until document back are done uploading then saves back of document to the server
    /// - Note: `completion` block is always executed on the main thread.
    func saveDocumentBackAndTransition(
        from fromScreen: IdentityAnalyticsClient.ScreenName,
        documentUploader: DocumentUploaderProtocol,
        completion: @escaping () -> Void
    ) {
        saveDocumentBack(
            from: fromScreen,
            forceConfirm: false,
            documentUploader: documentUploader,
            onCompletion: completion
        )
    }

    func forceDocumentFrontAndDecideBack(
        from fromScreen: IdentityAnalyticsClient.ScreenName,
        onCompletion: @escaping (_ isBackRequired: Bool) -> Void
    ) {
        guard let documentUploader = self.flowController.documentUploader
        else {
            self.flowController.transitionToErrorScreen(sheetController: self, error: VerificationSheetFlowControllerError.noDocumentUploader) {
                onCompletion(false)
            }
            return
        }

        saveDocumentFront(
            from: fromScreen,
            forceConfirm: true,
            documentUploader: documentUploader,
            onCompletion: onCompletion
        )
    }

    func forceDocumentBackAndTransition(
        from fromScreen: IdentityAnalyticsClient.ScreenName,
        completion: @escaping () -> Void
    ) {

        guard let documentUploader = self.flowController.documentUploader
        else {
            self.flowController.transitionToErrorScreen(sheetController: self, error: VerificationSheetFlowControllerError.noDocumentUploader, completion: completion)
            return
        }
        saveDocumentBack(from: fromScreen, forceConfirm: true, documentUploader: documentUploader, onCompletion: completion)
    }

    private func saveDocumentFront(
        from fromScreen: IdentityAnalyticsClient.ScreenName,
        forceConfirm: Bool,
        documentUploader: DocumentUploaderProtocol,
        onCompletion: @escaping (_ isBackRequired: Bool) -> Void
    ) {

        var optionalCollectedData: StripeAPI.VerificationPageCollectedData?
        documentUploader.frontUploadFuture?.chained { [weak self, apiClient] front -> Future<StripeAPI.VerificationPageData> in
            let collectedData = StripeAPI.VerificationPageCollectedData(
                idDocumentFront: forceConfirm ? front.withForceConfirm(true) : front
            )
            optionalCollectedData = collectedData
            return apiClient.updateIdentityVerificationPageData(
                updating: StripeAPI.VerificationPageDataUpdate(
                    clearData: self?.calculateClearData(dataToBeCollected: collectedData),
                    collectedData: collectedData
                )
            )
        }.observe(on: .main) { result in
            self.handleVerificationPageDataResult(collectedData: optionalCollectedData, updateDataResult: result) { successData in
                guard successData.requirements.errors.isEmpty else {
                    self.transitionWithVerificaionPageDataResult(result)
                    return
                }
                if successData.requirements.missing.contains(.idDocumentBack) {
                    onCompletion(true)
                } else {
                    self.analyticsClient.startTrackingTimeToScreen(from: fromScreen, sheetController: self)
                    self.checkSubmitAndTransition(updateDataResult: result) {
                        onCompletion(false)
                    }
                }
            }
        }
    }

    private func saveDocumentBack(
        from fromScreen: IdentityAnalyticsClient.ScreenName,
        forceConfirm: Bool,
        documentUploader: DocumentUploaderProtocol,
        onCompletion: @escaping () -> Void
    ) {
        analyticsClient.startTrackingTimeToScreen(from: fromScreen, sheetController: self)
        var optionalCollectedData: StripeAPI.VerificationPageCollectedData?
        documentUploader.backUploadFuture?.chained {
            [weak self, apiClient] back -> Future<StripeAPI.VerificationPageData> in
            let collectedData = StripeAPI.VerificationPageCollectedData(
                idDocumentBack: forceConfirm ? back.withForceConfirm(true) : back
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
                completion: onCompletion
            )
        }
    }

    func verifyAndTransition(
        simulateDelay: Bool,
        completion: @escaping () -> Void
    ) {
        apiClient.verifyTestVerificationSession(
            simulateDelay: simulateDelay
        ).observe(on: .main) { [weak self] result in
            self?.overrideTestModeReturnValue(result: .flowCompleted)
            self?.transitionWithVerificaionPageDataResult(result)
            completion()
        }
    }

    func unverifyAndTransition(
        simulateDelay: Bool,
        completion: @escaping () -> Void
    ) {
        apiClient.unverifyTestVerificationSession(
            simulateDelay: simulateDelay
        ).observe(on: .main) { [weak self] result in
            self?.overrideTestModeReturnValue(result: .flowCompleted)
            self?.transitionWithVerificaionPageDataResult(result)
            completion()
        }
    }

    func generatePhoneOtp(using successCallback: @escaping (StripeAPI.VerificationPageData) -> Void) {
        apiClient.generatePhoneOtp().observe(on: .main) { [weak self] result in
            self?.handleVerificationPageDataResult(updateDataResult: result, successPageData: successCallback)
        }
    }

    func sendCannotVerifyPhoneOtpAndTransition(
        completion: @escaping() -> Void
    ) {
        apiClient.cannotPhoneVerifyOtp().observe(on: .main) { [weak self] updatedDataResult in
            self?.transitionWithUpdatedDataResult(result: updatedDataResult)
        }
    }

    private func transitionWithUpdatedDataResult(result: Result<StripeAPI.VerificationPageData, Error>) {
        saveCheckSubmitAndTransition(
            collectedData: nil,
            updateDataResult: result,
            completion: {}
        )
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

    func transitionToSelfieCapture() {
        guard let verificationPageResponse = verificationPageResponse else {
            assertionFailure("verificationPageResponse is nil")
            return
        }

        flowController.transitionToSelfieCaptureScreen(
            staticContentResult: verificationPageResponse,
            sheetController: self
        )
    }

    func transitionToDocumentCapture() {
        guard let verificationPageResponse = verificationPageResponse else {
            assertionFailure("verificationPageResponse is nil")
            return
        }

        flowController.transitionToDocumentCaptureScreen(
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
            skipTestMode: true,
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
        analyticsClient.startTrackingTimeToScreen(from: fromScreen, sheetController: self)
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

    func saveOtpAndMaybeTransition(from fromScreen: IdentityAnalyticsClient.ScreenName, otp otpValue: String, completion: @escaping () -> Void = {}, invalidOtp: @escaping () -> Void) {
        analyticsClient.startTrackingTimeToScreen(from: fromScreen, sheetController: self)
        let phoneOtpData = StripeAPI.VerificationPageCollectedData(phoneOtp: otpValue)
        apiClient.updateIdentityVerificationPageData(
            updating: .init(
                clearData: calculateClearData(dataToBeCollected: phoneOtpData),
                collectedData: phoneOtpData
            )
        ).observe(on: .main) { [weak self] updateDataResult in
            self?.handleVerificationPageDataResult(collectedData: phoneOtpData, updateDataResult: updateDataResult, completion: completion) { successPageData in
                if successPageData.requirements.missing.contains(.phoneOtp) {
                    invalidOtp()
                } else {
                    self?.checkSubmitAndTransition(
                        updateDataResult: updateDataResult,
                        completion: completion
                    )
                }
            }
        }
    }

    // MARK: - Update internal states

    func clearCollectedData(field: StripeAPI.VerificationPageFieldType) {
        self.collectedData.clearData(field: field)
    }

    func overrideTestModeReturnValue(result: IdentityVerificationSheet.VerificationFlowResult) {
        self.testModeReturnValue = result
    }

    /// Check the result of VerificationPageData and update status. Callback successPageData if successful.
    private func handleVerificationPageDataResult(
        collectedData: StripeAPI.VerificationPageCollectedData? = nil,
        updateDataResult: Result<StripeAPI.VerificationPageData, Error>,
        completion: @escaping () -> Void = {},
        successPageData: @escaping (StripeAPI.VerificationPageData) -> Void
    ) {
        guard case .success(let resultData) = updateDataResult
        else {
            self.transitionWithVerificaionPageDataResult(updateDataResult, completion: completion)
            return
        }

        // update collectedData if there are no errors.
        if resultData.requirements.errors.isEmpty {
            if let collectedData = collectedData {
                self.collectedData.merge(collectedData)
            }
        }

        successPageData(resultData)
    }

    /// 1. If the save was successful, caches the collectedData
    /// 2. If all fields have been collected, submits the verification page
    /// 3. Transitions to the next screen
    private func saveCheckSubmitAndTransition(
        collectedData: StripeAPI.VerificationPageCollectedData?,
        updateDataResult: Result<StripeAPI.VerificationPageData, Error>,
        completion: @escaping () -> Void
    ) {
        handleVerificationPageDataResult(collectedData: collectedData, updateDataResult: updateDataResult, completion: completion) { _ in
            self.checkSubmitAndTransition(
                updateDataResult: updateDataResult,
                completion: completion
            )

        }
    }

    /// Calculate the clearData parameter from the collectedData to be generated by the following
    ///    allTypes - typesAlreadyCollected - typesToBeCollected
    private func calculateClearData(
        dataToBeCollected: StripeAPI.VerificationPageCollectedData
    ) -> StripeAPI.VerificationPageClearData {

        let initialMissings: Set<StripeAPI.VerificationPageFieldType>
        do {
            initialMissings = try verificationPageResponse?.get().requirements.missing ?? Set()
        } catch {
            assertionFailure("verificationPageResponse is nil, using StripeAPI.VerificationPageFieldType.allCases as initialMissings")
            initialMissings = Set(StripeAPI.VerificationPageFieldType.allCases)
        }
        let ret = StripeAPI.VerificationPageClearData.init(
            clearFields: initialMissings.subtracting(
                collectedData.collectedTypes
            ).subtracting(dataToBeCollected.collectedTypes)
        )
        return ret
    }

}

// MARK: - VerificationSheetFlowControllerDelegate

extension VerificationSheetController: VerificationSheetFlowControllerDelegate {
    func verificationSheetFlowControllerDidDismissNativeView(
        _ flowController: VerificationSheetFlowControllerProtocol
    ) {
        delegate?.verificationSheetController(
            self,
            didFinish: self.testModeReturnValue ?? (self.isVerificationPageSubmitted ? .flowCompleted : .flowCanceled)
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

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
        collectedData: StripeAPI.VerificationPageCollectedData
    ) async

    func saveDocumentFrontAndDecideBack(
        from fromScreen: IdentityAnalyticsClient.ScreenName,
        documentUploader: DocumentUploaderProtocol
    ) async -> Bool

    func saveDocumentBackAndTransition(
        from fromScreen: IdentityAnalyticsClient.ScreenName,
        documentUploader: DocumentUploaderProtocol
    ) async

    func forceDocumentFrontAndDecideBack(
        from fromScreen: IdentityAnalyticsClient.ScreenName,
    ) async -> Bool

    func forceDocumentBackAndTransition(
        from fromScreen: IdentityAnalyticsClient.ScreenName
    ) async

    func saveSelfieFileDataAndTransition(
        from fromScreen: IdentityAnalyticsClient.ScreenName,
        selfieUploader: SelfieUploaderProtocol,
        capturedImages: FaceCaptureData,
        trainingConsent: Bool
    ) async

    /// Submit OTP with VerificationPageData API and transition if OTP is valid or request failed.
    /// Call invalidOtp callback when the request is successful but OTP is invalid.
    func saveOtpAndMaybeTransition(
        from fromScreen: IdentityAnalyticsClient.ScreenName,
        otp otpValue: String,
        completion: @escaping () -> Void,
        invalidOtp: @escaping () -> Void
    )

    func verifyAndTransition(
        simulateDelay: Bool
    ) async

    func unverifyAndTransition(
        simulateDelay: Bool
    ) async

    /// Request a new phoneOtp, transition to error view controller if request failed, callback on successCallback otherwise.
    func generatePhoneOtp() async -> StripeAPI.VerificationPageData

    /// Send the cannotVerifyPhoneOtp request and transition accordingly.
    func sendCannotVerifyPhoneOtpAndTransition() async

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

    /// Transition to SelfieCaptureViewController without any API request
    func transitionToSelfieCapture(
        trainingConsent: Bool?
    )

    /// Transition to DocumentCaptureViewController without any API request
    func transitionToDocumentCapture()
}

private enum VerificationSheetControllerError: String, AnalyticLoggableStringErrorV2 {
    case missingVerificationPageResponseForFallbackUpdate
    case missingVerificationPageResponseForCountryNotListedTransition
    case missingVerificationPageResponseForIndividualTransition
    case missingVerificationPageResponseForSelfieCaptureTransition
    case missingVerificationPageResponseForDocumentCaptureTransition
    case missingVerificationPageResponseForPageDataTransition
    case missingVerificationPageResponseForClearDataCalculation
}

@MainActor
final class VerificationSheetController: @MainActor VerificationSheetControllerProtocol {

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
        Task { @MainActor in
            let result = await self.load()
            self.flowController.transitionToNextScreen(
                skipTestMode: skipTestMode,
                staticContentResult: result,
                updateDataResult: nil,
                sheetController: self,
                completion: {}
            )
        }
    }

    func load() async -> Result<StripeAPI.VerificationPage, Error> {
        do {
            let verificationPage = try await apiClient.getIdentityVerificationPage()
            self.verificationPageResponse = .success(verificationPage)
            self.startLoadingMLModels(from: verificationPage)
            self.isVerificationPageSubmitted = verificationPage.submitted
            // if result success and requires address, load address spec before continue
            if verificationPage.requirements.missing.contains(.address) {
                _ = await AddressSpecProvider.shared.loadAddressSpecs()
            }
            return .success(verificationPage)
        } catch {
            self.verificationPageResponse = .failure(error)
            return .failure(error)
        }
    }

    func startLoadingMLModels(from verificationPage: StripeAPI.VerificationPage) {
        mlModelLoader.startLoadingDocumentModels(
            from: verificationPage.documentCapture,
            with: self
        )
        if verificationPage.selfie != nil {
            mlModelLoader.startLoadingFaceModels(from: verificationPage)
        }
    }

    // MARK: - Save

    /// Saves the `collectedData` to the server and caches the saved fields if successful
    /// - Note: `completion` block is always executed on the main thread.
    func saveAndTransition(
        from fromScreen: IdentityAnalyticsClient.ScreenName,
        collectedData: StripeAPI.VerificationPageCollectedData
    ) async {
        analyticsClient.startTrackingTimeToScreen(from: fromScreen, sheetController: self)

        let result: Result<StripeAPI.VerificationPageData, Error>
        do {
            let response = try await apiClient.updateIdentityVerificationPageData(
                updating: .init(
                    clearData: calculateClearData(dataToBeCollected: collectedData),
                    collectedData: collectedData
                )
            )
            result = .success(response)
        } catch {
            result = .failure(error)
        }

        await self.saveCheckSubmitAndTransition(
            collectedData: collectedData,
            updateDataResult: result
        )
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
            transitionWithVerificationPageDataResult(
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
                    self.transitionWithVerificationPageDataResult(submittedData, completion: completion)
                    return
                }

                self.isVerificationPageSubmitted = resultData.submitted == true && resultData.closed == true

                if resultData.needsFallback() {
                    // Checking the buffered VerificationPageResponse, update its missings with the new missings
                    guard let verificationPageResponse = self.verificationPageOrLogError(
                        missingError: .missingVerificationPageResponseForFallbackUpdate,
                        assertionMessage: "Fail to get VerificationPageResponse is nil"
                    ) else {
                        return
                    }
                    self.verificationPageResponse = .success(verificationPageResponse.copyWithNewMissings(newMissings: resultData.requirements.missing))
                    // clear collected data
                    self.collectedData = StripeAPI.VerificationPageCollectedData()

                }
                self.transitionWithVerificationPageDataResult(
                    submittedData,
                    completion: completion
                )
            }
        } else {
            transitionWithVerificationPageDataResult(updateDataResult, completion: completion)
        }
    }

    /// Save update VerificationPage with document front, checks if back is needed
    /// If back is needed, invokes onNeedBack
    /// Otherwise submit the Verification session, transition and invokes onNotNeedBack
    /// returns `isBackRequired: Bool`
    func saveDocumentFrontAndDecideBack(
        from fromScreen: IdentityAnalyticsClient.ScreenName,
        documentUploader: DocumentUploaderProtocol
    ) async -> Bool {
        await saveDocumentFront(
            from: fromScreen,
            forceConfirm: false,
            documentUploader: documentUploader
        )
    }

    /// Waits until document back are done uploading then saves back of document to the server
    /// - Note: `completion` block is always executed on the main thread.
    func saveDocumentBackAndTransition(
        from fromScreen: IdentityAnalyticsClient.ScreenName,
        documentUploader: DocumentUploaderProtocol
    ) async {
        await saveDocumentBack(
            from: fromScreen,
            forceConfirm: false,
            documentUploader: documentUploader
        )
    }

    /// returns `isBackRequired: Bool`
    func forceDocumentFrontAndDecideBack(
        from fromScreen: IdentityAnalyticsClient.ScreenName
    ) async -> Bool {
        guard let documentUploader = self.flowController.documentUploader
        else {
            return await withCheckedContinuation { continuation in
                self.flowController.transitionToErrorScreen(sheetController: self, error: VerificationSheetFlowControllerError.noDocumentUploader) {
                    continuation.resume(returning: false)
                }
            }
        }

        return await saveDocumentFront(
            from: fromScreen,
            forceConfirm: true,
            documentUploader: documentUploader
        )
    }

    func forceDocumentBackAndTransition(
        from fromScreen: IdentityAnalyticsClient.ScreenName
    ) async {

        guard let documentUploader = self.flowController.documentUploader
        else {
            return await withCheckedContinuation { continuation in
                self.flowController.transitionToErrorScreen(sheetController: self, error: VerificationSheetFlowControllerError.noDocumentUploader) {
                    continuation.resume()
                }
            }
        }

        await saveDocumentBack(from: fromScreen, forceConfirm: true, documentUploader: documentUploader)
    }

    /// returns `isBackRequired: Bool`
    private func saveDocumentFront(
        from fromScreen: IdentityAnalyticsClient.ScreenName,
        forceConfirm: Bool,
        documentUploader: DocumentUploaderProtocol,
    ) async -> Bool {
        guard let frontUploadResult = await documentUploader.frontUploadResult()
        else {
            // TODO: throw an error for missing data instead?
            return false
        }

        var optionalCollectedData: StripeAPI.VerificationPageCollectedData?
        let result: Result<StripeAPI.VerificationPageData, Error>

        do {
            let front = try frontUploadResult.get()
            let collectedData = StripeAPI.VerificationPageCollectedData(
                idDocumentFront: forceConfirm ? front.withForceConfirm(true) : front
            )
            optionalCollectedData = collectedData
            let verificationPageData = try await apiClient.updateIdentityVerificationPageData(
                updating: StripeAPI.VerificationPageDataUpdate(
                    clearData: calculateClearData(dataToBeCollected: collectedData),
                    collectedData: collectedData
                )
            )
            result = .success(verificationPageData)
        } catch {
            result = .failure(error)
        }

        return await withCheckedContinuation { continuation in
            handleVerificationPageDataResult(
                collectedData: optionalCollectedData,
                updateDataResult: result,
                completion: {
                    continuation.resume(returning: false)
                }
            ) { successData in
                guard successData.requirements.errors.isEmpty else {
                    self.transitionWithVerificationPageDataResult(result) {
                        continuation.resume(returning: false)
                    }
                    return
                }
                if successData.requirements.missing.contains(.idDocumentBack) {
                    continuation.resume(returning: true)
                } else {
                    self.analyticsClient.startTrackingTimeToScreen(from: fromScreen, sheetController: self)
                    self.checkSubmitAndTransition(updateDataResult: result) {
                        continuation.resume(returning: false)
                    }
                }
            }
        }
    }

    private func saveDocumentBack(
        from fromScreen: IdentityAnalyticsClient.ScreenName,
        forceConfirm: Bool,
        documentUploader: DocumentUploaderProtocol
    ) async {
        guard let backUploadResult = await documentUploader.backUploadResult()
        else {
            // TODO: throw an error for missing data instead?
            return
        }

        analyticsClient.startTrackingTimeToScreen(from: fromScreen, sheetController: self)

        var optionalCollectedData: StripeAPI.VerificationPageCollectedData?
        let result: Result<StripeAPI.VerificationPageData, Error>

        do {
            let back = try backUploadResult.get()
            let collectedData = StripeAPI.VerificationPageCollectedData(
                idDocumentBack: forceConfirm ? back.withForceConfirm(true) : back
            )
            optionalCollectedData = collectedData
            let verificationPageData = try await apiClient.updateIdentityVerificationPageData(
                updating: StripeAPI.VerificationPageDataUpdate(
                    clearData: calculateClearData(dataToBeCollected: collectedData),
                    collectedData: collectedData
                )
            )
            result = .success(verificationPageData)
        } catch {
            result = .failure(error)
        }

        await saveCheckSubmitAndTransition(
            collectedData: optionalCollectedData,
            updateDataResult: result
        )
    }

    func verifyAndTransition(
        simulateDelay: Bool
    ) async {
        await withCheckedContinuation { continuation in
            apiClient.verifyTestVerificationSession(
                simulateDelay: simulateDelay
            ).observe(on: .main) { [weak self] result in
                self?.overrideTestModeReturnValue(result: .flowCompleted)
                self?.transitionWithVerificationPageDataResult(result)
                continuation.resume()
            }
        }
    }

    func unverifyAndTransition(
        simulateDelay: Bool
    ) async {
        await withCheckedContinuation { continuation in
            apiClient.unverifyTestVerificationSession(
                simulateDelay: simulateDelay
            ).observe(on: .main) { [weak self] result in
                self?.overrideTestModeReturnValue(result: .flowCompleted)
                self?.transitionWithVerificationPageDataResult(result)
                continuation.resume()
            }
        }
    }

    func generatePhoneOtp() async -> StripeAPI.VerificationPageData {
        await withCheckedContinuation { continuation in
            apiClient.generatePhoneOtp().observe(on: .main) { [weak self] result in
                self?.handleVerificationPageDataResult(updateDataResult: result, successPageData: { successPageData in continuation.resume(returning: successPageData) })
            }
        }
    }

    func sendCannotVerifyPhoneOtpAndTransition() async {
        await withCheckedContinuation { continuation in
            apiClient.cannotPhoneVerifyOtp().observe(on: .main) { [weak self] updatedDataResult in
                self?.transitionWithUpdatedDataResult(result: updatedDataResult)
                continuation.resume()
            }
        }
    }

    private func transitionWithUpdatedDataResult(result: Result<StripeAPI.VerificationPageData, Error>) {
        Task {
            await saveCheckSubmitAndTransition(
                collectedData: nil,
                updateDataResult: result
            )
        }
    }

    // MARK: - Transition without save
    func transitionToCountryNotListed(missingType: IndividualFormElement.MissingType) {
        guard let verificationPageResponse = verificationPageResponseOrLogMissing(
            .missingVerificationPageResponseForCountryNotListedTransition,
            assertionMessage: "verificationPageResponse is nil"
        ) else {
            return
        }

        flowController.transitionToCountryNotListedScreen(
            staticContentResult: verificationPageResponse,
            sheetController: self,
            missingType: missingType
        )
    }

    func transitionToIndividual() {
        guard let verificationPageResponse = verificationPageResponseOrLogMissing(
            .missingVerificationPageResponseForIndividualTransition,
            assertionMessage: "verificationPageResponse is nil"
        ) else {
            return
        }

        flowController.transitionToIndividualScreen(
            staticContentResult: verificationPageResponse,
            sheetController: self
        )
    }

    func transitionToSelfieCapture(
        trainingConsent: Bool?
    ) {
        guard let verificationPageResponse = verificationPageResponseOrLogMissing(
            .missingVerificationPageResponseForSelfieCaptureTransition,
            assertionMessage: "verificationPageResponse is nil"
        ) else {
            return
        }

        flowController.transitionToSelfieCaptureScreen(
            staticContentResult: verificationPageResponse,
            sheetController: self,
            trainingConsent: trainingConsent
        )
    }

    func transitionToDocumentCapture() {
        guard let verificationPageResponse = verificationPageResponseOrLogMissing(
            .missingVerificationPageResponseForDocumentCaptureTransition,
            assertionMessage: "verificationPageResponse is nil"
        ) else {
            return
        }

        flowController.transitionToDocumentCaptureScreen(
            staticContentResult: verificationPageResponse,
            sheetController: self
        )
    }

    /// * Assert verificationPageResponse to be correct, then transition with the PageDataResult.
    private func transitionWithVerificationPageDataResult(
        _ result: Result<StripeAPI.VerificationPageData, Error>?,
        completion: @escaping () -> Void = {}
    ) {
        // Only mutate properties on the main thread
        assert(Thread.isMainThread)
        guard let verificationPageResponse = verificationPageResponseOrLogMissing(
            .missingVerificationPageResponseForPageDataTransition,
            assertionMessage: "verificationPageResponse is nil"
        ) else {
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
        trainingConsent: Bool
    ) async {
        guard let uploadResult = await selfieUploader.uploadResult()
        else {
            // TODO: throw an error for missing data instead?
            return
        }

        analyticsClient.startTrackingTimeToScreen(from: fromScreen, sheetController: self)
        let shouldSubmit3DFaceCaptureData: Bool
        if case .success(let verificationPage)? = verificationPageResponse {
            shouldSubmit3DFaceCaptureData = verificationPage.shouldSubmit3DFaceCaptureData
        } else {
            shouldSubmit3DFaceCaptureData = false
        }
        var optionalCollectedData: StripeAPI.VerificationPageCollectedData?
        let result: Result<StripeAPI.VerificationPageData, Error>

        do {
            let uploadedFiles = try uploadResult.get()
            let collectedData = StripeAPI.VerificationPageCollectedData(
                face: .init(
                    uploadedFiles: uploadedFiles,
                    capturedImages: capturedImages,
                    bestFrameExifMetadata: capturedImages.bestMiddle.cameraExifMetadata,
                    trainingConsent: trainingConsent,
                    shouldSubmit3DFaceCaptureData: shouldSubmit3DFaceCaptureData
                )
            )
            optionalCollectedData = collectedData
            let verificationPageData = try await apiClient.updateIdentityVerificationPageData(
                updating: StripeAPI.VerificationPageDataUpdate(
                    clearData: calculateClearData(dataToBeCollected: collectedData),
                    collectedData: collectedData
                )
            )
            result = .success(verificationPageData)
        } catch {
            result = .failure(error)
        }

        await saveCheckSubmitAndTransition(
            collectedData: optionalCollectedData,
            updateDataResult: result
        )
    }

    func saveOtpAndMaybeTransition(from fromScreen: IdentityAnalyticsClient.ScreenName, otp otpValue: String, completion: @escaping () -> Void = {}, invalidOtp: @escaping () -> Void) {
        analyticsClient.startTrackingTimeToScreen(from: fromScreen, sheetController: self)
        let phoneOtpData = StripeAPI.VerificationPageCollectedData(phoneOtp: otpValue)

        Task { @MainActor in
            let updateDataResult: Result<StripeAPI.VerificationPageData, Error>
            do {
                let response = try await apiClient.updateIdentityVerificationPageData(
                    updating: .init(
                        clearData: calculateClearData(dataToBeCollected: phoneOtpData),
                        collectedData: phoneOtpData
                    )
                )
                updateDataResult = .success(response)
            } catch {
                updateDataResult = .failure(error)
            }

            self.handleVerificationPageDataResult(collectedData: phoneOtpData, updateDataResult: updateDataResult, completion: completion) { successPageData in
                if successPageData.requirements.missing.contains(.phoneOtp) {
                    invalidOtp()
                } else {
                    self.checkSubmitAndTransition(
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
            self.transitionWithVerificationPageDataResult(updateDataResult, completion: completion)
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
        updateDataResult: Result<StripeAPI.VerificationPageData, Error>
    ) async {
        await withCheckedContinuation { continuation in
            handleVerificationPageDataResult(
                collectedData: collectedData,
                updateDataResult: updateDataResult,
                completion: {
                    continuation.resume()
                },
                successPageData: { _ in
                    self.checkSubmitAndTransition(
                        updateDataResult: updateDataResult,
                        completion: {
                            continuation.resume()
                        }
                    )
                }
            )
        }
    }

    /// Calculate the clearData parameter from the collectedData to be generated by the following
    ///    allTypes - typesAlreadyCollected - typesToBeCollected
    private func calculateClearData(
        dataToBeCollected: StripeAPI.VerificationPageCollectedData
    ) -> StripeAPI.VerificationPageClearData {

        let initialMissings: Set<StripeAPI.VerificationPageFieldType>
        if let verificationPageResponse = verificationPageResponse {
            do {
                initialMissings = try verificationPageResponse.get().requirements.missing
            } catch {
                assertionFailure("verificationPageResponse could not be read, using StripeAPI.VerificationPageFieldType.allCases as initialMissings")
                analyticsClient.logGenericError(
                    error: error,
                    additionalMetadata: [
                        "error_context": "clear_data_calculation",
                        "screen_name": flowController.analyticsLastScreen?.analyticsScreenName.rawValue ?? "unknown",
                    ],
                    sheetController: self
                )
                initialMissings = Set(StripeAPI.VerificationPageFieldType.allCases)
            }
        } else {
            assertionFailure("verificationPageResponse is nil, using StripeAPI.VerificationPageFieldType.allCases as initialMissings")
            analyticsClient.logGenericError(
                error: VerificationSheetControllerError.missingVerificationPageResponseForClearDataCalculation,
                additionalMetadata: [
                    "error_context": "clear_data_calculation",
                    "screen_name": flowController.analyticsLastScreen?.analyticsScreenName.rawValue ?? "unknown",
                ],
                sheetController: self
            )
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

private extension VerificationSheetController {
    func verificationPageResponseOrLogMissing(
        _ error: VerificationSheetControllerError,
        assertionMessage: String,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) -> Result<StripeAPI.VerificationPage, Error>? {
        guard let verificationPageResponse = verificationPageResponse else {
            assertionFailure(assertionMessage)
            analyticsClient.logGenericError(
                error: error,
                additionalMetadata: [
                    "error_context": "verification_page_response_missing",
                    "screen_name": flowController.analyticsLastScreen?.analyticsScreenName.rawValue ?? "unknown",
                ],
                filePath: filePath,
                line: line,
                sheetController: self
            )
            return nil
        }
        return verificationPageResponse
    }

    func verificationPageOrLogError(
        missingError: VerificationSheetControllerError,
        assertionMessage: String,
        filePath: StaticString = #filePath,
        line: UInt = #line
    ) -> StripeAPI.VerificationPage? {
        guard let verificationPageResponse = verificationPageResponseOrLogMissing(
            missingError,
            assertionMessage: assertionMessage,
            filePath: filePath,
            line: line
        ) else {
            return nil
        }
        do {
            return try verificationPageResponse.get()
        } catch {
            assertionFailure(assertionMessage)
            analyticsClient.logGenericError(
                error: error,
                additionalMetadata: [
                    "error_context": "verification_page_response_read",
                    "screen_name": flowController.analyticsLastScreen?.analyticsScreenName.rawValue ?? "unknown",
                ],
                filePath: filePath,
                line: line,
                sheetController: self
            )
            return nil
        }
    }
}

// MARK: - VerificationSheetFlowControllerDelegate

extension VerificationSheetController: @MainActor VerificationSheetFlowControllerDelegate {
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
        Task { @MainActor in
            let verificationPage = try? await apiClient.getIdentityVerificationPage()
            self.isVerificationPageSubmitted = verificationPage?.submitted ?? false
            self.delegate?.verificationSheetController(
                self,
                didFinish: self.isVerificationPageSubmitted ? .flowCompleted : .flowCanceled
            )
        }
    }
}

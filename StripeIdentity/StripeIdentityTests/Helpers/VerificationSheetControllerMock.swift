//
//  VerificationSheetControllerMock.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 11/5/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils
import UIKit
import XCTest

@testable import StripeIdentity

final class VerificationSheetControllerMock: VerificationSheetControllerProtocol {
    func loadAndUpdateUI(skipTestMode: Bool) {
        self.skipTestMode = skipTestMode
    }

    func overrideTestModeReturnValue(result: StripeIdentity.IdentityVerificationSheet.VerificationFlowResult) {
        self.testModeReturnResult = result
    }

    func clearCollectedData(field: StripeCore.StripeAPI.VerificationPageFieldType) {
        // no-op
    }
    var verificationPageResponse: Result<StripeAPI.VerificationPage, Error>?

    var apiClient: IdentityAPIClient
    let flowController: VerificationSheetFlowControllerProtocol
    var collectedData: StripeAPI.VerificationPageCollectedData
    let mlModelLoader: IdentityMLModelLoaderProtocol
    let analyticsClient: IdentityAnalyticsClient

    weak var delegate: VerificationSheetControllerDelegate?

    var needBack: Bool = true

    var testModeReturnResult: StripeIdentity.IdentityVerificationSheet.VerificationFlowResult?
    var testModeTransitionCallback: (() -> Void)?

    var skipTestMode: Bool?

    private(set) var didLoadAndUpdateUI = false

    private(set) var savedData: StripeAPI.VerificationPageCollectedData?
    var saveAndTransitionCallback: (() -> Void)?
    private(set) var uploadedDocumentsResult: Result<DocumentUploaderProtocol.CombinedFileData, Error>?
    private(set) var frontUploadedDocumentsResult: Result<StripeAPI.VerificationPageDataDocumentFileData, Error>?
    private(set) var backUploadedDocumentsResult: Result<StripeAPI.VerificationPageDataDocumentFileData, Error>?
    private(set) var uploadedSelfieResult: Result<SelfieUploader.FileData, Error>?

    private(set) var didCheckSubmitAndTransition = false
    private(set) var didSaveDocumentFrontAndDecideBack = false
    private(set) var didSaveDocumentBackAndTransition = false
    var saveDocumentFrontAndDecideBackCallback: (() -> Void)?
    var saveDocumentBackAndTransitionCallback: (() -> Void)?
    var forceDocumentFrontAndDecideBackHandler: (() async -> Bool)?
    var forceDocumentBackAndTransitionHandler: (() async -> Void)?

    var missingType: StripeIdentity.IndividualFormElement.MissingType?
    var transitionedToIndividual: Bool = false
    var transitionedToSelfieCapture: Bool = false
    var transitionedToSelfieCaptureTrainingConsent: Bool?
    var transitionedToDocumentCapture: Bool = false

    var completeOption: CompleteOptionView.CompleteOption?

    var phoneOtpSuccessResult: StripeCore.StripeAPI.VerificationPageData?
    var generatePhoneOtpHandler: (() async -> StripeCore.StripeAPI.VerificationPageData)?
    var cannotVerifyPhoneOtpHandler: (() async -> Void)?
    var cannotVerifyPhoneOtpCalled: Bool = false

    var saveOtpAndMaybeTransitionCompletion: (() -> Void)?
    var saveOtpAndMaybeTransitionInvalidOtp: (() -> Void)?

    init(
        apiClient: IdentityAPIClient = IdentityAPIClientTestMock(),
        flowController: VerificationSheetFlowControllerProtocol =
            VerificationSheetFlowControllerMock(),
        collectedData: StripeAPI.VerificationPageCollectedData = .init(),
        mlModelLoader: IdentityMLModelLoaderProtocol = IdentityMLModelLoaderMock(),
        analyticsClient: IdentityAnalyticsClient = .init(
            verificationSessionId: "",
            analyticsClient: MockAnalyticsClientV2()
        )
    ) {
        self.apiClient = apiClient
        self.flowController = flowController
        self.collectedData = collectedData
        self.mlModelLoader = mlModelLoader
        self.analyticsClient = analyticsClient
    }

    func loadAndUpdateUI() {
        didLoadAndUpdateUI = true
    }

    func saveAndTransition(
        from fromScreen: IdentityAnalyticsClient.ScreenName,
        collectedData: StripeAPI.VerificationPageCollectedData
    ) async {
        savedData = collectedData
        saveAndTransitionCallback?()
    }

    func checkSubmitAndTransition(
        updateDataResult: Result<StripeAPI.VerificationPageData, Error>? = nil,
        completion: @escaping () -> Void
    ) {
        didCheckSubmitAndTransition = true
    }

    func saveDocumentFrontAndDecideBack(
        from fromScreen: IdentityAnalyticsClient.ScreenName,
        documentUploader: DocumentUploaderProtocol
    ) async -> Bool {
        didSaveDocumentFrontAndDecideBack = true

        let result = await documentUploader.frontUploadResult()
        self.frontUploadedDocumentsResult = result
        saveDocumentFrontAndDecideBackCallback?()
        if self.needBack {
            return true
        } else {
            return false
        }
    }

    func saveDocumentBackAndTransition(
        from fromScreen: IdentityAnalyticsClient.ScreenName,
        documentUploader: DocumentUploaderProtocol
    ) async {
        didSaveDocumentBackAndTransition = true
        let result = await documentUploader.backUploadResult()
        backUploadedDocumentsResult = result
        saveDocumentBackAndTransitionCallback?()
    }

    func forceDocumentFrontAndDecideBack(from fromScreen: StripeIdentity.IdentityAnalyticsClient.ScreenName) async -> Bool {
        if let forceDocumentFrontAndDecideBackHandler {
            return await forceDocumentFrontAndDecideBackHandler()
        }
        // no-op
        return false
    }

    func forceDocumentBackAndTransition(
        from fromScreen: StripeIdentity.IdentityAnalyticsClient.ScreenName
    ) async {
        if let forceDocumentBackAndTransitionHandler {
            await forceDocumentBackAndTransitionHandler()
        }
        // no-op
    }

    func saveSelfieFileDataAndTransition(
        from fromScreen: IdentityAnalyticsClient.ScreenName,
        selfieUploader: SelfieUploaderProtocol,
        capturedImages: FaceCaptureData,
        trainingConsent: Bool
    ) async {
        let result = await selfieUploader.uploadResult()
        self.uploadedSelfieResult = result
    }

    func saveOtpAndMaybeTransition(from fromScreen: StripeIdentity.IdentityAnalyticsClient.ScreenName, otp otpValue: String, completion: @escaping () -> Void, invalidOtp: @escaping () -> Void) {
        saveOtpAndMaybeTransitionCompletion = completion
        saveOtpAndMaybeTransitionInvalidOtp = invalidOtp

    }

    func verifyAndTransition(simulateDelay: Bool) async {
        testModeReturnResult = .flowCompleted
        completeOption = simulateDelay ? .successAsync : .success
        testModeTransitionCallback?()
    }

    func unverifyAndTransition(simulateDelay: Bool) async {
        testModeReturnResult = .flowCompleted
        completeOption = simulateDelay ? .failureAsync : .failure
        testModeTransitionCallback?()
    }

    func generatePhoneOtp() async -> StripeCore.StripeAPI.VerificationPageData {
        let mockResult: StripeCore.StripeAPI.VerificationPageData
        if let generatePhoneOtpHandler {
            mockResult = await generatePhoneOtpHandler()
        } else {
            mockResult = try! VerificationPageDataMock.response200.make()
        }
        phoneOtpSuccessResult = mockResult
        return mockResult
    }

    func sendCannotVerifyPhoneOtpAndTransition() async {
        self.cannotVerifyPhoneOtpCalled = true
        if let cannotVerifyPhoneOtpHandler {
            await cannotVerifyPhoneOtpHandler()
        }
    }

    func transitionToCountryNotListed(missingType: StripeIdentity.IndividualFormElement.MissingType) {
        self.missingType = missingType
    }

    func transitionToIndividual() {
        self.transitionedToIndividual = true
    }

    func transitionToSelfieCapture(
        trainingConsent: Bool?
    ) {
        self.transitionedToSelfieCapture = true
        self.transitionedToSelfieCaptureTrainingConsent = trainingConsent
    }

    func transitionToDocumentCapture() {
        self.transitionedToDocumentCapture = true
    }
}

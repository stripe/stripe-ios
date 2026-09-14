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

    var skipTestMode: Bool?

    private(set) var didLoadAndUpdateUI = false

    private(set) var savedData: StripeAPI.VerificationPageCollectedData?
    private(set) var uploadedDocumentsResult: Result<DocumentUploaderProtocol.CombinedFileData, Error>?
    private(set) var frontUploadedDocumentsResult: Result<StripeAPI.VerificationPageDataDocumentFileData, Error>?
    private(set) var backUploadedDocumentsResult: Result<StripeAPI.VerificationPageDataDocumentFileData, Error>?
    private(set) var uploadedSelfieResult: Result<SelfieUploader.FileData, Error>?

    private(set) var didCheckSubmitAndTransition = false
    private(set) var didSaveDocumentFrontAndDecideBack = false
    private(set) var didSaveDocumentBackAndTransition = false

    var missingType: StripeIdentity.IndividualFormElement.MissingType?
    var transitionedToIndividual: Bool = false
    var transitionedToSelfieCapture: Bool = false
    var transitionedToDocumentCapture: Bool = false

    var completeOption: CompleteOptionView.CompleteOption?

    var generatePhonOtpSuccessCallback: ((StripeCore.StripeAPI.VerificationPageData) -> Void)?
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
        collectedData: StripeAPI.VerificationPageCollectedData,
        completion: @escaping () -> Void
    ) {
        savedData = collectedData
        completion()
    }

    func checkSubmitAndTransition(
        updateDataResult: Result<StripeAPI.VerificationPageData, Error>? = nil,
        completion: @escaping () -> Void
    ) {
        didCheckSubmitAndTransition = true
    }

    func saveDocumentFrontAndDecideBack(
        from fromScreen: IdentityAnalyticsClient.ScreenName,
        documentUploader: DocumentUploaderProtocol,
        onCompletion: @escaping (_ isBackRequired: Bool) -> Void
    ) {
        didSaveDocumentFrontAndDecideBack = true
        documentUploader.frontUploadFuture?.observe { [self] result in
            self.frontUploadedDocumentsResult = result
            if self.needBack {
                onCompletion(true)
            } else {
                onCompletion(false)
            }

        }
    }

    func saveDocumentBackAndTransition(
        from fromScreen: IdentityAnalyticsClient.ScreenName,
        documentUploader: DocumentUploaderProtocol,
        completion: @escaping () -> Void
    ) {
        didSaveDocumentBackAndTransition = true
        documentUploader.backUploadFuture?.observe { [weak self] result in
            self?.backUploadedDocumentsResult = result
            completion()
        }
    }

    func forceDocumentFrontAndDecideBack(from fromScreen: StripeIdentity.IdentityAnalyticsClient.ScreenName, onCompletion: @escaping (Bool) -> Void) {
        // no-op
    }

    func forceDocumentBackAndTransition(
        from fromScreen: StripeIdentity.IdentityAnalyticsClient.ScreenName,
        completion: @escaping () -> Void
    ) {
        // no-op
    }

    func saveSelfieFileDataAndTransition(
        from fromScreen: IdentityAnalyticsClient.ScreenName,
        selfieUploader: SelfieUploaderProtocol,
        capturedImages: FaceCaptureData,
        trainingConsent: Bool,
        completion: @escaping () -> Void
    ) {
        selfieUploader.uploadFuture?.observe { [weak self] result in
            self?.uploadedSelfieResult = result
            completion()
        }
    }

    func saveOtpAndMaybeTransition(from fromScreen: StripeIdentity.IdentityAnalyticsClient.ScreenName, otp otpValue: String, completion: @escaping () -> Void, invalidOtp: @escaping () -> Void) {
        saveOtpAndMaybeTransitionCompletion = completion
        saveOtpAndMaybeTransitionInvalidOtp = invalidOtp

    }

    func verifyAndTransition(simulateDelay: Bool, completion: @escaping () -> Void) {
        testModeReturnResult = .flowCompleted
        completeOption = simulateDelay ? .successAsync : .success
    }

    func unverifyAndTransition(simulateDelay: Bool, completion: @escaping () -> Void) {
        testModeReturnResult = .flowCompleted
        completeOption = simulateDelay ? .failureAsync : .failure
    }

    func generatePhoneOtp(using successCallback: @escaping (StripeCore.StripeAPI.VerificationPageData) -> Void) {
        generatePhonOtpSuccessCallback = successCallback
    }

    func sendCannotVerifyPhoneOtpAndTransition(completion: @escaping () -> Void) {
        self.cannotVerifyPhoneOtpCalled = true
    }

    func transitionToCountryNotListed(missingType: StripeIdentity.IndividualFormElement.MissingType) {
        self.missingType = missingType
    }

    func transitionToIndividual() {
        self.transitionedToIndividual = true
    }

    func transitionToSelfieCapture() {
        self.transitionedToSelfieCapture = true
    }

    func transitionToDocumentCapture() {
        self.transitionedToDocumentCapture = true
    }

}

//
//  VerificationSheetControllerTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 10/27/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils
import UIKit
import XCTest

@testable import StripeIdentity

final class VerificationSheetControllerTest: XCTestCase {

    let mockVerificationSessionId = "vs_123"
    let mockEphemeralKeySecret = "sk_test_123"

    private var mockFlowController: VerificationSheetFlowControllerMock!
    private var controller: VerificationSheetController!
    private var mockAPIClient: IdentityAPIClientTestMock!
    // swiftlint:disable:next weak_delegate
    private var mockDelegate: MockDelegate!
    private var mockMLModelLoader: IdentityMLModelLoaderMock!
    private var mockAnalyticsClient: MockAnalyticsClientV2!
    private var identityAnalyticsClient: IdentityAnalyticsClient!
    private var exp: XCTestExpectation!

    override func setUp() {
        super.setUp()

        // Mock the api client
        mockAPIClient = IdentityAPIClientTestMock(
            verificationSessionId: mockVerificationSessionId,
            ephemeralKeySecret: mockEphemeralKeySecret
        )
        mockDelegate = MockDelegate()
        mockMLModelLoader = IdentityMLModelLoaderMock()
        mockFlowController = VerificationSheetFlowControllerMock()
        mockAnalyticsClient = MockAnalyticsClientV2()
        identityAnalyticsClient = .init(
            verificationSessionId: "",
            analyticsClient: mockAnalyticsClient
        )
        controller = VerificationSheetController(
            apiClient: mockAPIClient,
            flowController: mockFlowController,
            mlModelLoader: mockMLModelLoader,
            analyticsClient: identityAnalyticsClient
        )
        controller.delegate = mockDelegate
        exp = XCTestExpectation(description: "Finished API call")
    }

    func testLoadValidResponse() throws {
        let mockResponse = try VerificationPageMock.response200.make()

        // Load
        controller.load().observe { _ in
            self.exp.fulfill()
        }

        // Verify 1 request made with secret
        XCTAssertEqual(mockAPIClient.verificationPage.requestHistory.count, 1)

        // Verify result is nil until API responds to request
        XCTAssertNil(controller.verificationPageResponse)

        // Respond to request with success
        mockAPIClient.verificationPage.respondToRequests(with: .success(mockResponse))

        // Verify completion block is called
        wait(for: [exp], timeout: 1)

        // Verify response updated on controller
        XCTAssertEqual(try? controller.verificationPageResponse?.get(), mockResponse)
        XCTAssertTrue(mockMLModelLoader.didStartLoadingDocumentModels)
        XCTAssertTrue(mockMLModelLoader.didStartLoadingFaceModels)
    }

    func testLoadErrorResponse() throws {
        let mockError = NSError(domain: "", code: 0, userInfo: nil)

        // Load
        controller.load().observe { _ in
            self.exp.fulfill()
        }

        // Respond to request with error
        mockAPIClient.verificationPage.respondToRequests(with: .failure(mockError))

        // Verify completion block is called
        wait(for: [exp], timeout: 1)

        // Verify error updated on controller
        guard case .failure = controller.verificationPageResponse else {
            return XCTFail("Expected failure")
        }
    }

    func testLoadAndUpdateUI() throws {
        let mockResponse = try VerificationPageMock.response200.make()
        controller.loadAndUpdateUI()

        // Respond to request with success
        mockAPIClient.verificationPage.respondToRequests(with: .success(mockResponse))

        // Verify response sent to flowController
        wait(for: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
        XCTAssertEqual(
            try? mockFlowController.transitionedWithStaticContentResult?.get(),
            mockResponse
        )
    }

    func testSaveDataValidResponse() throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        let mockResponse = try VerificationPageDataMock.noErrors.make()
        let mockData = StripeAPI.VerificationPageCollectedData(biometricConsent: true)
        mockFlowController.uncollectedFields = [.idDocumentType, .idDocumentFront, .idDocumentBack]

        // Save data
        controller.saveAndTransition(from: .biometricConsent, collectedData: mockData) {
            self.exp.fulfill()
        }

        // Verify analytics client updated
        XCTAssertEqual(identityAnalyticsClient.timeToScreenFromScreen, .biometricConsent)

        // Verify 1 request made with Id, EAK, and collected data
        XCTAssertEqual(mockAPIClient.verificationPageData.requestHistory.count, 1)
        XCTAssertEqual(
            mockAPIClient.verificationPageData.requestHistory.first,
            .init(
                clearData: .init(
                    biometricConsent: false,
                    face: true,
                    idDocumentBack: true,
                    idDocumentFront: true,
                    idDocumentType: true,
                    idNumber: true,
                    dob: true,
                    name: true,
                    address: true
                ),
                collectedData: mockData
            )
        )

        // Respond to request with success
        mockAPIClient.verificationPageData.respondToRequests(with: .success(mockResponse))

        let submitRequestExp = expectation(description: "submit request made")
        mockAPIClient.verificationSessionSubmit.callBackOnRequest {
            submitRequestExp.fulfill()
        }
        wait(for: [submitRequestExp], timeout: 1)

        // Verify submit request
        XCTAssertEqual(mockAPIClient.verificationSessionSubmit.requestHistory.count, 1)
        mockAPIClient.verificationSessionSubmit.respondToRequests(with: .success(mockResponse))

        // Verify completion block is called
        wait(for: [exp], timeout: 1)

        // Verify value cached locally
        XCTAssertEqual(controller.collectedData.biometricConsent, true)

        // Verify response sent to flowController
        wait(for: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
        XCTAssertEqual(
            try? mockFlowController.transitionedWithUpdateDataResult?.get(),
            mockResponse
        )
    }

    func testSaveDataErrorResponse() throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        let mockError = NSError(domain: "", code: 0, userInfo: nil)
        let mockData = StripeAPI.VerificationPageCollectedData(biometricConsent: true)

        // Save data
        controller.saveAndTransition(from: .biometricConsent, collectedData: mockData) {
            self.exp.fulfill()
        }

        // Verify analytics client updated
        XCTAssertEqual(identityAnalyticsClient.timeToScreenFromScreen, .biometricConsent)

        // Respond to request with failure
        mockAPIClient.verificationPageData.respondToRequests(with: .failure(mockError))

        // Verify completion block is called
        wait(for: [exp], timeout: 1)

        // Verify value not cached locally
        XCTAssertNil(controller.collectedData.biometricConsent)

        // Verify response sent to flowController
        wait(for: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
        guard case .failure = mockFlowController.transitionedWithUpdateDataResult else {
            return XCTFail("Expected failure")
        }
    }

    func testSaveDocumentFrontNotNeedbackSuccess() throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        let frontFileData = (VerificationPageDataUpdateMock.default.collectedData?.idDocumentFront)!

        let mockResponse = try VerificationPageDataMock.noErrors.make()
        let mockDocumentUploader = DocumentUploaderMock()

        let saveRequestExp = expectation(description: "Save data request was made")
        mockAPIClient.verificationPageData.callBackOnRequest {
            saveRequestExp.fulfill()
        }

        let notNeedbackExp = expectation(description: "onNotNeedback is called")
        controller.saveDocumentFrontAndDecideBack(
            from: .biometricConsent,
            documentUploader: mockDocumentUploader,
            onCompletion: { isBackRequired in
                if !isBackRequired {
                    notNeedbackExp.fulfill()
                }
            }
        )

        // Mock that document upload succeeded
        mockDocumentUploader.frontUploadPromise.resolve(with: frontFileData)

        // Verify save data request was made
        wait(for: [saveRequestExp], timeout: 1)
        XCTAssertEqual(mockAPIClient.verificationPageData.requestHistory.count, 1)
        XCTAssertEqual(
            mockAPIClient.verificationPageData.requestHistory.first?.collectedData?.idDocumentFront,
            frontFileData
        )

        // Respond to request with success
        mockAPIClient.verificationPageData.respondToRequests(with: .success(mockResponse))
        let submitRequestExp = expectation(description: "submit request made")
        mockAPIClient.verificationSessionSubmit.callBackOnRequest {
            submitRequestExp.fulfill()
        }
        wait(for: [submitRequestExp], timeout: 1)

        // Verify submit request
        XCTAssertEqual(mockAPIClient.verificationSessionSubmit.requestHistory.count, 1)
        mockAPIClient.verificationSessionSubmit.respondToRequests(with: .success(mockResponse))

        // Verify completion block is called
        wait(for: [notNeedbackExp], timeout: 1)

        // Verify analytics client updated
        XCTAssertEqual(identityAnalyticsClient.timeToScreenFromScreen, .biometricConsent)

        // Verify values cached locally
        XCTAssertEqual(controller.collectedData.idDocumentFront, frontFileData)

        // Verify response sent to flowController
        wait(for: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
    }

    func testSaveDocumentFrontNeedbackSuccess() throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        let frontFileData = (VerificationPageDataUpdateMock.default.collectedData?.idDocumentFront)!

        let mockResponse = try VerificationPageDataMock.noErrorsNeedback.make()
        let mockDocumentUploader = DocumentUploaderMock()

        let saveRequestExp = expectation(description: "Save data request was made")
        mockAPIClient.verificationPageData.callBackOnRequest {
            saveRequestExp.fulfill()
        }

        let needBackExp = expectation(description: "onNeedBack is called")
        controller.saveDocumentFrontAndDecideBack(
            from: .biometricConsent,
            documentUploader: mockDocumentUploader,
            onCompletion: { isBackRequired in
                if isBackRequired {
                    needBackExp.fulfill()
                }
            }
        )

        // Mock that document upload succeeded
        mockDocumentUploader.frontUploadPromise.resolve(with: frontFileData)

        // Verify save data request was made
        wait(for: [saveRequestExp], timeout: 1)
        XCTAssertEqual(mockAPIClient.verificationPageData.requestHistory.count, 1)
        XCTAssertEqual(
            mockAPIClient.verificationPageData.requestHistory.first?.collectedData?.idDocumentFront,
            frontFileData
        )

        // Respond to request with success
        mockAPIClient.verificationPageData.respondToRequests(with: .success(mockResponse))

        // Verify completion block is called
        wait(for: [needBackExp], timeout: 1)

        // Verify values cached locally
        XCTAssertEqual(controller.collectedData.idDocumentFront, frontFileData)
    }

    func testSaveDocumentFrontFailure() throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        let mockError = NSError(domain: "", code: 0, userInfo: nil)
        let mockDocumentUploader = DocumentUploaderMock()

        controller.saveDocumentFrontAndDecideBack(
            from: .biometricConsent,
            documentUploader: mockDocumentUploader,
            onCompletion: { _ in }
        )
        // Mock that document upload failed
        mockDocumentUploader.frontUploadPromise.reject(with: mockError)

        // Verify values cached locally
        XCTAssertEqual(controller.collectedData.idDocumentFront, nil)

        // Verify save data request was not made
        XCTAssertEqual(mockAPIClient.verificationPageData.requestHistory.count, 0)

        // Verify response sent to flowController
        wait(for: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
        guard case .failure = mockFlowController.transitionedWithUpdateDataResult else {
            return XCTFail("Expected failure")
        }
    }

    func testSaveDocumentBackSuccess() throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        let backFileData = (VerificationPageDataUpdateMock.default.collectedData?.idDocumentBack)!

        let mockResponse = try VerificationPageDataMock.noErrors.make()
        let mockDocumentUploader = DocumentUploaderMock()

        let saveRequestExp = expectation(description: "Save data request was made")
        mockAPIClient.verificationPageData.callBackOnRequest {
            saveRequestExp.fulfill()
        }

        controller.saveDocumentBackAndTransition(
            from: .biometricConsent,
            documentUploader: mockDocumentUploader
        ) {
            self.exp.fulfill()
        }

        // Mock that document upload succeeded
        mockDocumentUploader.backUploadPromise.resolve(with: backFileData)

        // Verify save data request was made
        wait(for: [saveRequestExp], timeout: 1)
        XCTAssertEqual(mockAPIClient.verificationPageData.requestHistory.count, 1)
        XCTAssertEqual(
            mockAPIClient.verificationPageData.requestHistory.first?.collectedData?.idDocumentBack,
            backFileData
        )

        // Respond to request with success
        mockAPIClient.verificationPageData.respondToRequests(with: .success(mockResponse))

        let submitRequestExp = expectation(description: "submit request made")
        mockAPIClient.verificationSessionSubmit.callBackOnRequest {
            submitRequestExp.fulfill()
        }
        wait(for: [submitRequestExp], timeout: 1)

        // Verify submit request
        XCTAssertEqual(mockAPIClient.verificationSessionSubmit.requestHistory.count, 1)
        mockAPIClient.verificationSessionSubmit.respondToRequests(with: .success(mockResponse))

        // Verify completion block is called
        wait(for: [exp], timeout: 1)

        // Verify analytics client updated
        XCTAssertEqual(identityAnalyticsClient.timeToScreenFromScreen, .biometricConsent)

        // Verify values cached locally
        XCTAssertEqual(controller.collectedData.idDocumentBack, backFileData)

        // Verify response sent to flowController
        wait(for: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
    }

    func testSaveDocumentBackFailure() throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        let mockError = NSError(domain: "", code: 0, userInfo: nil)
        let mockDocumentUploader = DocumentUploaderMock()

        controller.saveDocumentBackAndTransition(
            from: .biometricConsent,
            documentUploader: mockDocumentUploader
        ) {}

        // Mock that document upload failed
        mockDocumentUploader.backUploadPromise.reject(with: mockError)

        // Verify values cached locally
        XCTAssertEqual(controller.collectedData.idDocumentBack, nil)

        // Verify save data request was not made
        XCTAssertEqual(mockAPIClient.verificationPageData.requestHistory.count, 0)

        // Verify response sent to flowController
        wait(for: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
        guard case .failure = mockFlowController.transitionedWithUpdateDataResult else {
            return XCTFail("Expected failure")
        }
    }

    func testSaveDataSubmitsValidResponse() throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        // Mock time to submit
        mockFlowController.isFinishedCollecting = true

        let mockDataResponse = try VerificationPageDataMock.noErrors.make()
        let mockSubmitResponse = try VerificationPageDataMock.submitted.make()
        let mockData = VerificationPageDataUpdateMock.default.collectedData!

        // Mock number of attempted scans
        controller.analyticsClient.countDidStartDocumentScan(for: .front)
        controller.analyticsClient.countDidStartDocumentScan(for: .back)
        controller.analyticsClient.countDidStartDocumentScan(for: .back)

        // Save data
        controller.saveAndTransition(from: .biometricConsent, collectedData: mockData) {
            self.exp.fulfill()
        }

        // Respond to save data request with success
        mockAPIClient.verificationPageData.respondToRequests(with: .success(mockDataResponse))

        let submitRequestExp = expectation(description: "submit request made")
        mockAPIClient.verificationSessionSubmit.callBackOnRequest {
            submitRequestExp.fulfill()
        }
        wait(for: [submitRequestExp], timeout: 1)

        // Verify submit request
        XCTAssertEqual(mockAPIClient.verificationSessionSubmit.requestHistory.count, 1)
        mockAPIClient.verificationSessionSubmit.respondToRequests(
            with: .success(mockSubmitResponse)
        )

        // Verify completion block is called
        wait(for: [exp], timeout: 1)

        // Verify value cached locally
        XCTAssertEqual(controller.collectedData, mockData)

        // Verify submitted
        XCTAssertEqual(controller.isVerificationPageSubmitted, true)

        // Verify succeed analytic
        XCTAssertEqual(mockAnalyticsClient.loggedAnalyticsPayloads.count, 1)
        let analytic = mockAnalyticsClient.loggedAnalyticsPayloads.first
        XCTAssert(
            analytic: analytic,
            hasProperty: "event_name",
            withValue: "verification_succeeded"
        )
        XCTAssert(analytic: analytic, hasMetadata: "doc_front_model_score", withValue: Float(1))
        XCTAssert(analytic: analytic, hasMetadata: "doc_back_model_score", withValue: Float(1))
        XCTAssert(analytic: analytic, hasMetadata: "selfie_model_score", withValue: Float(0.9))
        XCTAssert(analytic: analytic, hasMetadata: "doc_front_retry_times", withValue: 0)
        XCTAssert(analytic: analytic, hasMetadata: "doc_back_retry_times", withValue: 1)
        XCTAssert(analytic: analytic, hasMetadata: "selfie_retry_times", withValue: 0)

        // Verify response sent to flowController
        wait(for: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
        XCTAssertEqual(
            try? mockFlowController.transitionedWithUpdateDataResult?.get(),
            mockSubmitResponse
        )
    }

    func testSaveDataSubmitsErrorResponse() throws {
        let mockError = NSError(domain: "", code: 0, userInfo: nil)

        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        // Mock time to submit
        mockFlowController.isFinishedCollecting = true

        let mockData = StripeAPI.VerificationPageCollectedData(biometricConsent: true)
        let mockResponse = try VerificationPageDataMock.response200.make()

        // Save data
        controller.saveAndTransition(from: .biometricConsent, collectedData: mockData) {
            self.exp.fulfill()
        }

        // Respond to save data request with success
        mockAPIClient.verificationPageData.respondToRequests(with: .success(mockResponse))

        let submitRequestExp = expectation(description: "submit request made")
        mockAPIClient.verificationSessionSubmit.callBackOnRequest {
            submitRequestExp.fulfill()
        }
        wait(for: [submitRequestExp], timeout: 1)

        // Respond with error
        mockAPIClient.verificationSessionSubmit.respondToRequests(with: .failure(mockError))

        // Verify completion block is called
        wait(for: [exp], timeout: 1)

        // Verify not submitted
        XCTAssertEqual(controller.isVerificationPageSubmitted, false)

        // Verify no succeed analytic
        XCTAssertEqual(mockAnalyticsClient.loggedAnalyticsPayloads.count, 0)

        // Verify response sent to flowController
        wait(for: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
        guard case .failure = mockFlowController.transitionedWithUpdateDataResult else {
            return XCTFail("Expected failure")
        }
    }

    func testDismissResultNotSubmitted() throws {
        controller.verificationSheetFlowControllerDidDismissNativeView(mockFlowController)
        XCTAssertEqual(mockDelegate.result, .flowCanceled)
    }

    func testDismissResultSubmitted() throws {
        controller.isVerificationPageSubmitted = true
        controller.verificationSheetFlowControllerDidDismissNativeView(mockFlowController)
        XCTAssertEqual(mockDelegate.result, .flowCompleted)
    }
}

private final class MockDelegate: VerificationSheetControllerDelegate {
    private(set) var result: IdentityVerificationSheet.VerificationFlowResult?

    func verificationSheetController(
        _ controller: VerificationSheetControllerProtocol,
        didFinish result: IdentityVerificationSheet.VerificationFlowResult
    ) {
        self.result = result
    }
}

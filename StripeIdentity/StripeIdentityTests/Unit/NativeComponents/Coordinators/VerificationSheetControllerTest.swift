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

@MainActor
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
    private var mockDocumentUploader: DocumentUploaderMock!

    override func setUp() {
        super.setUp()

        mockDocumentUploader = DocumentUploaderMock()
        // Mock the api client
        mockAPIClient = IdentityAPIClientTestMock(
            verificationSessionId: mockVerificationSessionId,
            ephemeralKeySecret: mockEphemeralKeySecret
        )
        mockDelegate = MockDelegate()
        mockMLModelLoader = IdentityMLModelLoaderMock()
        mockFlowController = VerificationSheetFlowControllerMock()
        mockFlowController.documentUploader = mockDocumentUploader
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

    func testLoadValidResponse() async throws {
        let mockResponse = try VerificationPageMock.response200.make()
        let requestExp = expectation(description: "Request made")
        mockAPIClient.verificationPage.callBackOnRequest {
            requestExp.fulfill()
        }

        // Load
        let loadTask = Task {
            await controller.load()
        }
        await fulfillment(of: [requestExp], timeout: 1)

        // Verify 1 request made with secret
        XCTAssertEqual(mockAPIClient.verificationPage.requestHistory.count, 1)

        // Verify result is nil until API responds to request
        XCTAssertNil(controller.verificationPageResponse)

        // Respond to request with success
        mockAPIClient.verificationPage.respondToRequests(with: .success(mockResponse))

        // Verify load completes
        let result = await loadTask.value
        XCTAssertEqual(try? result.get(), mockResponse)

        // Verify response updated on controller
        XCTAssertEqual(try? controller.verificationPageResponse?.get(), mockResponse)
        XCTAssertTrue(mockMLModelLoader.didStartLoadingDocumentModels)
        XCTAssertTrue(mockMLModelLoader.didStartLoadingFaceModels)
    }

    func testLoadSubmittedValidResponse() async throws {
        let mockResponse = try VerificationPageMock.response200Submitted.make()
        let requestExp = expectation(description: "Request made")
        mockAPIClient.verificationPage.callBackOnRequest {
            requestExp.fulfill()
        }

        // Load
        let loadTask = Task {
            await controller.load()
        }
        await fulfillment(of: [requestExp], timeout: 1)

        // Verify 1 request made with secret
        XCTAssertEqual(mockAPIClient.verificationPage.requestHistory.count, 1)

        // Verify result is nil until API responds to request
        XCTAssertNil(controller.verificationPageResponse)

        // Respond to request with success
        mockAPIClient.verificationPage.respondToRequests(with: .success(mockResponse))

        // Verify load completes
        let result = await loadTask.value
        XCTAssertEqual(try? result.get(), mockResponse)

        // Verify response updated on controller
        XCTAssertEqual(try? controller.verificationPageResponse?.get(), mockResponse)
        XCTAssertTrue(mockMLModelLoader.didStartLoadingDocumentModels)
        XCTAssertTrue(mockMLModelLoader.didStartLoadingFaceModels)
        XCTAssertTrue(controller.isVerificationPageSubmitted)
    }

    func testLoadErrorResponse() async {
        let mockError = NSError(domain: "", code: 0, userInfo: nil)
        let requestExp = expectation(description: "Request made")
        mockAPIClient.verificationPage.callBackOnRequest {
            requestExp.fulfill()
        }

        // Load
        let loadTask = Task {
            await controller.load()
        }
        await fulfillment(of: [requestExp], timeout: 1)

        // Respond to request with error
        mockAPIClient.verificationPage.respondToRequests(with: .failure(mockError))

        // Verify load completes with error
        let result = await loadTask.value
        guard case .failure = result else {
            return XCTFail("Expected failure")
        }

        // Verify error updated on controller
        guard case .failure = controller.verificationPageResponse else {
            return XCTFail("Expected failure")
        }
    }

    func testLoadAndUpdateUI() async throws {
        let mockResponse = try VerificationPageMock.response200.make()
        let requestExp = expectation(description: "Request made")
        mockAPIClient.verificationPage.callBackOnRequest {
            requestExp.fulfill()
        }

        controller.loadAndUpdateUI(skipTestMode: true)
        await fulfillment(of: [requestExp], timeout: 1)

        // Respond to request with success
        mockAPIClient.verificationPage.respondToRequests(with: .success(mockResponse))

        // Verify response sent to flowController
        await fulfillment(of: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
        XCTAssertEqual(
            try? mockFlowController.transitionedWithStaticContentResult?.get(),
            mockResponse
        )
    }

    func testSaveDataValidResponse() async throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        let mockResponse = try VerificationPageDataMock.noErrors.make()
        let mockData = StripeAPI.VerificationPageCollectedData(biometricConsent: true)
        mockFlowController.uncollectedFields = [.idDocumentFront, .idDocumentBack]
        let saveRequestExp = expectation(description: "Save data request was made")
        mockAPIClient.verificationPageData.callBackOnRequest {
            saveRequestExp.fulfill()
        }

        // Save data
        let saveTask = Task {
            await controller.saveAndTransition(from: .biometricConsent, collectedData: mockData)
        }
        await fulfillment(of: [saveRequestExp], timeout: 1)

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
                    idNumber: false,
                    dob: false,
                    name: false,
                    address: false,
                    phoneOtp: false
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
        await fulfillment(of: [submitRequestExp], timeout: 1)

        // Verify submit request
        XCTAssertEqual(mockAPIClient.verificationSessionSubmit.requestHistory.count, 1)
        mockAPIClient.verificationSessionSubmit.respondToRequests(with: .success(mockResponse))

        await saveTask.value

        // Verify value cached locally
        XCTAssertEqual(controller.collectedData.biometricConsent, true)

        // Verify response sent to flowController
        await fulfillment(of: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
        XCTAssertEqual(
            try? mockFlowController.transitionedWithUpdateDataResult?.get(),
            mockResponse
        )
    }

    func testSaveDataErrorResponse() async throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        let mockError = NSError(domain: "", code: 0, userInfo: nil)
        let mockData = StripeAPI.VerificationPageCollectedData(biometricConsent: true)
        let saveRequestExp = expectation(description: "Save data request was made")
        mockAPIClient.verificationPageData.callBackOnRequest {
            saveRequestExp.fulfill()
        }

        // Save data
        let saveTask = Task {
            await controller.saveAndTransition(from: .biometricConsent, collectedData: mockData)
        }
        await fulfillment(of: [saveRequestExp], timeout: 1)

        // Verify analytics client updated
        XCTAssertEqual(identityAnalyticsClient.timeToScreenFromScreen, .biometricConsent)

        // Respond to request with failure
        mockAPIClient.verificationPageData.respondToRequests(with: .failure(mockError))

        await saveTask.value

        // Verify value not cached locally
        XCTAssertNil(controller.collectedData.biometricConsent)

        // Verify response sent to flowController
        await fulfillment(of: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
        guard case .failure = mockFlowController.transitionedWithUpdateDataResult else {
            return XCTFail("Expected failure")
        }
    }

    func testSaveDocumentFrontNotNeedbackSuccess() async throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        let frontFileData = (VerificationPageDataUpdateMock.default.collectedData?.idDocumentFront)!

        let mockResponse = try VerificationPageDataMock.noErrors.make()

        let saveRequestExp = expectation(description: "Save data request was made")
        mockAPIClient.verificationPageData.callBackOnRequest {
            saveRequestExp.fulfill()
        }

        // Mock that document upload succeeded
        mockDocumentUploader.frontUploadResultValue = .success(frontFileData)

        let saveTask = Task {
            await controller.saveDocumentFrontAndDecideBack(
                from: .biometricConsent,
                documentUploader: mockDocumentUploader
            )
        }

        // Verify save data request was made
        await fulfillment(of: [saveRequestExp], timeout: 1)
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
        await fulfillment(of: [submitRequestExp], timeout: 1)

        // Verify submit request
        XCTAssertEqual(mockAPIClient.verificationSessionSubmit.requestHistory.count, 1)
        mockAPIClient.verificationSessionSubmit.respondToRequests(with: .success(mockResponse))

        let isBackRequired = await saveTask.value
        XCTAssertFalse(isBackRequired)

        // Verify analytics client updated
        XCTAssertEqual(identityAnalyticsClient.timeToScreenFromScreen, .biometricConsent)

        // Verify values cached locally
        XCTAssertEqual(controller.collectedData.idDocumentFront, frontFileData)

        // Verify response sent to flowController
        await fulfillment(of: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
    }

    func testForceDocumentFrontNotNeedbackSuccess() async throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        let frontFileData = (VerificationPageDataUpdateMock.default.collectedData?.idDocumentFront)!

        let mockResponse = try VerificationPageDataMock.noErrors.make()

        let saveRequestExp = expectation(description: "Save data request was made")
        mockAPIClient.verificationPageData.callBackOnRequest {
            saveRequestExp.fulfill()
        }

        // Mock that document upload succeeded
        mockDocumentUploader.frontUploadResultValue = .success(frontFileData)

        let saveTask = Task {
            await controller.forceDocumentFrontAndDecideBack(
                from: .biometricConsent
            )
        }

        // Verify save data request was made
        await fulfillment(of: [saveRequestExp], timeout: 1)
        XCTAssertEqual(mockAPIClient.verificationPageData.requestHistory.count, 1)
        XCTAssertEqual(
            mockAPIClient.verificationPageData.requestHistory.first?.collectedData?.idDocumentFront,
            frontFileData.withForceConfirm(true)
        )

        // Respond to request with success
        mockAPIClient.verificationPageData.respondToRequests(with: .success(mockResponse))
        let submitRequestExp = expectation(description: "submit request made")
        mockAPIClient.verificationSessionSubmit.callBackOnRequest {
            submitRequestExp.fulfill()
        }
        await fulfillment(of: [submitRequestExp], timeout: 1)

        // Verify submit request
        XCTAssertEqual(mockAPIClient.verificationSessionSubmit.requestHistory.count, 1)
        mockAPIClient.verificationSessionSubmit.respondToRequests(with: .success(mockResponse))

        let isBackRequired = await saveTask.value
        XCTAssertFalse(isBackRequired)

        // Verify analytics client updated
        XCTAssertEqual(identityAnalyticsClient.timeToScreenFromScreen, .biometricConsent)

        // Verify values cached locally
        XCTAssertEqual(controller.collectedData.idDocumentFront, frontFileData.withForceConfirm(true))

        // Verify response sent to flowController
        await fulfillment(of: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
    }

    func testSaveDocumentFrontNeedbackSuccess() async throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        let frontFileData = (VerificationPageDataUpdateMock.default.collectedData?.idDocumentFront)!

        let mockResponse = try VerificationPageDataMock.noErrorsNeedback.make()

        let saveRequestExp = expectation(description: "Save data request was made")
        mockAPIClient.verificationPageData.callBackOnRequest {
            saveRequestExp.fulfill()
        }

        // Mock that document upload succeeded
        mockDocumentUploader.frontUploadResultValue = .success(frontFileData)

        let saveTask = Task {
            await controller.saveDocumentFrontAndDecideBack(
                from: .biometricConsent,
                documentUploader: mockDocumentUploader
            )
        }

        // Verify save data request was made
        await fulfillment(of: [saveRequestExp], timeout: 1)
        XCTAssertEqual(mockAPIClient.verificationPageData.requestHistory.count, 1)
        XCTAssertEqual(
            mockAPIClient.verificationPageData.requestHistory.first?.collectedData?.idDocumentFront,
            frontFileData
        )

        // Respond to request with success
        mockAPIClient.verificationPageData.respondToRequests(with: .success(mockResponse))

        let isBackRequired = await saveTask.value
        XCTAssertTrue(isBackRequired)

        // Verify values cached locally
        XCTAssertEqual(controller.collectedData.idDocumentFront, frontFileData)
    }

    func testForceDocumentFrontNeedbackSuccess() async throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        let frontFileData = (VerificationPageDataUpdateMock.default.collectedData?.idDocumentFront)!

        let mockResponse = try VerificationPageDataMock.noErrorsNeedback.make()

        let saveRequestExp = expectation(description: "Save data request was made")
        mockAPIClient.verificationPageData.callBackOnRequest {
            saveRequestExp.fulfill()
        }

        // Mock that document upload succeeded
        mockDocumentUploader.frontUploadResultValue = .success(frontFileData)

        let saveTask = Task {
            await controller.forceDocumentFrontAndDecideBack(
                from: .biometricConsent
            )
        }

        // Verify save data request was made
        await fulfillment(of: [saveRequestExp], timeout: 1)
        XCTAssertEqual(mockAPIClient.verificationPageData.requestHistory.count, 1)
        XCTAssertEqual(
            mockAPIClient.verificationPageData.requestHistory.first?.collectedData?.idDocumentFront,
            frontFileData.withForceConfirm(true)
        )

        // Respond to request with success
        mockAPIClient.verificationPageData.respondToRequests(with: .success(mockResponse))

        let isBackRequired = await saveTask.value
        XCTAssertTrue(isBackRequired)

        // Verify values cached locally
        XCTAssertEqual(controller.collectedData.idDocumentFront, frontFileData.withForceConfirm(true))
    }

    func testSaveDocumentFrontFailure() async throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        let mockError = NSError(domain: "", code: 0, userInfo: nil)

        // Mock that document upload failed
        mockDocumentUploader.frontUploadResultValue = .failure(mockError)

        _ = await controller.saveDocumentFrontAndDecideBack(
            from: .biometricConsent,
            documentUploader: mockDocumentUploader
        )

        // Verify values cached locally
        XCTAssertEqual(controller.collectedData.idDocumentFront, nil)

        // Verify save data request was not made
        XCTAssertEqual(mockAPIClient.verificationPageData.requestHistory.count, 0)

        // Verify response sent to flowController
        await fulfillment(of: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
        guard case .failure = mockFlowController.transitionedWithUpdateDataResult else {
            return XCTFail("Expected failure")
        }
    }

    func testSaveDocumentBackSuccess() async throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        let backFileData = (VerificationPageDataUpdateMock.default.collectedData?.idDocumentBack)!

        let mockResponse = try VerificationPageDataMock.noErrors.make()

        let saveRequestExp = expectation(description: "Save data request was made")
        mockAPIClient.verificationPageData.callBackOnRequest {
            saveRequestExp.fulfill()
        }

        // Mock that document upload succeeded
        mockDocumentUploader.backUploadResultValue = .success(backFileData)

        let saveTask = Task {
            await controller.saveDocumentBackAndTransition(
                from: .biometricConsent,
                documentUploader: mockDocumentUploader
            )
        }

        // Verify save data request was made
        await fulfillment(of: [saveRequestExp], timeout: 1)
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
        await fulfillment(of: [submitRequestExp], timeout: 1)

        // Verify submit request
        XCTAssertEqual(mockAPIClient.verificationSessionSubmit.requestHistory.count, 1)
        mockAPIClient.verificationSessionSubmit.respondToRequests(with: .success(mockResponse))

        await saveTask.value

        // Verify analytics client updated
        XCTAssertEqual(identityAnalyticsClient.timeToScreenFromScreen, .biometricConsent)

        // Verify values cached locally
        XCTAssertEqual(controller.collectedData.idDocumentBack, backFileData)

        // Verify response sent to flowController
        await fulfillment(of: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
    }

    func testForceDocumentBackSuccess() async throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        let backFileData = (VerificationPageDataUpdateMock.default.collectedData?.idDocumentBack)!

        let mockResponse = try VerificationPageDataMock.noErrors.make()

        let saveRequestExp = expectation(description: "Save data request was made")
        mockAPIClient.verificationPageData.callBackOnRequest {
            saveRequestExp.fulfill()
        }

        // Mock that document upload succeeded
        mockDocumentUploader.backUploadResultValue = .success(backFileData)

        let saveTask = Task {
            await controller.forceDocumentBackAndTransition(
                from: .biometricConsent
            )
        }

        // Verify save data request was made
        await fulfillment(of: [saveRequestExp], timeout: 1)
        XCTAssertEqual(mockAPIClient.verificationPageData.requestHistory.count, 1)
        XCTAssertEqual(
            mockAPIClient.verificationPageData.requestHistory.first?.collectedData?.idDocumentBack,
            backFileData.withForceConfirm(true)
        )

        // Respond to request with success
        mockAPIClient.verificationPageData.respondToRequests(with: .success(mockResponse))

        let submitRequestExp = expectation(description: "submit request made")
        mockAPIClient.verificationSessionSubmit.callBackOnRequest {
            submitRequestExp.fulfill()
        }
        await fulfillment(of: [submitRequestExp], timeout: 1)

        // Verify submit request
        XCTAssertEqual(mockAPIClient.verificationSessionSubmit.requestHistory.count, 1)
        mockAPIClient.verificationSessionSubmit.respondToRequests(with: .success(mockResponse))

        await saveTask.value

        // Verify analytics client updated
        XCTAssertEqual(identityAnalyticsClient.timeToScreenFromScreen, .biometricConsent)

        // Verify values cached locally
        XCTAssertEqual(controller.collectedData.idDocumentBack, backFileData.withForceConfirm(true))

        // Verify response sent to flowController
        await fulfillment(of: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
    }

    func testSaveDocumentBackFailure() async throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        let mockError = NSError(domain: "", code: 0, userInfo: nil)

        // Mock that document upload failed
        mockDocumentUploader.backUploadResultValue = .failure(mockError)

        await controller.saveDocumentBackAndTransition(
            from: .biometricConsent,
            documentUploader: mockDocumentUploader
        )

        // Verify values cached locally
        XCTAssertEqual(controller.collectedData.idDocumentBack, nil)

        // Verify save data request was not made
        XCTAssertEqual(mockAPIClient.verificationPageData.requestHistory.count, 0)

        // Verify response sent to flowController
        await fulfillment(of: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
        guard case .failure = mockFlowController.transitionedWithUpdateDataResult else {
            return XCTFail("Expected failure")
        }
    }

    func testSaveDataSubmitsValidResponse() async throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        // Mock time to submit
        mockFlowController.isFinishedCollecting = true

        let mockDataResponse = try VerificationPageDataMock.noErrors.make()
        let mockSubmitResponse = try VerificationPageDataMock.submitted.make()
        let mockData = VerificationPageDataUpdateMock.default.collectedData!
        let saveRequestExp = expectation(description: "Save data request was made")
        mockAPIClient.verificationPageData.callBackOnRequest {
            saveRequestExp.fulfill()
        }

        // Mock number of attempted scans
        controller.analyticsClient.countDidStartDocumentScan(for: .front)
        controller.analyticsClient.countDidStartDocumentScan(for: .back)
        controller.analyticsClient.countDidStartDocumentScan(for: .back)

        // Save data
        let saveTask = Task {
            await controller.saveAndTransition(from: .biometricConsent, collectedData: mockData)
        }
        await fulfillment(of: [saveRequestExp], timeout: 1)

        // Respond to save data request with success
        mockAPIClient.verificationPageData.respondToRequests(with: .success(mockDataResponse))

        let submitRequestExp = expectation(description: "submit request made")
        mockAPIClient.verificationSessionSubmit.callBackOnRequest {
            submitRequestExp.fulfill()
        }
        await fulfillment(of: [submitRequestExp], timeout: 1)

        // Verify submit request
        XCTAssertEqual(mockAPIClient.verificationSessionSubmit.requestHistory.count, 1)
        mockAPIClient.verificationSessionSubmit.respondToRequests(
            with: .success(mockSubmitResponse)
        )

        await saveTask.value

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
        await fulfillment(of: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
        XCTAssertEqual(
            try? mockFlowController.transitionedWithUpdateDataResult?.get(),
            mockSubmitResponse
        )
    }

    func testSaveDataSubmitsFallbackResponse() async throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        // Mock time to submit
        mockFlowController.isFinishedCollecting = true

        let mockDataResponse = try VerificationPageDataMock.noErrors.make()
        let mockSubmitResponse = try VerificationPageDataMock.submittedNotClosed.make()
        let mockData = VerificationPageDataUpdateMock.default.collectedData!
        let saveRequestExp = expectation(description: "Save data request was made")
        mockAPIClient.verificationPageData.callBackOnRequest {
            saveRequestExp.fulfill()
        }

        // Mock number of attempted scans
        controller.analyticsClient.countDidStartDocumentScan(for: .front)
        controller.analyticsClient.countDidStartDocumentScan(for: .back)
        controller.analyticsClient.countDidStartDocumentScan(for: .back)

        // Save data
        let saveTask = Task {
            await controller.saveAndTransition(from: .biometricConsent, collectedData: mockData)
        }
        await fulfillment(of: [saveRequestExp], timeout: 1)

        // Respond to save data request with success
        mockAPIClient.verificationPageData.respondToRequests(with: .success(mockDataResponse))

        let submitRequestExp = expectation(description: "submit request made")
        mockAPIClient.verificationSessionSubmit.callBackOnRequest {
            submitRequestExp.fulfill()
        }
        await fulfillment(of: [submitRequestExp], timeout: 1)

        // Verify submit request
        XCTAssertEqual(mockAPIClient.verificationSessionSubmit.requestHistory.count, 1)
        mockAPIClient.verificationSessionSubmit.respondToRequests(
            with: .success(mockSubmitResponse)
        )

        await saveTask.value

        // Verify missing got updated
        XCTAssertEqual(try controller.verificationPageResponse?.get().requirements.missing, mockSubmitResponse.requirements.missing)

        // Verify collectedData got cleared
        XCTAssertEqual(controller.collectedData, StripeAPI.VerificationPageCollectedData())

        // Verify submitted is false
        XCTAssertEqual(controller.isVerificationPageSubmitted, false)

        // Verify response sent to flowController
        await fulfillment(of: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
        XCTAssertEqual(
            try? mockFlowController.transitionedWithUpdateDataResult?.get(),
            mockSubmitResponse
        )
    }

    func testSaveDataSubmitsErrorResponse() async throws {
        let mockError = NSError(domain: "", code: 0, userInfo: nil)

        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        // Mock time to submit
        mockFlowController.isFinishedCollecting = true

        let mockData = StripeAPI.VerificationPageCollectedData(biometricConsent: true)
        let mockResponse = try VerificationPageDataMock.response200.make()
        let saveRequestExp = expectation(description: "Save data request was made")
        mockAPIClient.verificationPageData.callBackOnRequest {
            saveRequestExp.fulfill()
        }

        // Save data
        let saveTask = Task {
            await controller.saveAndTransition(from: .biometricConsent, collectedData: mockData)
        }
        await fulfillment(of: [saveRequestExp], timeout: 1)

        // Respond to save data request with success
        mockAPIClient.verificationPageData.respondToRequests(with: .success(mockResponse))

        let submitRequestExp = expectation(description: "submit request made")
        mockAPIClient.verificationSessionSubmit.callBackOnRequest {
            submitRequestExp.fulfill()
        }
        await fulfillment(of: [submitRequestExp], timeout: 1)

        // Respond with error
        mockAPIClient.verificationSessionSubmit.respondToRequests(with: .failure(mockError))

        await saveTask.value

        // Verify not submitted
        XCTAssertEqual(controller.isVerificationPageSubmitted, false)

        // Verify no succeed analytic
        XCTAssertEqual(mockAnalyticsClient.loggedAnalyticsPayloads.count, 0)

        // Verify response sent to flowController
        await fulfillment(of: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
        guard case .failure = mockFlowController.transitionedWithUpdateDataResult else {
            return XCTFail("Expected failure")
        }
    }

    func testVerifyAndTransitionWithoutDelay() async throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        let requestExp = expectation(description: "verify request made")
        mockAPIClient.verifyUnverifyRequest.callBackOnRequest {
            requestExp.fulfill()
        }
        let verifyTask = Task {
            await controller.verifyAndTransition(simulateDelay: false)
        }
        await fulfillment(of: [requestExp], timeout: 1)

        XCTAssertEqual(mockAPIClient.verifyUnverifyRequest.requestHistory.count, 1)

        XCTAssertEqual(
            mockAPIClient.verifyUnverifyRequest.requestHistory.first,
            ["simulateDelay": false]
        )

        mockAPIClient.verifyUnverifyRequest.respondToRequests(with: .success(try VerificationPageDataMock.response200.make()))

        await verifyTask.value

        XCTAssertEqual(controller.testModeReturnValue, IdentityVerificationSheet.VerificationFlowResult.flowCompleted)
    }

    func testVerifyAndTransitionWithDelay() async throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        let requestExp = expectation(description: "verify request made")
        mockAPIClient.verifyUnverifyRequest.callBackOnRequest {
            requestExp.fulfill()
        }
        let verifyTask = Task {
            await controller.verifyAndTransition(simulateDelay: true)
        }
        await fulfillment(of: [requestExp], timeout: 1)

        XCTAssertEqual(mockAPIClient.verifyUnverifyRequest.requestHistory.count, 1)

        XCTAssertEqual(
            mockAPIClient.verifyUnverifyRequest.requestHistory.first,
            ["simulateDelay": true]
        )

        mockAPIClient.verifyUnverifyRequest.respondToRequests(with: .success(try VerificationPageDataMock.response200.make()))

        await verifyTask.value

        XCTAssertEqual(controller.testModeReturnValue, IdentityVerificationSheet.VerificationFlowResult.flowCompleted)
    }

    func testUnverifyAndTransitionWithoutDelay() async throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        let requestExp = expectation(description: "unverify request made")
        mockAPIClient.verifyUnverifyRequest.callBackOnRequest {
            requestExp.fulfill()
        }
        let unverifyTask = Task {
            await controller.unverifyAndTransition(simulateDelay: false)
        }
        await fulfillment(of: [requestExp], timeout: 1)

        XCTAssertEqual(mockAPIClient.verifyUnverifyRequest.requestHistory.count, 1)

        XCTAssertEqual(
            mockAPIClient.verifyUnverifyRequest.requestHistory.first,
            ["simulateDelay": false]
        )

        mockAPIClient.verifyUnverifyRequest.respondToRequests(with: .success(try VerificationPageDataMock.response200.make()))

        await unverifyTask.value

        XCTAssertEqual(controller.testModeReturnValue, IdentityVerificationSheet.VerificationFlowResult.flowCompleted)
    }

    func testUnverifyAndTransitionWithDelay() async throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        let requestExp = expectation(description: "unverify request made")
        mockAPIClient.verifyUnverifyRequest.callBackOnRequest {
            requestExp.fulfill()
        }
        let unverifyTask = Task {
            await controller.unverifyAndTransition(simulateDelay: true)
        }
        await fulfillment(of: [requestExp], timeout: 1)

        XCTAssertEqual(mockAPIClient.verifyUnverifyRequest.requestHistory.count, 1)

        XCTAssertEqual(
            mockAPIClient.verifyUnverifyRequest.requestHistory.first,
            ["simulateDelay": true]
        )

        mockAPIClient.verifyUnverifyRequest.respondToRequests(with: .success(try VerificationPageDataMock.response200.make()))

        await unverifyTask.value

        XCTAssertEqual(controller.testModeReturnValue, IdentityVerificationSheet.VerificationFlowResult.flowCompleted)
    }

    func testGeneratePhoneOtp() async throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        let requestExp = expectation(description: "generate OTP request made")
        mockAPIClient.verificationPageGeneratePhoneOtp.callBackOnRequest {
            requestExp.fulfill()
        }
        let generateTask = Task { await controller.generatePhoneOtp() }
        await fulfillment(of: [requestExp], timeout: 1)

        XCTAssertEqual(mockAPIClient.verificationPageGeneratePhoneOtp.requestHistory.count, 1)

        // Respond with generatePhoneOtp, trigger callback
        mockAPIClient.verificationPageGeneratePhoneOtp.respondToRequests(with: .success(try VerificationPageDataMock.response200.make()))
        _ = await generateTask.value
    }

    func testGeneratePhoneOtpFailureTransitionsAndReturnsNil() async throws {
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        let requestExp = expectation(description: "generate OTP request made")
        mockAPIClient.verificationPageGeneratePhoneOtp.callBackOnRequest {
            requestExp.fulfill()
        }

        let generateTask = Task { await controller.generatePhoneOtp() }
        await fulfillment(of: [requestExp], timeout: 1)

        let error = NSError(domain: "test", code: 1)
        mockAPIClient.verificationPageGeneratePhoneOtp.respondToRequests(with: .failure(error))

        await fulfillment(of: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
        let result = await generateTask.value
        XCTAssertNil(result)
    }

    func testCannotVerifyPhoneOtp() async throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        let requestExp = expectation(description: "cannot verify OTP request made")
        mockAPIClient.verificationPageCannotVerifyPhoneOtp.callBackOnRequest {
            requestExp.fulfill()
        }
        let cannotVerifyTask = Task { await controller.sendCannotVerifyPhoneOtpAndTransition() }
        await fulfillment(of: [requestExp], timeout: 1)

        XCTAssertEqual(mockAPIClient.verificationPageCannotVerifyPhoneOtp.requestHistory.count, 1)

        let submitRequestExp = expectation(description: "submit request made")
        mockAPIClient.verificationSessionSubmit.callBackOnRequest {
            submitRequestExp.fulfill()
        }
        mockAPIClient.verificationPageCannotVerifyPhoneOtp.respondToRequests(with: .success(try VerificationPageDataMock.response200.make()))
        await fulfillment(of: [submitRequestExp], timeout: 1)
        mockAPIClient.verificationSessionSubmit.respondToRequests(with: .success(try VerificationPageDataMock.response200.make()))

        await cannotVerifyTask.value
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

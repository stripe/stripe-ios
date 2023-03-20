//
//  VerificationSheetControllerTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 10/27/21.
//

import XCTest
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils
@testable import StripeIdentity

@available(iOS 13, *)
final class VerificationSheetControllerTest: XCTestCase {

    let mockVerificationSessionId = "vs_123"
    let mockEphemeralKeySecret = "sk_test_123"

    private var mockFlowController: VerificationSheetFlowControllerMock!
    private var controller: VerificationSheetController!
    private var mockAPIClient: IdentityAPIClientTestMock!
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
        identityAnalyticsClient = .init(verificationSessionId: "", analyticsClient: mockAnalyticsClient)
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
        XCTAssertEqual(try? mockFlowController.transitionedWithStaticContentResult?.get(), mockResponse)
    }

    func testSaveDataValidResponse() throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        let mockResponse = try VerificationPageDataMock.response200.make()
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
                    face: false,
                    idDocumentBack: true,
                    idDocumentFront: true,
                    idDocumentType: true
                ),
                collectedData: mockData
            )
        )

        // Respond to request with success
        mockAPIClient.verificationPageData.respondToRequests(with: .success(mockResponse))

        // Verify completion block is called
        wait(for: [exp], timeout: 1)

        // Verify value cached locally
        XCTAssertEqual(controller.collectedData.biometricConsent, true)

        // Verify response sent to flowController
        wait(for: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
        XCTAssertEqual(try? mockFlowController.transitionedWithUpdateDataResult?.get(), mockResponse)
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

    func testSaveDocumentFileDataSuccess() throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        let mockCombinedFileData = VerificationPageDataUpdateMock.default.collectedData.map { (front: $0.idDocumentFront!, back: $0.idDocumentBack!) }!
        let mockResponse = try VerificationPageDataMock.response200.make()
        let mockDocumentUploader = DocumentUploaderMock()

        let saveRequestExp = expectation(description: "Save data request was made")
        mockAPIClient.verificationPageData.callBackOnRequest {
            saveRequestExp.fulfill()
        }

        controller.saveDocumentFileDataAndTransition(
            from: .biometricConsent,
            documentUploader: mockDocumentUploader
        ) {
            self.exp.fulfill()
        }

        // Verify analytics client updated
        XCTAssertEqual(identityAnalyticsClient.timeToScreenFromScreen, .biometricConsent)

        // Mock that document upload succeeded
        mockDocumentUploader.frontBackUploadPromise.resolve(with: mockCombinedFileData)

        // Verify save data request was made
        wait(for: [saveRequestExp], timeout: 1)
        XCTAssertEqual(mockAPIClient.verificationPageData.requestHistory.count, 1)
        XCTAssertEqual(mockAPIClient.verificationPageData.requestHistory.first?.collectedData?.idDocumentFront, mockCombinedFileData.front)
        XCTAssertEqual(mockAPIClient.verificationPageData.requestHistory.first?.collectedData?.idDocumentBack, mockCombinedFileData.back)

        // Respond to request with success
        mockAPIClient.verificationPageData.respondToRequests(with: .success(mockResponse))

        // Verify completion block is called
        wait(for: [exp], timeout: 1)

        // Verify values cached locally
        XCTAssertEqual(controller.collectedData.idDocumentFront, mockCombinedFileData.front)
        XCTAssertEqual(controller.collectedData.idDocumentBack, mockCombinedFileData.back)

        // Verify response sent to flowController
        wait(for: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
        XCTAssertEqual(try? mockFlowController.transitionedWithUpdateDataResult?.get(), mockResponse)
    }

    func testSaveDocumentFileDataError() throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        let mockError = NSError(domain: "", code: 0, userInfo: nil)
        let mockDocumentUploader = DocumentUploaderMock()

        controller.saveDocumentFileDataAndTransition(
            from: .biometricConsent,
            documentUploader: mockDocumentUploader
        ) {
            self.exp.fulfill()
        }
        // Mock that document upload failed
        mockDocumentUploader.frontBackUploadPromise.reject(with: mockError)

        // Verify values cached locally
        XCTAssertEqual(controller.collectedData.idDocumentFront, nil)
        XCTAssertEqual(controller.collectedData.idDocumentBack, nil)

        // Verify save data request was not made
        XCTAssertEqual(mockAPIClient.verificationPageData.requestHistory.count, 0)

        // Verify completion block is called
        wait(for: [exp], timeout: 1)

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

        let mockDataResponse = try VerificationPageDataMock.response200.make()
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
        mockAPIClient.verificationSessionSubmit.respondToRequests(with: .success(mockSubmitResponse))

        // Verify completion block is called
        wait(for: [exp], timeout: 1)

        // Verify value cached locally
        XCTAssertEqual(controller.collectedData, mockData)

        // Verify submitted
        XCTAssertEqual(controller.isVerificationPageSubmitted, true)

        // Verify succeed analytic
        XCTAssertEqual(mockAnalyticsClient.loggedAnalyticsPayloads.count, 1)
        let analytic = mockAnalyticsClient.loggedAnalyticsPayloads.first
        XCTAssert(analytic: analytic, hasProperty: "event_name", withValue: "verification_succeeded")
        XCTAssert(analytic: analytic, hasMetadata: "doc_front_model_score", withValue: Float(1))
        XCTAssert(analytic: analytic, hasMetadata: "doc_back_model_score", withValue: Float(1))
        XCTAssert(analytic: analytic, hasMetadata: "selfie_model_score", withValue: Float(0.9))
        XCTAssert(analytic: analytic, hasMetadata: "doc_front_retry_times", withValue: 0)
        XCTAssert(analytic: analytic, hasMetadata: "doc_back_retry_times", withValue: 1)
        XCTAssert(analytic: analytic, hasMetadata: "selfie_retry_times", withValue: 0)

        // Verify response sent to flowController
        wait(for: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
        XCTAssertEqual(try? mockFlowController.transitionedWithUpdateDataResult?.get(), mockSubmitResponse)
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

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
        controller = VerificationSheetController(
            apiClient: mockAPIClient,
            flowController: mockFlowController,
            mlModelLoader: mockMLModelLoader
        )
        controller.delegate = mockDelegate
        exp = XCTestExpectation(description: "Finished API call")
    }

    func testLoadValidResponse() throws {
        let mockResponse = try VerificationPageMock.response200.make()

        // Load
        controller.load() {
            self.exp.fulfill()
        }

        // Verify 1 request made with secret
        XCTAssertEqual(mockAPIClient.verificationPage.requestHistory.count, 1)

        // Verify response & error are nil until API responds to request
        XCTAssertNil(controller.apiContent.staticContent)
        XCTAssertNil(controller.apiContent.lastError)

        // Respond to request with success
        mockAPIClient.verificationPage.respondToRequests(with: .success(mockResponse))

        // Verify completion block is called
        wait(for: [exp], timeout: 1)

        // Verify response updated on controller
        XCTAssertEqual(controller.apiContent.staticContent, mockResponse)
        XCTAssertNil(controller.apiContent.lastError)
        XCTAssertTrue(mockMLModelLoader.didStartLoadingDocumentModels)
    }

    func testLoadErrorResponse() throws {
        let mockError = NSError(domain: "", code: 0, userInfo: nil)

        // Load
        controller.load() {
            self.exp.fulfill()
        }

        // Respond to request with error
        mockAPIClient.verificationPage.respondToRequests(with: .failure(mockError))

        // Verify completion block is called
        wait(for: [exp], timeout: 1)

        // Verify error updated on controller
        XCTAssertNil(controller.apiContent.staticContent)
        XCTAssertNotNil(controller.apiContent.lastError)
    }

    func testSaveDataValidResponse() throws {
        let mockResponse = try VerificationPageDataMock.response200.make()
        let mockData = VerificationPageCollectedData(biometricConsent: true)
        mockFlowController.uncollectedFields = [.idDocumentType, .idDocumentFront, .idDocumentBack]

        // Save data
        controller.saveAndTransition(collectedData: mockData) {
            self.exp.fulfill()
        }

        // Verify 1 request made with Id, EAK, and collected data
        XCTAssertEqual(mockAPIClient.verificationPageData.requestHistory.count, 1)
        XCTAssertEqual(
            mockAPIClient.verificationPageData.requestHistory.first,
            .init(
                clearData: .init(
                    biometricConsent: false,
                    idDocumentBack: true,
                    idDocumentFront: true,
                    idDocumentType: true,
                    _additionalParametersStorage: nil
                ),
                collectedData: mockData,
                _additionalParametersStorage: nil
            )
        )

        // Verify response & error are nil until API responds to request
        XCTAssertNil(controller.apiContent.sessionData)
        XCTAssertNil(controller.apiContent.lastError)

        // Respond to request with success
        mockAPIClient.verificationPageData.respondToRequests(with: .success(mockResponse))

        // Verify completion block is called
        wait(for: [exp], timeout: 1)

        // Verify value cached locally
        XCTAssertEqual(controller.collectedData.consent?.biometric, true)

        // Verify response updated on controller
        XCTAssertEqual(controller.apiContent.sessionData, mockResponse)
        XCTAssertNil(controller.apiContent.lastError)
    }

    func testSaveDataErrorResponse() throws {
        let mockError = NSError(domain: "", code: 0, userInfo: nil)
        let mockData = VerificationPageCollectedData(biometricConsent: true)

        // Save data
        controller.saveAndTransition(collectedData: mockData) {
            self.exp.fulfill()
        }

        // Respond to request with failure
        mockAPIClient.verificationPageData.respondToRequests(with: .failure(mockError))

        // Verify completion block is called
        wait(for: [exp], timeout: 1)

        // Verify value not cached locally
        XCTAssertNil(controller.collectedData.consent?.biometric)

        // Verify response updated on controller
        XCTAssertNil(controller.apiContent.sessionData)
        XCTAssertNotNil(controller.apiContent.lastError)
    }

    func testSaveDocumentFileDataSuccess() throws {
        let mockCombinedFileData = VerificationPageDataUpdateMock.default.collectedData!.idDocument.map { (front: $0.front!, back: $0.back!) }!
        let mockResponse = try VerificationPageDataMock.response200.make()
        let mockDocumentUploader = DocumentUploaderMock()

        let saveRequestExp = expectation(description: "Save data request was made")
        mockAPIClient.verificationPageData.callBackOnRequest {
            saveRequestExp.fulfill()
        }

        controller.saveDocumentFileDataAndTransition(
            documentUploader: mockDocumentUploader
        ) {
            self.exp.fulfill()
        }

        // Mock that document upload succeeded
        mockDocumentUploader.frontBackUploadPromise.resolve(with: mockCombinedFileData)

        // Verify save data request was made
        wait(for: [saveRequestExp], timeout: 1)
        XCTAssertEqual(mockAPIClient.verificationPageData.requestHistory.count, 1)
        XCTAssertEqual(mockAPIClient.verificationPageData.requestHistory.first?.collectedData?.idDocument?.front, mockCombinedFileData.front)
        XCTAssertEqual(mockAPIClient.verificationPageData.requestHistory.first?.collectedData?.idDocument?.back, mockCombinedFileData.back)

        // Respond to request
        mockAPIClient.verificationPageData.respondToRequests(with: .success(mockResponse))

        // Verify completion block is called
        wait(for: [exp], timeout: 1)

        // Verify values cached locally
        XCTAssertEqual(controller.collectedData.idDocument?.front, mockCombinedFileData.front)
        XCTAssertEqual(controller.collectedData.idDocument?.back, mockCombinedFileData.back)

        // Verify APIContent updated with response
        XCTAssertEqual(controller.apiContent.sessionData, mockResponse)
        XCTAssertNil(controller.apiContent.lastError)
    }

    func testSaveDocumentFileDataError() throws {
        let mockError = NSError(domain: "", code: 0, userInfo: nil)
        let mockDocumentUploader = DocumentUploaderMock()

        controller.saveDocumentFileDataAndTransition(
            documentUploader: mockDocumentUploader
        ) {
            self.exp.fulfill()
        }
        // Mock that document upload failed
        mockDocumentUploader.frontBackUploadPromise.reject(with: mockError)

        // Verify values cached locally
        XCTAssertEqual(controller.collectedData.idDocument?.front, nil)
        XCTAssertEqual(controller.collectedData.idDocument?.back, nil)

        // Verify save data request was not made
        XCTAssertEqual(mockAPIClient.verificationPageData.requestHistory.count, 0)

        // Verify completion block is called
        wait(for: [exp], timeout: 1)

        // Verify response updated on controller
        XCTAssertNil(controller.apiContent.sessionData)
        XCTAssertNotNil(controller.apiContent.lastError)
    }

    func testSubmitValidResponse() throws {
        let mockResponse = try VerificationPageDataMock.response200.make()

        // Submit
        controller.submit { mutatedApiContent in
            XCTAssertEqual(mutatedApiContent.sessionData, mockResponse)
            XCTAssertNil(mutatedApiContent.lastError)
            self.exp.fulfill()
        }

        // Verify 1 request made with Id, EAK, and collected data
        XCTAssertEqual(mockAPIClient.verificationSessionSubmit.requestHistory.count, 1)

        // Verify response & error are nil until API responds to request
        XCTAssertNil(controller.apiContent.sessionData)
        XCTAssertNil(controller.apiContent.lastError)

        // Respond to request with success
        mockAPIClient.verificationSessionSubmit.respondToRequests(with: .success(mockResponse))

        // Verify completion block is called
        wait(for: [exp], timeout: 1)

        // Verify response updated on controller
        XCTAssertEqual(controller.apiContent.sessionData, mockResponse)
        XCTAssertNil(controller.apiContent.lastError)
    }

    func testSubmitErrorResponse() throws {
        let mockError = NSError(domain: "", code: 0, userInfo: nil)

        // Submit
        controller.submit { mutatedApiContent in
            XCTAssertNil(mutatedApiContent.sessionData)
            XCTAssertNotNil(mutatedApiContent.lastError)
            self.exp.fulfill()
        }

        // Respond to request with failure
        mockAPIClient.verificationSessionSubmit.respondToRequests(with: .failure(mockError))

        // Verify completion block is called
        wait(for: [exp], timeout: 1)

        // Verify response updated on controller
        XCTAssertNil(controller.apiContent.sessionData)
        XCTAssertNotNil(controller.apiContent.lastError)
    }

    func testDismissResultNoAPIContent() {
        controller.verificationSheetFlowControllerDidDismiss(mockFlowController)
        XCTAssertEqual(mockDelegate.result, .flowCanceled)
    }

    func testDismissResultNotSubmitted() throws {
        controller.apiContent = .init(
            staticContent: try VerificationPageMock.response200.make(),
            sessionData: try VerificationPageDataMock.response200.make(),
            lastError: nil
        )
        controller.verificationSheetFlowControllerDidDismiss(mockFlowController)
        XCTAssertEqual(mockDelegate.result, .flowCanceled)
    }

    func testDismissResultAPIError() throws {
        controller.apiContent = .init(
            staticContent: try VerificationPageMock.response200.make(),
            sessionData: try VerificationPageDataMock.response200.make(),
            lastError: NSError(domain: "", code: 0, userInfo: nil)
        )
        controller.verificationSheetFlowControllerDidDismiss(mockFlowController)
        XCTAssertEqual(mockDelegate.result, .flowCanceled)
    }

    func testDismissResultSubmitted() throws {
        controller.apiContent = .init(
            staticContent: try VerificationPageMock.response200.make(),
            sessionData: try VerificationPageDataMock.response200.makeWithModifications(submitted: true),
            lastError: nil
        )
        controller.verificationSheetFlowControllerDidDismiss(mockFlowController)
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

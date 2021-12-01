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

final class VerificationSheetControllerTest: XCTestCase {

    let mockVerificationSessionId = "vs_123"
    let mockEphemeralKeySecret = "sk_test_123"

    let mockFlowController = VerificationSheetFlowControllerMock()
    private var controller: VerificationSheetController!
    private var mockAPIClient: IdentityAPIClientTestMock!
    private var mockDelegate: MockDelegate!
    private var exp: XCTestExpectation!

    override func setUp() {
        super.setUp()

        // Mock the api client
        mockAPIClient = IdentityAPIClientTestMock()
        mockDelegate = MockDelegate()
        controller = VerificationSheetController(
            verificationSessionId: mockVerificationSessionId,
            ephemeralKeySecret: mockEphemeralKeySecret,
            apiClient: mockAPIClient
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
        XCTAssertEqual(mockAPIClient.verificationPage.requestHistory.first?.id, mockVerificationSessionId)
        XCTAssertEqual(mockAPIClient.verificationPage.requestHistory.first?.ephemeralKey, mockEphemeralKeySecret)

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
        let mockResponse = try VerificationSessionDataMock.response200.make()
        setUpForSaveData()

        // Save data
        controller.saveData { mutatedApiContent in
            XCTAssertEqual(mutatedApiContent.sessionData, mockResponse)
            XCTAssertNil(mutatedApiContent.lastError)
            self.exp.fulfill()
        }

        // Verify 1 request made with Id, EAK, and collected data
        XCTAssertEqual(mockAPIClient.verificationSessionData.requestHistory.count, 1)
        XCTAssertEqual(mockAPIClient.verificationSessionData.requestHistory.first?.id, mockVerificationSessionId)
        XCTAssertEqual(mockAPIClient.verificationSessionData.requestHistory.first?.ephemeralKey, mockEphemeralKeySecret)
        XCTAssertEqual(mockAPIClient.verificationSessionData.requestHistory.first?.data, controller.dataStore.toAPIModel)

        // Verify response & error are nil until API responds to request
        XCTAssertNil(controller.apiContent.sessionData)
        XCTAssertNil(controller.apiContent.lastError)

        // Respond to request with success
        mockAPIClient.verificationSessionData.respondToRequests(with: .success(mockResponse))

        // Verify completion block is called
        wait(for: [exp], timeout: 1)

        // Verify response updated on controller
        XCTAssertEqual(controller.apiContent.sessionData, mockResponse)
        XCTAssertNil(controller.apiContent.lastError)
    }

    func testSaveDataErrorResponse() throws {
        let mockError = NSError(domain: "", code: 0, userInfo: nil)
        setUpForSaveData()

        // Save data
        controller.saveData { mutatedApiContent in
            XCTAssertNil(mutatedApiContent.sessionData)
            XCTAssertNotNil(mutatedApiContent.lastError)
            self.exp.fulfill()
        }

        // Respond to request with failure
        mockAPIClient.verificationSessionData.respondToRequests(with: .failure(mockError))

        // Verify completion block is called
        wait(for: [exp], timeout: 1)

        // Verify response updated on controller
        XCTAssertNil(controller.apiContent.sessionData)
        XCTAssertNotNil(controller.apiContent.lastError)
    }

    func testUploadDocument() throws {
        let mockImage = UIImage()
        let mockResponse = try FileMock.identityDocument.make()

        let uploadPromise = controller.uploadDocument(image: mockImage)

        uploadPromise.observe { [weak self] result in
            switch result {
            case .success(let response):
                XCTAssertEqual(response, mockResponse.id)
            case .failure(let error):
                XCTFail("Expected success but instead found error \(error)")
            }
            self?.exp.fulfill()
        }

        // Verify API request is made
        XCTAssertEqual(mockAPIClient.imageUpload.requestHistory.count, 1)
        XCTAssertEqual(mockAPIClient.imageUpload.requestHistory.first?.image, mockImage)
        XCTAssertEqual(mockAPIClient.imageUpload.requestHistory.first?.purpose, .identityDocument)

        // Respond to request with success
        mockAPIClient.imageUpload.respondToRequests(with: .success(mockResponse))

        // Verify completion block is called
        wait(for: [exp], timeout: 1)
    }

    func testSubmitValidResponse() throws {
        let mockResponse = try VerificationSessionDataMock.response200.make()
        setUpForSaveData()

        // Save data
        controller.submit { mutatedApiContent in
            XCTAssertEqual(mutatedApiContent.sessionData, mockResponse)
            XCTAssertNil(mutatedApiContent.lastError)
            self.exp.fulfill()
        }

        // Verify 1 request made with Id, EAK, and collected data
        XCTAssertEqual(mockAPIClient.verificationSessionSubmit.requestHistory.count, 1)
        XCTAssertEqual(mockAPIClient.verificationSessionSubmit.requestHistory.first?.id, mockVerificationSessionId)
        XCTAssertEqual(mockAPIClient.verificationSessionSubmit.requestHistory.first?.ephemeralKey, mockEphemeralKeySecret)

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
        setUpForSaveData()

        // Save data
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
            sessionData: try VerificationSessionDataMock.response200.make(),
            lastError: nil
        )
        controller.verificationSheetFlowControllerDidDismiss(mockFlowController)
        XCTAssertEqual(mockDelegate.result, .flowCanceled)
    }

    func testDismissResultAPIError() throws {
        controller.apiContent = .init(
            staticContent: try VerificationPageMock.response200.make(),
            sessionData: try VerificationSessionDataMock.response200.make(),
            lastError: NSError(domain: "", code: 0, userInfo: nil)
        )
        controller.verificationSheetFlowControllerDidDismiss(mockFlowController)
        XCTAssertEqual(mockDelegate.result, .flowCanceled)
    }

    func testDismissResultSubmitted() throws {
        controller.apiContent = .init(
            staticContent: try VerificationPageMock.response200.make(),
            sessionData: try VerificationSessionDataMock.response200.makeWithModifications(submitted: true),
            lastError: nil
        )
        controller.verificationSheetFlowControllerDidDismiss(mockFlowController)
        XCTAssertEqual(mockDelegate.result, .flowCompleted)
    }

    func testAPIClientBetaHeader() {
        // Tests that the API client instantiated in the default initializer
        // sets up the API version
        let controller = VerificationSheetController(
            verificationSessionId: "",
            ephemeralKeySecret: ""
        )
        guard let apiClient = controller.apiClient as? STPAPIClient else {
            return XCTFail("Expected `STPAPIClient`")
        }
        XCTAssertEqual(apiClient.betas, ["identity_client_api=v1"])
    }
}

private extension VerificationSheetControllerTest {
    func setUpForSaveData() {
        // Mock that the user has entered data
        controller.dataStore.biometricConsent = true
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

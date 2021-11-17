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

    let mockSecret = "secret_123"
    static var mockStaticContent: VerificationPage!

    private var controller: VerificationSheetController!
    private var mockAPIClient: IdentityAPIClientTestMock!
    private var exp: XCTestExpectation!

    override class func setUp() {
        super.setUp()
        guard let mockStaticContent = try? VerificationPageMock.response200.make() else {
            return XCTFail("Could not load mock data")
        }
        self.mockStaticContent = mockStaticContent
    }

    override func setUp() {
        super.setUp()

        // Mock the api client
        mockAPIClient = IdentityAPIClientTestMock()
        controller = VerificationSheetController(apiClient: mockAPIClient)
        exp = expectation(description: "Finished API call")
    }

    func testLoadValidResponse() throws {
        let mockResponse = try VerificationPageMock.response200.make()

        // Load
        controller.load(clientSecret: mockSecret) {
            self.exp.fulfill()
        }

        // Verify 1 request made with secret
        XCTAssertEqual(mockAPIClient.verificationPage.requestHistory.count, 1)
        XCTAssertEqual(mockAPIClient.verificationPage.requestHistory.first, mockSecret)

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
        controller.load(clientSecret: mockSecret) {
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
        XCTAssertEqual(mockAPIClient.verificationSessionData.requestHistory.first?.id, VerificationSheetControllerTest.mockStaticContent.id)
        XCTAssertEqual(mockAPIClient.verificationSessionData.requestHistory.first?.ephemeralKey, VerificationSheetControllerTest.mockStaticContent.ephemeralApiKey)
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
}

private extension VerificationSheetControllerTest {
    func setUpForSaveData() {
        // Mock that a VerificationPage response has already been received
        controller.apiContent.setStaticContent(result: .success(VerificationSheetControllerTest.mockStaticContent))

        // Mock that the user has entered data
        controller.dataStore.biometricConsent = true
    }
}

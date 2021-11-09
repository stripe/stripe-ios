//
//  VerificationSheetControllerTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 10/27/21.
//

import XCTest
@testable import StripeIdentity

final class VerificationSheetControllerTest: XCTestCase {

    let mockSecret = "secret_123"
    let mockStaticContent = try! VerificationPageMock.response200.make()

    private var controller: VerificationSheetController!
    private var mockAPIClient: IdentityAPIClientTestMock!
    private var exp: XCTestExpectation!

    override func setUp() {
        super.setUp()

        // Mock the api client
        mockAPIClient = IdentityAPIClientTestMock()
        controller = VerificationSheetController(apiClient: mockAPIClient)
        exp = expectation(description: "Finished API call")
    }

    func testValidVerificationPageResponse() throws {
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

    func testErrorVerificationPageResponse() throws {
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

    func testValidVerificationSessionDataResponse() throws {
        let mockResponse = try VerificationSessionDataMock.response200.make()

        // Mock that a VerificationPage response has already been received
        controller.apiContent.setStaticContent(result: .success(mockStaticContent))

        // Mock that the user has entered data
        controller.dataStore.biometricConsent = true

        // Save data
        controller.saveData { mutatedApiContent in
            XCTAssertEqual(mutatedApiContent.sessionData, mockResponse)
            XCTAssertNil(mutatedApiContent.lastError)
            self.exp.fulfill()
        }

        // Verify 1 request made with Id, EAK, and collected data
        XCTAssertEqual(mockAPIClient.verificationSessionData.requestHistory.count, 1)
        XCTAssertEqual(mockAPIClient.verificationSessionData.requestHistory.first?.id, mockStaticContent.id)
        XCTAssertEqual(mockAPIClient.verificationSessionData.requestHistory.first?.ephemeralKey, mockStaticContent.ephemeralApiKey)
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

    func testErrorVerificationSessionDataResponse() throws {
        let mockError = NSError(domain: "", code: 0, userInfo: nil)

        // Mock that a VerificationPage response has already been received
        controller.apiContent.setStaticContent(result: .success(mockStaticContent))

        // Mock that the user has entered data
        controller.dataStore.biometricConsent = true

        // Save data
        controller.saveData { mutatedApiContent in
            XCTAssertNil(mutatedApiContent.sessionData)
            XCTAssertNotNil(mutatedApiContent.lastError)
            self.exp.fulfill()
        }

        // Respond to request with success
        mockAPIClient.verificationSessionData.respondToRequests(with: .failure(mockError))

        // Verify completion block is called
        wait(for: [exp], timeout: 1)

        // Verify response updated on controller
        XCTAssertNil(controller.apiContent.sessionData)
        XCTAssertNotNil(controller.apiContent.lastError)
    }
}

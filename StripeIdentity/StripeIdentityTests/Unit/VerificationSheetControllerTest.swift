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

    private var controller: VerificationSheetController!
    private var mockAPIClient: IdentityAPIClientTestMock!
    private var loadedExp: XCTestExpectation!

    override func setUp() {
        super.setUp()

        // Mock the api client
        mockAPIClient = IdentityAPIClientTestMock()
        controller = VerificationSheetController(apiClient: mockAPIClient)
        loadedExp = expectation(description: "Controller finished loading")
    }

    func testValidResponse() throws {
        let mockResponse = try VerificationPageMock.response200.make()

        // Load
        controller.load(clientSecret: mockSecret) {
            self.loadedExp.fulfill()
        }

        // Verify 1 request made with secret
        XCTAssertEqual(mockAPIClient.verificationPage.requestHistory.count, 1)
        XCTAssertEqual(mockAPIClient.verificationPage.requestHistory.first, mockSecret)

        // Verify response & error are nil until API responds to request
        XCTAssertNil(controller.verificationPage)
        XCTAssertNil(controller.lastError)

        // Respond to request with success
        mockAPIClient.verificationPage.respondToRequests(with: .success(mockResponse))

        // Verify completion block is called
        wait(for: [loadedExp], timeout: 1)

        // Verify response updated on controller
        XCTAssertEqual(controller.verificationPage, mockResponse)
        XCTAssertNil(controller.lastError)
    }

    func testErrorResponse() throws {
        let mockError = NSError(domain: "", code: 0, userInfo: nil)

        // Load
        controller.load(clientSecret: mockSecret) {
            self.loadedExp.fulfill()
        }

        // Respond to request with error
        mockAPIClient.verificationPage.respondToRequests(with: .failure(mockError))

        // Verify completion block is called
        wait(for: [loadedExp], timeout: 1)

        // Verify error updated on controller
        XCTAssertNil(controller.verificationPage)
        XCTAssertNotNil(controller.lastError)
    }
}

//
//  VerificationSheetControllerTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 10/27/21.
//

import XCTest
import OHHTTPStubs
import StripeCoreTestUtils
@_spi(STP) @testable import StripeCore
@_spi(STP) @testable import StripeUICore
@testable import StripeIdentity

final class VerificationSheetControllerTest: APIStubbedTestCase {

    let mockSecret = "secret_123"

    private var controller: VerificationSheetController!
    private var loadedExp: XCTestExpectation!

    override func setUp() {
        super.setUp()

        // Mock the api client
        controller = VerificationSheetController(apiClient: stubbedAPIClient())

        loadedExp = expectation(description: "Controller finished loading")
    }

    func testValidResponse() throws {
        let mock = VerificationPageMock.response200

        stubVerificationPage(.success(try mock.data()), statusCode: 200, expectedSecret: mockSecret)

        controller.load(clientSecret: mockSecret) {
            self.loadedExp.fulfill()
        }

        wait(for: [loadedExp], timeout: 1)

        XCTAssertEqual(controller.verificationPage, try mock.make())
        XCTAssertNil(controller.lastError)
    }

    func testErrorResponse() throws {
        let mockError = NSError(domain: "", code: 0, userInfo: nil)

        stubVerificationPage(.failure(mockError), statusCode: 200, expectedSecret: mockSecret)

        controller.load(clientSecret: mockSecret) {
            self.loadedExp.fulfill()
        }

        wait(for: [loadedExp], timeout: 1)

        XCTAssertNil(controller.verificationPage)
        XCTAssertNotNil(controller.lastError)
    }
}

private extension VerificationSheetControllerTest {
    @discardableResult
    func stubVerificationPage(_ result: Result<Data, Error>, statusCode: Int32, expectedSecret: String) -> HTTPStubsDescriptor {
        return stub { urlRequest in
            guard (urlRequest.url?.absoluteString.hasSuffix("v1/identity/verification_pages") == true)
                    && urlRequest.httpMethod == "POST" else {
                return false
            }

            guard let httpBody = urlRequest.ohhttpStubs_httpBody else {
                XCTFail("Expected an httpBody but found none")
                return false
            }

            XCTAssertEqual(String(data: httpBody, encoding: .utf8), "client_secret=\(expectedSecret)")

            return true
        } response: { _ in
            switch result {
            case .success(let data):
                return HTTPStubsResponse(data: data, statusCode: statusCode, headers: nil)
            case .failure(let error):
                return HTTPStubsResponse(error: error)
            }
        }
    }
}

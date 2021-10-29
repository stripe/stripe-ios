//
//  STPAPIClient+IdentityTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 10/27/21.
//

import XCTest
import OHHTTPStubs
@_spi(STP) import StripeCore
import StripeCoreTestUtils
@testable import StripeIdentity

final class STPAPIClient_IdentityTest: APIStubbedTestCase {

    func testVerificationPageRequest() throws {
        let mockSecret = "secret"

        let mockVerificationPage = VerificationPageMock.response200
        let mockResponseData = try mockVerificationPage.data()
        let mockResponse = try mockVerificationPage.make()

        let exp = expectation(description: "Request completed")

        stub { urlRequest in
            XCTAssertEqual(urlRequest.url?.absoluteString.hasSuffix("v1/identity/verification_pages"), true)
            XCTAssertEqual(urlRequest.httpMethod, "POST")

            guard let httpBody = urlRequest.ohhttpStubs_httpBody else {
                XCTFail("Expected an httpBody but found none")
                return false
            }

            XCTAssertEqual(String(data: httpBody, encoding: .utf8), "client_secret=\(mockSecret)")

            return true
        } response: { urlRequest in
            return HTTPStubsResponse(data: mockResponseData, statusCode: 200, headers: nil)
        }

        let apiClient = stubbedAPIClient()
        let promise = apiClient.postIdentityVerificationPage(clientSecret: "secret")
        promise.observe { result in
            switch result {
            case .success(let response):
                XCTAssertEqual(response, mockResponse)
            case .failure(let error):
                XCTFail("Request returned error \(error)")
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)
    }
}

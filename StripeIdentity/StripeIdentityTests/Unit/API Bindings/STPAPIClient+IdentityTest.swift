//
//  STPAPIClient+IdentityTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 10/27/21.
//

import XCTest
import OHHTTPStubs
@testable @_spi(STP) import StripeCore
import StripeCoreTestUtils
@testable import StripeIdentity

final class STPAPIClient_IdentityTest: APIStubbedTestCase {

    func testCreateVerificationPage() throws {
        let mockId = "VS_123"
        let mockEAK = "ephemeral_key_secret"

        let mockVerificationPage = VerificationPageMock.response200
        let mockResponseData = try mockVerificationPage.data()
        let mockResponse = try mockVerificationPage.make()

        let exp = expectation(description: "Request completed")

        stub { urlRequest in
            XCTAssertEqual(urlRequest.url?.absoluteString.hasSuffix("v1/identity/verification_pages/\(mockId)?"), true)
            XCTAssertEqual(urlRequest.httpMethod, "GET")
            XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Authorization"], "Bearer \(mockEAK)")

            return true
        } response: { urlRequest in
            return HTTPStubsResponse(data: mockResponseData, statusCode: 200, headers: nil)
        }

        let apiClient = stubbedAPIClient()
        let promise = apiClient.getIdentityVerificationPage(
            id: mockId,
            ephemeralKeySecret: mockEAK
        )
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

    func testUpdateVerificationPageData() throws {
        let mockId = "VS_123"
        let mockEAK = "ephemeral_key_secret"
        let mockVerificationData = VerificationPageDataUpdateMock.default
        let encodedMockVerificationData = URLEncoder.queryString(from: try mockVerificationData.encodeJSONDictionary())

        let mockVerificationPageData = VerificationPageDataMock.response200
        let mockResponseData = try mockVerificationPageData.data()
        let mockResponse = try mockVerificationPageData.make()

        let exp = expectation(description: "Request completed")

        stub { urlRequest in
            XCTAssertEqual(urlRequest.url?.absoluteString.hasSuffix("v1/identity/verification_pages/\(mockId)/data"), true)
            XCTAssertEqual(urlRequest.httpMethod, "POST")

            XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Authorization"], "Bearer \(mockEAK)")

            guard let httpBody = urlRequest.ohhttpStubs_httpBody else {
                XCTFail("Expected an httpBody but found none")
                return false
            }
            XCTAssertEqual(String(data: httpBody, encoding: .utf8), encodedMockVerificationData)
            return true
        } response: { urlRequest in
            return HTTPStubsResponse(data: mockResponseData, statusCode: 200, headers: nil)
        }

        let apiClient = stubbedAPIClient()
        let promise = apiClient.updateIdentityVerificationPageData(
            id: mockId,
            updating: mockVerificationData,
            ephemeralKeySecret: mockEAK
        )
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

    func testSubmitIdentityVerificationSession() throws {
        let mockId = "VS_123"
        let mockEAK = "ephemeral_key_secret"
        let mockVerificationPageData = VerificationPageDataMock.response200
        let mockResponseData = try mockVerificationPageData.data()
        let mockResponse = try mockVerificationPageData.make()

        let exp = expectation(description: "Request completed")

        stub { urlRequest in
            XCTAssertEqual(urlRequest.url?.absoluteString.hasSuffix("v1/identity/verification_pages/\(mockId)/submit"), true)
            XCTAssertEqual(urlRequest.httpMethod, "POST")

            XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Authorization"], "Bearer \(mockEAK)")

            XCTAssertEqual(urlRequest.ohhttpStubs_httpBody?.isEmpty, true)
            return true
        } response: { urlRequest in
            return HTTPStubsResponse(data: mockResponseData, statusCode: 200, headers: nil)
        }

        let apiClient = stubbedAPIClient()
        let promise = apiClient.submitIdentityVerificationPage(
            id: mockId,
            ephemeralKeySecret: mockEAK
        )
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

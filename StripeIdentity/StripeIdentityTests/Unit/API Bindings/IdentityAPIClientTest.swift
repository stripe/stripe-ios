//
//  IdentityAPIClientTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 10/27/21.
//

import XCTest
import OHHTTPStubs
@testable @_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils
@testable import StripeIdentity

final class IdentityAPIClientTest: APIStubbedTestCase {

    static let mockId = "VS_123"
    static let mockEAK = "ephemeral_key_secret"

    private var apiClient: IdentityAPIClientImpl!
    private var exp: XCTestExpectation!

    override func setUp() {
        super.setUp()

        apiClient = .init(
            verificationSessionId: IdentityAPIClientTest.mockId,
            ephemeralKeySecret: IdentityAPIClientTest.mockEAK
        )
        stubClient()

        exp = expectation(description: "Request completed")
    }

    func stubClient() {
        let urlSessionConfig = URLSessionConfiguration.default
        HTTPStubs.setEnabled(true, for: urlSessionConfig)
        apiClient.apiClient.urlSession = URLSession(configuration: urlSessionConfig)
    }

    func testCreateVerificationPage() throws {
        let mockVerificationPage = VerificationPageMock.response200
        let mockResponseData = try mockVerificationPage.data()
        let mockResponse = try mockVerificationPage.make()

        stub { urlRequest in
            XCTAssertEqual(urlRequest.url?.absoluteString.hasSuffix("v1/identity/verification_pages/\(IdentityAPIClientTest.mockId)?"), true)
            XCTAssertEqual(urlRequest.httpMethod, "GET")
            verifyHeaders(urlRequest: urlRequest)

            return true
        } response: { urlRequest in
            return HTTPStubsResponse(data: mockResponseData, statusCode: 200, headers: nil)
        }

        apiClient.getIdentityVerificationPage().observe { result in
            switch result {
            case .success(let response):
                XCTAssertEqual(response, mockResponse)
            case .failure(let error):
                XCTFail("Request returned error \(error)")
            }
            self.exp.fulfill()
        }

        wait(for: [exp], timeout: 1)
    }

    func testUpdateVerificationPageData() throws {
        let mockVerificationData = VerificationPageDataUpdateMock.default
        let encodedMockVerificationData = URLEncoder.queryString(from: try mockVerificationData.encodeJSONDictionary())

        let mockVerificationPageData = VerificationPageDataMock.response200
        let mockResponseData = try mockVerificationPageData.data()
        let mockResponse = try mockVerificationPageData.make()

        stub { urlRequest in
            XCTAssertEqual(urlRequest.url?.absoluteString.hasSuffix("v1/identity/verification_pages/\(IdentityAPIClientTest.mockId)/data"), true)
            XCTAssertEqual(urlRequest.httpMethod, "POST")

            verifyHeaders(urlRequest: urlRequest)

            guard let httpBody = urlRequest.ohhttpStubs_httpBody else {
                XCTFail("Expected an httpBody but found none")
                return false
            }
            XCTAssertEqual(String(data: httpBody, encoding: .utf8), encodedMockVerificationData)
            return true
        } response: { urlRequest in
            return HTTPStubsResponse(data: mockResponseData, statusCode: 200, headers: nil)
        }

        apiClient.updateIdentityVerificationPageData(
            updating: mockVerificationData
        ).observe { result in
            switch result {
            case .success(let response):
                XCTAssertEqual(response, mockResponse)
            case .failure(let error):
                XCTFail("Request returned error \(error)")
            }
            self.exp.fulfill()
        }

        wait(for: [exp], timeout: 1)
    }

    func testSubmitIdentityVerificationSession() throws {
        let mockVerificationPageData = VerificationPageDataMock.response200
        let mockResponseData = try mockVerificationPageData.data()
        let mockResponse = try mockVerificationPageData.make()

        stub { urlRequest in
            XCTAssertEqual(urlRequest.url?.absoluteString.hasSuffix("v1/identity/verification_pages/\(IdentityAPIClientTest.mockId)/submit"), true)
            XCTAssertEqual(urlRequest.httpMethod, "POST")

            verifyHeaders(urlRequest: urlRequest)

            XCTAssertEqual(urlRequest.ohhttpStubs_httpBody?.isEmpty, true)
            return true
        } response: { urlRequest in
            return HTTPStubsResponse(data: mockResponseData, statusCode: 200, headers: nil)
        }

        apiClient.submitIdentityVerificationPage().observe { result in
            switch result {
            case .success(let response):
                XCTAssertEqual(response, mockResponse)
            case .failure(let error):
                XCTFail("Request returned error \(error)")
            }
            self.exp.fulfill()
        }

        wait(for: [exp], timeout: 1)
    }

    func testUploadImage() throws {
        let mockPurpose = "purpose"

        let mockImage = CapturedImageMock.frontDriversLicense.image
        let mockFile = FileMock.identityDocument
        let mockResponseData = try mockFile.data()
        let mockResponse = try mockFile.make()

        stub { urlRequest in
            verifyHeaders(urlRequest: urlRequest)

            guard let httpBody = urlRequest.ohhttpStubs_httpBody else {
                XCTFail("Expected an httpBody but found none")
                return false
            }

            verifyImageUploadOwnedBy(
                IdentityAPIClientTest.mockId,
                purpose: mockPurpose,
                httpBody: httpBody
            )

            return true
        } response: { urlRequest in
            return HTTPStubsResponse(data: mockResponseData, statusCode: 200, headers: nil)
        }


        apiClient.uploadImage(
            mockImage,
            compressionQuality: 0.5,
            purpose: mockPurpose,
            fileName: "filename"
        ).observe { result in
            switch result {
            case .success(let response):
                XCTAssertEqual(response, mockResponse)
            case .failure(let error):
                XCTFail("Request returned error \(error)")
            }
            self.exp.fulfill()
        }

        wait(for: [exp], timeout: 1)
    }
}

private func verifyHeaders(
    urlRequest: URLRequest,
    file: StaticString = #file,
    line: UInt = #line
) {
    XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Authorization"], "Bearer \(IdentityAPIClientTest.mockEAK)", file: file, line: line)
    XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Stripe-Version"], "2020-08-27; identity_client_api=v1", file: file, line: line)
}

private func verifyImageUploadOwnedBy(
    _ ownedBy: String,
    purpose: String,
    httpBody: Data
) {
    // Determine the size of the purpose & owned by portion of the data
    let purposePart = STPMultipartFormDataPart()
    purposePart.name = "purpose"
    purposePart.data = purpose.data(using: .utf8)

    let ownedByPart = STPMultipartFormDataPart()
    ownedByPart.name = "owned_by"
    ownedByPart.data = ownedBy.data(using: .utf8)

    let multiPartData = STPMultipartFormDataEncoder.multipartFormData(
        for: [purposePart, ownedByPart],
        boundary: STPMultipartFormDataEncoder.generateBoundary()
    )

    let size = multiPartData.count

    // Extract the data range from the httpBody matching the expected size of
    // the purpose & ownedBy fields
    let subData = httpBody.subdata(in: .init(NSRange(location: 0, length: size))!)

    guard let subDataString = String(data: subData, encoding: .utf8) else {
        return XCTFail("Could not extract string from data")
    }

    let expectedContainsString = "name=\"owned_by\"\r\n\r\n\(ownedBy)"

    XCTAssertTrue(
        subDataString.contains(expectedContainsString),
        "'\(subDataString)' does not contain \(expectedContainsString)"
    )
}

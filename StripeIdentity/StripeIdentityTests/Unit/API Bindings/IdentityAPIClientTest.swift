//
//  IdentityAPIClientTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 10/27/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import OHHTTPStubs
import OHHTTPStubsSwift
@_spi(STP) import StripeCoreTestUtils
import XCTest

// swift-format-ignore
@testable @_spi(STP) import StripeCore

@testable import StripeIdentity

final class IdentityAPIClientTest: APIStubbedTestCase {

    static let mockId = "VS_123"
    static let mockEAK = "ephemeral_key_secret"

    private var apiClient: IdentityAPIClientImpl!

    override func setUp() {
        super.setUp()

        apiClient = .init(
            verificationSessionId: IdentityAPIClientTest.mockId,
            ephemeralKeySecret: IdentityAPIClientTest.mockEAK
        )
        stubClient()
    }

    func stubClient() {
        let urlSessionConfig = URLSessionConfiguration.default
        HTTPStubs.setEnabled(true, for: urlSessionConfig)
        apiClient.apiClient.urlSession = URLSession(configuration: urlSessionConfig)
    }

    func testCreateVerificationPageWithTypeDoc() async throws {
        try await testVerificationPage(with: VerificationPageMock.response200)
    }

    func testCreateVerificationPageWithTypeDocRequireLifeCapture() async throws {
        try await testVerificationPage(with: VerificationPageMock.requireLiveCapture)
    }

    func testCreateVerificationPageWithTypeDocNoSelfie() async throws {
        try await testVerificationPage(with: VerificationPageMock.noSelfie)
    }

    func testCreateVerificationPageWithTypeDocRequireIdNumber() async throws {
        try await testVerificationPage(with: VerificationPageMock.typeDocumentRequireIdNumber)
    }

    func testCreateVerificationPageWithTypeDocRequireAddress() async throws {
        try await testVerificationPage(with: VerificationPageMock.typeDocumentRequireAddress)
    }

    func testCreateVerificationPageWithTypeDocRequireIdNumberAndAddress() async throws {
        try await testVerificationPage(with: VerificationPageMock.typeDocumentRequireIdNumberAndAddress)
    }

    func testCreateVerificationPageWithTypeIdNumber() async throws {
        try await testVerificationPage(with: VerificationPageMock.typeIdNumber)
    }

    func testCreateVerificationPageWithTypeAddress() async throws {
        try await testVerificationPage(with: VerificationPageMock.typeAddress)
    }

    func testUpdateVerificationPageData() async throws {
        let mockVerificationData = VerificationPageDataUpdateMock.default
        let encodedMockVerificationData = URLEncoder.queryString(
            from: try mockVerificationData.encodeJSONDictionary()
        )

        let mockVerificationPageData = VerificationPageDataMock.response200
        let mockResponseData = try mockVerificationPageData.data()
        let mockResponse = try mockVerificationPageData.make()

        stub { urlRequest in
            XCTAssertEqual(
                urlRequest.url?.absoluteString.hasSuffix(
                    "v1/identity/verification_pages/\(IdentityAPIClientTest.mockId)/data"
                ),
                true
            )
            XCTAssertEqual(urlRequest.httpMethod, "POST")

            verifyHeaders(urlRequest: urlRequest)

            guard let httpBody = urlRequest.ohhttpStubs_httpBody else {
                XCTFail("Expected an httpBody but found none")
                return false
            }
            XCTAssertEqual(String(data: httpBody, encoding: .utf8), encodedMockVerificationData)
            return true
        } response: { _ in
            return HTTPStubsResponse(data: mockResponseData, statusCode: 200, headers: nil)
        }

        let response = try await apiClient.updateIdentityVerificationPageData(
            updating: mockVerificationData
        )

        XCTAssertEqual(response, mockResponse)
    }

    func testSubmitIdentityVerificationSession() async throws {
        try await verifyPostWithSuffix(expectedSuffix: "v1/identity/verification_pages/\(IdentityAPIClientTest.mockId)/submit") {
            try await apiClient.submitIdentityVerificationPage()
        }
    }

    func testGeneratePhoneOtp() async throws {
        try await verifyPostWithSuffix(expectedSuffix: "v1/identity/verification_pages/\(IdentityAPIClientTest.mockId)/phone_otp/generate") {
            try await apiClient.generatePhoneOtp()
        }
    }

    func testCannotPhoneVerifyOtp() async throws {
        try await verifyPostWithSuffix(expectedSuffix: "v1/identity/verification_pages/\(IdentityAPIClientTest.mockId)/phone_otp/cannot_verify") {
            try await apiClient.cannotPhoneVerifyOtp()
        }
    }

    func testUploadImage() async throws {
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
        } response: { _ in
            return HTTPStubsResponse(data: mockResponseData, statusCode: 200, headers: nil)
        }

        let (response, _) = try await apiClient.uploadImage(
            mockImage,
            compressionQuality: 0.5,
            purpose: mockPurpose,
            fileName: "filename"
        )
        XCTAssertEqual(response, mockResponse)
    }

    private func testVerificationPage(with responseMock: VerificationPageMock) async throws {
        let mockVerificationPage = responseMock
        let mockResponseData = try mockVerificationPage.data()
        let mockResponse = try mockVerificationPage.make()

        stub { urlRequest in
            XCTAssertEqual(
                urlRequest.url?.absoluteString.hasSuffix(
                    "v1/identity/verification_pages/\(IdentityAPIClientTest.mockId)?app_identifier=\(Bundle.main.bundleIdentifier ?? "")"
                ),
                true
            )
            XCTAssertEqual(urlRequest.httpMethod, "GET")
            verifyHeaders(urlRequest: urlRequest)

            return true
        } response: { _ in
            return HTTPStubsResponse(data: mockResponseData, statusCode: 200, headers: nil)
        }

        let response = try await apiClient.getIdentityVerificationPage()
        XCTAssertEqual(response, mockResponse)
    }

    private func verifyPostWithSuffix(expectedSuffix: String, apiCall: () async throws -> StripeCore.StripeAPI.VerificationPageData) async throws {
        let mockVerificationPageData = VerificationPageDataMock.response200
        let mockResponseData = try mockVerificationPageData.data()
        let mockResponse = try mockVerificationPageData.make()

        stub { urlRequest in
            XCTAssertEqual(
                urlRequest.url?.absoluteString.hasSuffix(expectedSuffix),
                true
            )
            XCTAssertEqual(urlRequest.httpMethod, "POST")

            verifyHeaders(urlRequest: urlRequest)

            XCTAssertEqual(urlRequest.ohhttpStubs_httpBody?.isEmpty, true)
            return true
        } response: { _ in
            return HTTPStubsResponse(data: mockResponseData, statusCode: 200, headers: nil)
        }

        do {
            let response = try await apiCall()
            XCTAssertEqual(response, mockResponse)
        } catch {
            XCTFail("Request returned error \(error)")
        }
    }
}

private func verifyHeaders(
    urlRequest: URLRequest,
    file: StaticString = #file,
    line: UInt = #line
) {
    XCTAssertEqual(
        urlRequest.allHTTPHeaderFields?["Authorization"],
        "Bearer \(IdentityAPIClientTest.mockEAK)",
        file: file,
        line: line
    )
    XCTAssertEqual(
        urlRequest.allHTTPHeaderFields?["Stripe-Version"],
        "2020-08-27; identity_client_api=v7",
        file: file,
        line: line
    )
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

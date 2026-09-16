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

    func testCreateVerificationPageWithTypeDoc() throws {
        try testVerificationPage(with: VerificationPageMock.response200)
    }

    func testCreateVerificationPageWithTypeDocRequireLifeCapture() throws {
        try testVerificationPage(with: VerificationPageMock.requireLiveCapture)
    }

    func testCreateVerificationPageWithTypeDocNoSelfie() throws {
        try testVerificationPage(with: VerificationPageMock.noSelfie)
    }

    func testCreateVerificationPageWithTypeDocRequireIdNumber() throws {
        try testVerificationPage(with: VerificationPageMock.typeDocumentRequireIdNumber)
    }

    func testCreateVerificationPageWithTypeDocRequireAddress() throws {
        try testVerificationPage(with: VerificationPageMock.typeDocumentRequireAddress)
    }

    func testCreateVerificationPageWithTypeDocRequireIdNumberAndAddress() throws {
        try testVerificationPage(with: VerificationPageMock.typeDocumentRequireIdNumberAndAddress)
    }

    func testCreateVerificationPageWithTypeIdNumber() throws {
        try testVerificationPage(with: VerificationPageMock.typeIdNumber)
    }

    func testCreateVerificationPageWithTypeAddress() throws {
        try testVerificationPage(with: VerificationPageMock.typeAddress)
    }

    func testUpdateVerificationPageData() throws {
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
        try verifyPostWithSuffix(expectedSuffix: "v1/identity/verification_pages/\(IdentityAPIClientTest.mockId)/submit") {
            apiClient.submitIdentityVerificationPage()
        }
    }

    func testGeneratePhoneOtp() throws {
        try verifyPostWithSuffix(expectedSuffix: "v1/identity/verification_pages/\(IdentityAPIClientTest.mockId)/phone_otp/generate") {
            apiClient.generatePhoneOtp()
        }
    }

    func testCannotPhoneVerifyOtp() throws {
        try verifyPostWithSuffix(expectedSuffix: "v1/identity/verification_pages/\(IdentityAPIClientTest.mockId)/phone_otp/cannot_verify") {
            apiClient.cannotPhoneVerifyOtp()
        }
    }

    func testAttachNetworkedIdentityDocument() throws {
        try verifyNetworkedIdentityAction(
            action: "attach_document",
            parameters: ["identity_document_association_token": "reuse_token"]
        ) {
            apiClient.attachNetworkedIdentityDocument(associationToken: "reuse_token")
        }
    }

    func testPrepareNetworkedIdentityDocumentSave() throws {
        try verifyNetworkedIdentityAction(
            action: "prepare_document_save",
            parameters: ["identity_document_save_association_token": "save_token"]
        ) {
            apiClient.prepareNetworkedIdentityDocumentSave(associationToken: "save_token")
        }
    }

    func testSkipNetworkedIdentity() throws {
        try verifyNetworkedIdentityAction(action: "skip", parameters: [:]) {
            apiClient.skipNetworkedIdentity()
        }
    }

    func testNetworkedIdentityActionsRequireExplicitV8OptIn() {
        // Given the unchanged production version
        XCTAssertEqual(apiClient.apiVersion, 7)
        XCTAssertFalse(apiClient.supportsNetworkedIdentity)
        stub { _ in
            XCTFail("A v7 client must not send draft Networked Identity actions")
            return true
        } response: { _ in
            HTTPStubsResponse(data: Data(), statusCode: 500, headers: nil)
        }
        exp.expectedFulfillmentCount = 3

        // When attempting each draft mutation without opting in
        let promises = [
            apiClient.attachNetworkedIdentityDocument(associationToken: "reuse_token"),
            apiClient.prepareNetworkedIdentityDocumentSave(associationToken: "save_token"),
            apiClient.skipNetworkedIdentity(),
        ]
        promises.forEach { promise in
            promise.observe { result in
                // Then it fails locally, without transmitting any token
                guard case .failure(let error) = result else {
                    XCTFail("Expected an unsupported-version error")
                    self.exp.fulfill()
                    return
                }
                guard case IdentityAPIClientError.networkedIdentityRequiresV8 = error else {
                    XCTFail("Unexpected error: \(error)")
                    self.exp.fulfill()
                    return
                }
                self.exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 1)
    }

    func testNetworkedIdentityActionsDoNotRetryRateLimitResponses() {
        verifyNetworkedIdentityActionsDoNotRetry {
            HTTPStubsResponse(data: Data(), statusCode: 429, headers: nil)
        }
    }

    func testNetworkedIdentityActionsDoNotRetryServerErrors() {
        verifyNetworkedIdentityActionsDoNotRetry {
            HTTPStubsResponse(data: Data(), statusCode: 500, headers: nil)
        }
    }

    func testNetworkedIdentityActionsDoNotRetryTransportFailure() {
        verifyNetworkedIdentityActionsDoNotRetry {
            HTTPStubsResponse(error: URLError(.timedOut))
        }
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
        } response: { _ in
            return HTTPStubsResponse(data: mockResponseData, statusCode: 200, headers: nil)
        }

        apiClient.uploadImage(
            mockImage,
            compressionQuality: 0.5,
            purpose: mockPurpose,
            fileName: "filename"
        ).observe { result in
            switch result {
            case .success((let response, _)):
                XCTAssertEqual(response, mockResponse)
            case .failure(let error):
                XCTFail("Request returned error \(error)")
            }
            self.exp.fulfill()
        }

        wait(for: [exp], timeout: 1)
    }

    private func testVerificationPage(with responseMock: VerificationPageMock) throws {
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

    private func verifyNetworkedIdentityAction(
        action: String,
        parameters: [String: String],
        apiCall: () -> Promise<StripeAPI.VerificationPageData>
    ) throws {
        // Given a client explicitly opted into the draft API
        apiClient.apiVersion = 8
        XCTAssertTrue(apiClient.supportsNetworkedIdentity)
        let mock = VerificationPageDataMock.response200
        let responseData = try mock.data()
        let expectedResponse = try mock.make()
        stub { request in
            XCTAssertEqual(
                request.url?.path,
                "/v1/identity/verification_pages/\(Self.mockId)/networked_identity/\(action)"
            )
            XCTAssertEqual(request.httpMethod, "POST")
            verifyHeaders(urlRequest: request, apiVersion: 8)
            XCTAssertNil(request.value(forHTTPHeaderField: "Stripe-Account"))
            XCTAssertNil(request.value(forHTTPHeaderField: "X-Stripe-Mock-Request"))
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/x-www-form-urlencoded")
            // Only the capability token is sent to Identity, never Link's raw session credentials.
            XCTAssertEqual(
                request.ohhttpStubs_httpBody.flatMap { String(data: $0, encoding: .utf8) },
                URLEncoder.queryString(from: parameters)
            )
            return true
        } response: { _ in
            HTTPStubsResponse(data: responseData, statusCode: 200, headers: nil)
        }

        // When the mutation succeeds, then the returned verification-page state is decoded
        apiCall().observe { result in
            switch result {
            case .success(let response):
                XCTAssertEqual(response, expectedResponse)
            case .failure(let error):
                XCTFail("Request returned error \(error)")
            }
            self.exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }

    private func verifyNetworkedIdentityActionsDoNotRetry(response: @escaping () -> HTTPStubsResponse) {
        // Given a retryable-looking response to a capability-bearing mutation
        apiClient.apiVersion = 8
        var requestCount = 0
        stub { _ in true } response: { _ in
            requestCount += 1
            return response()
        }
        exp.expectedFulfillmentCount = 3

        // When each mutation fails
        let promises = [
            apiClient.attachNetworkedIdentityDocument(associationToken: "reuse_token"),
            apiClient.prepareNetworkedIdentityDocumentSave(associationToken: "save_token"),
            apiClient.skipNetworkedIdentity(),
        ]
        promises.forEach { promise in
            promise.observe { result in
                guard case .failure = result else {
                    XCTFail("Expected the failed request to be surfaced")
                    self.exp.fulfill()
                    return
                }
                self.exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 1)
        // Then no potentially consumed token or mutation was replayed
        XCTAssertEqual(requestCount, 3)
    }

    private func verifyPostWithSuffix(expectedSuffix: String, apiCall: () -> StripeCore.Promise<StripeCore.StripeAPI.VerificationPageData>) throws {
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

        apiCall().observe { result in
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
    apiVersion: Int = 7,
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
        "2020-08-27; identity_client_api=v\(apiVersion)",
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

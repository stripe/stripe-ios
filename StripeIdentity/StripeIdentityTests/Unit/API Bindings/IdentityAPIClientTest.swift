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

    func testCreateWalletIdentitySession() throws {
        let responseJSON = """
            {
              "session_id": "wis_123",
              "platform": "apple_passkit",
              "request": {
                "nonce": "dGVzdE5vbmNlQWJjZGVmZ2hpamtsbW5vcHE",
                "merchant_identifier": "merchant.com.stripe.identity.test",
                "document_requests": [{
                  "document_type": "driving_license",
                  "requested_elements": [
                    "org.iso.18013.5.1.given_name",
                    "org.iso.18013.5.1.family_name",
                    "org.iso.18013.5.1.portrait",
                    "org.iso.18013.5.1.address",
                    "org.iso.18013.5.1.birth_date",
                    "org.iso.18013.5.1.document_number",
                    "org.iso.18013.5.1.issue_date",
                    "org.iso.18013.5.1.expiry_date",
                    "org.iso.18013.5.1.issuing_authority"
                  ]
                }]
              }
            }
            """
        let mockResponseData = responseJSON.data(using: .utf8)!
        let mockResponse = StripeAPI.VerificationPageWalletIdentitySession(
            sessionId: "wis_123",
            platform: "apple_passkit",
            request: .init(
                nonce: "dGVzdE5vbmNlQWJjZGVmZ2hpamtsbW5vcHE",
                merchantIdentifier: "merchant.com.stripe.identity.test",
                documentRequests: [
                    .init(
                        documentType: "driving_license",
                        requestedElements: [
                            "org.iso.18013.5.1.given_name",
                            "org.iso.18013.5.1.family_name",
                            "org.iso.18013.5.1.portrait",
                            "org.iso.18013.5.1.address",
                            "org.iso.18013.5.1.birth_date",
                            "org.iso.18013.5.1.document_number",
                            "org.iso.18013.5.1.issue_date",
                            "org.iso.18013.5.1.expiry_date",
                            "org.iso.18013.5.1.issuing_authority",
                        ]
                    ),
                ]
            )
        )

        stub { urlRequest in
            XCTAssertEqual(
                urlRequest.url?.absoluteString.hasSuffix(
                    "v1/identity/verification_pages/\(IdentityAPIClientTest.mockId)/wallet_identity/sessions"
                ),
                true
            )
            XCTAssertEqual(urlRequest.httpMethod, "POST")
            verifyHeaders(urlRequest: urlRequest)
            let body = String(data: urlRequest.ohhttpStubs_httpBody ?? Data(), encoding: .utf8)
            XCTAssertEqual(Set(body?.components(separatedBy: "&") ?? []), [
                "app_identifier=\(Bundle.main.bundleIdentifier ?? "")",
                "platform=apple_passkit",
            ])
            return true
        } response: { _ in
            return HTTPStubsResponse(data: mockResponseData, statusCode: 200, headers: nil)
        }

        apiClient.createWalletIdentitySession().observe { result in
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

    func testSubmitWalletIdentitySessionWithCredential() throws {
        try testSubmitWalletIdentitySession(
            outcome: .credentialReturned(encryptedResponse: "-_8"),
            expectedParameters: [
                "outcome": "credential_returned",
                "encrypted_response": "-_8",
            ],
            responseStatus: .validated
        )
    }

    func testSubmitWalletIdentitySessionWithoutCredential() throws {
        try testSubmitWalletIdentitySession(
            outcome: .userDeclined,
            expectedParameters: ["outcome": "user_declined"],
            responseStatus: .userDeclined
        )
    }

    func testSubmitWalletIdentitySessionWithNoDocument() throws {
        try testSubmitWalletIdentitySession(
            outcome: .noDocument,
            expectedParameters: ["outcome": "no_document"],
            responseStatus: .noDocument
        )
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

    private func testSubmitWalletIdentitySession(
        outcome: StripeAPI.VerificationPageWalletIdentitySessionOutcome,
        expectedParameters: [String: String],
        responseStatus: StripeAPI.VerificationPageWalletIdentitySessionSubmission.Status
    ) throws {
        let responseJSON = """
            {
              "session_id": "wis_123",
              "platform": "apple_passkit",
              "status": "\(responseStatus.rawValue)"
            }
            """
        let expectedResponse = StripeAPI.VerificationPageWalletIdentitySessionSubmission(
            sessionId: "wis_123",
            platform: "apple_passkit",
            status: responseStatus
        )

        stub { urlRequest in
            XCTAssertEqual(
                urlRequest.url?.absoluteString.hasSuffix(
                    "v1/identity/verification_pages/\(IdentityAPIClientTest.mockId)/wallet_identity/sessions/wis_123/submit"
                ),
                true
            )
            XCTAssertEqual(urlRequest.httpMethod, "POST")
            verifyHeaders(urlRequest: urlRequest)
            let body = String(data: urlRequest.ohhttpStubs_httpBody ?? Data(), encoding: .utf8)
            XCTAssertEqual(Set(body?.components(separatedBy: "&") ?? []), Set(expectedParameters.map { "\($0.key)=\($0.value)" }))
            return true
        } response: { _ in
            return HTTPStubsResponse(
                data: Data(responseJSON.utf8),
                statusCode: 200,
                headers: nil
            )
        }

        apiClient.submitWalletIdentitySession(id: "wis_123", outcome: outcome).observe { result in
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
        "2020-08-27; identity_client_api=v8",
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

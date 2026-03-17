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

    func testUpdateVerificationPageDataEncodesMetricsToFourDecimalPlaces() throws {
        let mockVerificationData = StripeAPI.VerificationPageDataUpdate(
            clearData: nil,
            collectedData: .init(
                biometricConsent: false,
                face: .init(
                    bestHighResImage: "best_high_res_id",
                    bestLowResImage: "best_low_res_id",
                    firstHighResImage: "first_high_res_id",
                    firstLowResImage: "first_low_res_id",
                    lastHighResImage: "last_high_res_id",
                    lastLowResImage: "last_low_res_id",
                    bestFaceScore: .init(0.12341),
                    faceScoreVariance: .init(0.8090820312499999744),
                    numFrames: 8,
                    bestBrightnessValue: .init(double: 4.266),
                    bestCameraLensModel: nil,
                    bestExposureDuration: nil,
                    bestExposureIso: .init(320.12341),
                    bestFocalLength: .init(double: 33.5),
                    bestIsVirtualCamera: nil,
                    trainingConsent: true
                ),
                idDocumentFront: .init(
                    backScore: .init(0.12341),
                    brightnessValue: .init(double: 1.23456),
                    cameraLensModel: nil,
                    exposureDuration: nil,
                    exposureIso: .init(42.12341),
                    focalLength: .init(double: 28.0),
                    frontCardScore: .init(0.98761),
                    highResImage: "front_user_upload_id",
                    invalidScore: .init(0.10001),
                    iosBarcodeDecoded: nil,
                    iosBarcodeSymbology: nil,
                    iosTimeToFindBarcode: nil,
                    isVirtualCamera: nil,
                    lowResImage: "front_full_frame_id",
                    passportScore: .init(0.54321),
                    uploadMethod: .autoCapture
                )
            )
        )

        let mockVerificationPageData = VerificationPageDataMock.response200
        let mockResponseData = try mockVerificationPageData.data()
        let mockResponse = try mockVerificationPageData.make()

        stub { urlRequest in
            verifyHeaders(urlRequest: urlRequest)

            guard let httpBody = urlRequest.ohhttpStubs_httpBody else {
                XCTFail("Expected an httpBody but found none")
                return false
            }

            guard let httpBodyString = String(data: httpBody, encoding: .utf8) else {
                XCTFail("Could not decode httpBody")
                return false
            }

            XCTAssertQueryString(httpBodyString, containsField: "best_face_score", value: "0.1234")
            XCTAssertQueryString(httpBodyString, containsField: "face_score_variance", value: "0.8091")
            XCTAssertQueryString(httpBodyString, containsField: "best_brightness_value", value: "4.2660")
            XCTAssertQueryString(httpBodyString, containsField: "best_exposure_iso", value: "320.1234")
            XCTAssertQueryString(httpBodyString, containsField: "back_score", value: "0.1234")
            XCTAssertQueryString(httpBodyString, containsField: "brightness_value", value: "1.2346")
            XCTAssertQueryString(httpBodyString, containsField: "exposure_iso", value: "42.1234")
            XCTAssertQueryString(httpBodyString, containsField: "front_card_score", value: "0.9876")
            XCTAssertQueryString(httpBodyString, containsField: "invalid_score", value: "0.1000")
            XCTAssertQueryString(httpBodyString, containsField: "passport_score", value: "0.5432")

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

private func XCTAssertQueryString(
    _ queryString: String,
    containsField fieldName: String,
    value: String,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let pattern = "\(NSRegularExpression.escapedPattern(for: fieldName))[^&]*=\(NSRegularExpression.escapedPattern(for: value))(?=&|$)"
    XCTAssertNotNil(
        queryString.range(of: pattern, options: .regularExpression),
        "'\(queryString)' did not contain \(fieldName)=\(value)",
        file: file,
        line: line
    )
}

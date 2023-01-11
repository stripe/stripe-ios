//
//  STPAPIClient+CardImageVerificationTest.swift
//  StripeCardScanTests
//
//  Created by Jaime Park on 11/16/21.
//

import OHHTTPStubs
import OHHTTPStubsSwift
import StripeCoreTestUtils
import XCTest

@testable import StripeCardScan
@testable@_spi(STP) import StripeCore

class STPAPIClient_CardImageVerificationTest: APIStubbedTestCase {
    /// The following test is mocking a flow where the merchant has set a card during the CIV intent creation.
    /// It will check the following:
    /// 1. The request URL has been constructed properly: /v1/card_image_verifications/:id/initialize_client
    /// 2. The request body contains the client secret
    /// 3. The response from request has details of card set during the CIV intent creation
    func testFetchCardImageVerificationDetails_CardSet() throws {
        let mockResponse =
            try CardImageVerificationDetailsResponseMock.cardImageVerification_cardSet_200.data()

        /// Stub the request to get details of CIV intent
        stub { request in
            guard let httpBody = request.ohhttpStubs_httpBody else {
                XCTFail("Expected an httpBody but found none")
                return false
            }

            XCTAssertNotNil(request.url)
            XCTAssertEqual(
                request.url?.absoluteString.contains(
                    "v1/card_image_verifications/\(CIVIntentMockData.id)/initialize_client"
                ),
                true
            )
            XCTAssertEqual(
                String(data: httpBody, encoding: .utf8),
                "client_secret=\(CIVIntentMockData.clientSecret)"
            )
            XCTAssertEqual(request.httpMethod, "POST")

            return true
        } response: { _ in
            return HTTPStubsResponse(data: mockResponse, statusCode: 200, headers: nil)
        }

        let exp = expectation(description: "Request completed")

        /// Make request to get card details
        let apiClient = stubbedAPIClient()
        let promise = apiClient.fetchCardImageVerificationDetails(
            cardImageVerificationSecret: CIVIntentMockData.clientSecret,
            cardImageVerificationId: CIVIntentMockData.id
        )

        promise.observe { result in
            switch result {
            case .success(let response):
                XCTAssertEqual(response.expectedCard.last4, "4242")
                XCTAssertEqual(response.expectedCard.issuer, "Visa")

                XCTAssertNotNil(response.acceptedImageConfigs)

                XCTAssertEqual(
                    response.acceptedImageConfigs?.preferredFormats,
                    [.heic, .webp, .jpeg]
                )

                XCTAssertEqual(
                    response.acceptedImageConfigs?.defaultSettings?.compressionRatio,
                    0.8
                )
                XCTAssertEqual(
                    response.acceptedImageConfigs?.defaultSettings?.imageSize,
                    [1080.0, 1920.0]
                )

                if let formatSettings = response.acceptedImageConfigs?.formatSettings {
                    let webpSettings = formatSettings[.webp]
                    XCTAssertEqual(webpSettings??.compressionRatio, 0.7)
                    XCTAssertEqual(webpSettings??.imageSize, [2160.0, 1920.0])
                } else {
                    XCTFail("Format Settings failed to parse")
                }
            case .failure(let error):
                XCTFail("Request returned error \(error)")
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)
    }

    /// The following test is mocking a flow where the merchant has not set a card during the CIV intent creation.
    /// It will check the following:
    /// 1. The request URL has been constructed properly: /v1/card_image_verifications/:id/initialize_client
    /// 2. The request body contains the client secret
    /// 3. The response from request is empty
    func testFetchCardImageVerificationDetails_CardAdd() throws {
        let mockResponse =
            try CardImageVerificationDetailsResponseMock.cardImageVerification_cardAdd_200.data()

        /// Stub the request to get details of CIV intent
        stub { request in
            guard let httpBody = request.ohhttpStubs_httpBody else {
                XCTFail("Expected an httpBody but found none")
                return false
            }

            XCTAssertNotNil(request.url)
            XCTAssertEqual(request.httpMethod, "POST")

            if let url = request.url {
                XCTAssertTrue(
                    url.path
                        == "/v1/card_image_verifications/\(CIVIntentMockData.id)/initialize_client"
                        || url.path
                            == "/v1/card_image_verifications/\(CIVIntentMockData.id)/scan_stats"
                )

                let bodyString = String(data: httpBody, encoding: .utf8)!
                XCTAssertTrue(
                    bodyString.hasPrefix("client_secret=\(CIVIntentMockData.clientSecret)")
                )
            }

            return true
        } response: { _ in
            return HTTPStubsResponse(data: mockResponse, statusCode: 200, headers: nil)
        }

        let exp = expectation(description: "Request completed")

        /// Make request to get card details
        let apiClient = stubbedAPIClient()
        let promise = apiClient.fetchCardImageVerificationDetails(
            cardImageVerificationSecret: CIVIntentMockData.clientSecret,
            cardImageVerificationId: CIVIntentMockData.id
        )

        promise.observe { result in
            switch result {
            case .success(let response):
                XCTAssertNil(response.expectedCard.last4)
                XCTAssertNil(response.expectedCard.issuer)
            case .failure(let error):
                XCTFail("Request returned error \(error)")
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)
    }

    /// The following test is mocking a flow where the collected verification frames are submitted to the server
    /// It will check the following:
    /// 1. The request URL has been constructed properly: /v1/card_image_verifications/:id/verify_frames
    /// 2. The request body contains `client_secret` and `verification_frames_data`
    /// 3. The response from request is empty
    func testSubmitVerificationFrames() throws {
        let base64EncodedVerificationFrames = "base64_encoded_list_of_verify_frames"
        let mockResponse = "{}".data(using: .utf8)!
        let mockParameter = VerifyFrames(
            clientSecret: CIVIntentMockData.clientSecret,
            verificationFramesData: base64EncodedVerificationFrames
        )

        /// Stub the request to submit verify frames
        stub { request in
            guard let httpBody = request.ohhttpStubs_httpBody else {
                XCTFail("Expected an httpBody but found none")
                return false
            }

            XCTAssertNotNil(request.url)
            XCTAssertEqual(
                request.url?.absoluteString.contains(
                    "v1/card_image_verifications/\(CIVIntentMockData.id)/verify_frames"
                ),
                true
            )
            XCTAssertEqual(
                String(data: httpBody, encoding: .utf8),
                "client_secret=\(CIVIntentMockData.clientSecret)&verification_frames_data=\(base64EncodedVerificationFrames)"
            )
            XCTAssertEqual(request.httpMethod, "POST")

            return true
        } response: { _ in
            return HTTPStubsResponse(data: mockResponse, statusCode: 200, headers: nil)
        }

        let exp = expectation(description: "Request completed")

        /// Make request to submit verification frames
        let apiClient = stubbedAPIClient()
        let promise = apiClient.submitVerificationFrames(
            cardImageVerificationId: CIVIntentMockData.id,
            verifyFrames: mockParameter
        )

        promise.observe { result in
            switch result {
            /// The successful response is an empty struct
            case .success:
                XCTAssert(true, "A response has been returned")
            case .failure(let error):
                XCTFail("Request returned error \(error)")
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)
    }

    /// The following test is mocking a flow where the collected verification frames are submitted to the server
    /// It will check the following. This test is using the expanded version of  the request `submitVerificationFrames`:
    /// 1. The request URL has been constructed properly: /v1/card_image_verifications/:id/verify_frames
    /// 2. The request body contains `client_secret` and `verification_frames_data`
    /// 3. The response from request is empty
    func testSubmitVerificationFrames_Expanded() throws {
        let verificationFrameData = VerificationFramesData(
            imageData: "image_data".data(using: .utf8)!,
            viewfinderMargins: ViewFinderMargins(left: 0, upper: 0, right: 0, lower: 0)
        )

        let mockResponse = "{}".data(using: .utf8)!

        /// The list of verification frame datas are encoded with snake_case before converting to a `VerifyFrames` object
        let jsonEncoder = JSONEncoder()
        jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
        let jsonVerificationFramesData = try jsonEncoder.encode([verificationFrameData])

        /// Turn the JSON data into a string
        let verificationFramesDataString =
            String(data: jsonVerificationFramesData, encoding: .utf8) ?? ""

        let urlEncodedString = URLEncoder.string(byURLEncoding: verificationFramesDataString)

        // Stub the request to submit verify frames
        stub { request in
            guard let httpBody = request.ohhttpStubs_httpBody else {
                XCTFail("Expected an httpBody but found none")
                return false
            }

            XCTAssertNotNil(request.url)
            XCTAssertEqual(
                request.url?.absoluteString.contains(
                    "v1/card_image_verifications/\(CIVIntentMockData.id)/verify_frames"
                ),
                true
            )
            XCTAssertEqual(
                String(data: httpBody, encoding: .utf8),
                "client_secret=\(CIVIntentMockData.clientSecret)&verification_frames_data=\(urlEncodedString)"
            )
            XCTAssertEqual(request.httpMethod, "POST")

            return true
        } response: { _ in
            return HTTPStubsResponse(data: mockResponse, statusCode: 200, headers: nil)
        }

        let exp = expectation(description: "Request completed")

        /// Make request to submit verification frames
        let apiClient = stubbedAPIClient()
        let promise = apiClient.submitVerificationFrames(
            cardImageVerificationId: CIVIntentMockData.id,
            cardImageVerificationSecret: CIVIntentMockData.clientSecret,
            verificationFramesData: [verificationFrameData]
        )

        promise.observe { result in
            switch result {
            /// The successful response is an empty struct
            case .success:
                XCTAssert(true, "A response has been returned")
            case .failure(let error):
                XCTFail("Request returned error \(error)")
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)
    }

    /// The following test is mocking a flow where the collected scan analytics are uploaded to the server
    /// It will check the following
    /// 1. The request URL has been constructed properly: /v1/card_image_verifications/:id/scan_stats
    /// 2. The response from request is empty
    func testUploadScanStats() throws {
        let startDate = Date()
        let mockResponse = "{}".data(using: .utf8)!
        let payload: ScanAnalyticsPayload = .init(
            configuration: .init(strictModeFrames: 0),
            payloadInfo: .init(
                imageCompressionType: "heic",
                imageCompressionQuality: 0.8,
                imagePayloadSize: 4000
            ),
            scanStats: .init(
                repeatingTasks: .init(
                    mainLoopImagesProcessed: .init(executions: 1)
                ),
                tasks: .init(
                    cameraPermissionTask: .init(event: .success, startTime: startDate),
                    completionLoopDuration: .init(event: .success, startTime: startDate),
                    imageCompressionDuration: .init(event: .success, startTime: startDate),
                    mainLoopDuration: .init(event: .success, startTime: startDate),
                    scanActivityTasks: [
                        .init(event: .torchSupported, startTime: startDate),
                        .init(event: .torchSupported, startTime: startDate),
                    ],
                    torchSupportedTask: .init(event: .torchSupported, startTime: startDate)
                )
            )
        )

        /// Stub the request to upload scan stats
        /// Check request body more closely in a different test
        stub { request in
            /// Check that the http body exists
            guard let httpBody = request.ohhttpStubs_httpBody,
                let httpBodyQueryString = String(data: httpBody, encoding: .utf8)
            else {
                XCTFail("Expected an httpBody but found none")
                return false
            }

            XCTAssertNotNil(request.url)
            XCTAssertEqual(
                request.url?.absoluteString.contains(
                    "v1/card_image_verifications/\(CIVIntentMockData.id)/scan_stats"
                ),
                true
            )
            /// Just check the existence of the parent-level payload fields
            /// In-depth form data checking will be done in separate unit test
            XCTAssertTrue(
                httpBodyQueryString.contains("client_secret=\(CIVIntentMockData.clientSecret)"),
                "http body does not contain client secret"
            )
            XCTAssertTrue(
                httpBodyQueryString.contains("payload["),
                "http body does any payload info"
            )
            XCTAssertEqual(request.httpMethod, "POST")

            return true
        } response: { _ in
            return HTTPStubsResponse(data: mockResponse, statusCode: 200, headers: nil)
        }

        let exp = expectation(description: "Request completed")

        /// Make request to upload scan stats
        let apiClient = stubbedAPIClient()
        let promise = apiClient.uploadScanStats(
            cardImageVerificationId: CIVIntentMockData.id,
            cardImageVerificationSecret: CIVIntentMockData.clientSecret,
            scanAnalyticsPayload: payload
        )

        promise.observe { result in
            switch result {
            /// The successful response is an empty struct
            case .success:
                XCTAssert(true, "A response has been returned")
            case .failure(let error):
                XCTFail("Request returned error \(error)")
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)
    }
}

//
//  STPAPIClient+FileUploadTest.swift
//  StripeCoreTests
//
//  Created by Michael Liberatore on 9/16/26.
//

import OHHTTPStubs
import OHHTTPStubsSwift
@_spi(STP) import StripeCore
import StripeCoreTestUtils
import UIKit
import XCTest

final class STPAPIClient_FileUploadTest: APIStubbedTestCase {
    private typealias FileUploadError = STPAPIClient.FileUploadError

    // The byte value and size are arbitrary; these tests just need consistent binary data.
    private static let testData = Data(repeating: 0xAB, count: 1024)
    private var temporaryDirectoryURL: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        temporaryDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temporaryDirectoryURL, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: temporaryDirectoryURL)
        try super.tearDownWithError()
    }

    func testUploadInfersMIMETypeAndPreservesBytesAndFilename() async throws {
        let bytes = Self.testData
        let apiClient = stubbedAPIClient()
        apiClient.publishableKey = "pk_test_merchant"
        for (fileExtension, mimeType) in [
            ("pdf", "application/pdf"),
            ("jpg", "image/jpeg"),
            ("jpeg", "image/jpeg"),
            ("png", "image/png"),
            ("unknown-upload-format", "application/octet-stream"),
        ] {
            let sourceFileURL = temporaryDirectoryURL.appendingPathComponent("name% •\"\\\r\n.\(fileExtension)")
            try bytes.write(to: sourceFileURL)
            let stubDescriptor = stub(condition: { $0.url?.host == "uploads.stripe.com" }) { request in
                XCTAssertEqual(request.url?.path, "/v1/files")
                XCTAssertEqual(request.httpMethod, "POST")
                XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer lsk_test")
                let boundary = request.value(forHTTPHeaderField: "Content-Type")?.components(separatedBy: "boundary=").last ?? ""
                var expectedRequestBody = Data(("--\(boundary)\r\nContent-Disposition: form-data; name=\"purpose\"\r\n\r\ncrypto_onramp_kyc_document\r\n"
                    + "--\(boundary)\r\nContent-Disposition: form-data; name=\"file\"; filename=\"name% %E2%80%A2%22%5C%0D%0A.\(fileExtension)\"\r\n"
                    + "Content-Type: \(mimeType)\r\n\r\n").utf8)
                expectedRequestBody.append(bytes)
                expectedRequestBody.append(Data("\r\n--\(boundary)--\r\n".utf8))
                XCTAssertEqual(request.httpBodyOrBodyStream ?? request.ohhttpStubs_httpBody, expectedRequestBody)
                return self.makeSuccessResponse()
            }

            let file = try await apiClient.uploadFile(at: sourceFileURL, purpose: StripeFile.Purpose.cryptoOnrampKYCDocument.rawValue, authorizationSecret: "lsk_test")

            XCTAssertEqual(file.id, "file_test")
            XCTAssertEqual(file.purpose, .cryptoOnrampKYCDocument)
            XCTAssertEqual(try Data(contentsOf: sourceFileURL), bytes)
            HTTPStubs.removeStub(stubDescriptor)
        }
    }

    func testEmptyCredentialDoesNotSendRequest() async throws {
        let apiClient = stubbedAPIClient()
        do {
            _ = try await apiClient.uploadFile(at: temporaryDirectoryURL.appendingPathComponent("missing.pdf"), purpose: StripeFile.Purpose.cryptoOnrampKYCDocument.rawValue, authorizationSecret: "")
            XCTFail("Expected an authentication error")
        } catch FileUploadError.missingAuthorizationSecret {
            // Expected.
        }
    }

    func testNonFileURLIsRejected() async throws {
        do {
            _ = try await stubbedAPIClient().uploadFile(at: URL(string: "https://example.com/document.pdf")!, purpose: StripeFile.Purpose.cryptoOnrampKYCDocument.rawValue, authorizationSecret: "lsk_test")
            XCTFail("Expected a local file URL error")
        } catch FileUploadError.invalidFileURL {
            // Expected.
        }
    }

    func testFileReadFailurePreservesUnderlyingError() async throws {
        do {
            _ = try await stubbedAPIClient().uploadFile(at: temporaryDirectoryURL.appendingPathComponent("missing.pdf"), purpose: StripeFile.Purpose.cryptoOnrampKYCDocument.rawValue, authorizationSecret: "lsk_test")
            XCTFail("Expected a file read error")
        } catch FileUploadError.fileReadFailed(let underlyingError) {
            XCTAssertEqual((underlyingError as? CocoaError)?.code, .fileReadNoSuchFile)
        }
    }

    func testAlreadyCanceledTaskDoesNotReadFile() async throws {
        let apiClient = stubbedAPIClient()
        let sourceFileURL = temporaryDirectoryURL.appendingPathComponent("missing.pdf")
        let uploadTask = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await apiClient.uploadFile(at: sourceFileURL, purpose: StripeFile.Purpose.cryptoOnrampKYCDocument.rawValue, authorizationSecret: "lsk_test")
        }
        do {
            _ = try await uploadTask.value
            XCTFail("Expected cancellation before reading the missing file")
        } catch FileUploadError.cancelled {
            // Expected.
        }
    }

    func testNetworkFailurePreservesUnderlyingError() async throws {
        let sourceFileURL = temporaryDirectoryURL.appendingPathComponent("document.pdf")
        try Self.testData.write(to: sourceFileURL)
        var attempts = 0
        stub(condition: { $0.url?.host == "uploads.stripe.com" }) { _ in
            attempts += 1
            return HTTPStubsResponse(error: URLError(.notConnectedToInternet) as NSError)
        }
        do {
            _ = try await stubbedAPIClient().uploadFile(at: sourceFileURL, purpose: StripeFile.Purpose.cryptoOnrampKYCDocument.rawValue, authorizationSecret: "lsk_test")
            XCTFail("Expected a network error")
        } catch FileUploadError.networkFailed(let underlyingError) {
            XCTAssertEqual((underlyingError as? URLError)?.code, .notConnectedToInternet)
        }
        XCTAssertEqual(attempts, 1)
    }

    func testServerFailureIsDecoded() async throws {
        let sourceFileURL = temporaryDirectoryURL.appendingPathComponent("document.png")
        try Self.testData.write(to: sourceFileURL)
        var attempts = 0
        stub(condition: { $0.url?.host == "uploads.stripe.com" }) { _ in
            attempts += 1
            return HTTPStubsResponse(jsonObject: ["error": ["type": "invalid_request_error", "message": "Upload not accepted", "code": "file_upload_invalid"]], statusCode: 400, headers: ["Content-Type": "application/json", "Request-Id": "req_test_upload"])
        }
        do {
            _ = try await stubbedAPIClient().uploadFile(at: sourceFileURL, purpose: StripeFile.Purpose.cryptoOnrampKYCDocument.rawValue, authorizationSecret: "lsk_test")
            XCTFail("Expected an upload error")
        } catch FileUploadError.apiError(let apiError) {
            XCTAssertEqual(apiError.type, .invalidRequestError)
            XCTAssertEqual(apiError.code, "file_upload_invalid")
            XCTAssertEqual(apiError.message, "Upload not accepted")
            XCTAssertEqual(apiError.httpStatusCode, 400)
            XCTAssertEqual(apiError.requestID, "req_test_upload")
        }
        XCTAssertEqual(attempts, 1)
    }

    func testInvalidResponsePreservesStatusAndUnderlyingError() async throws {
        let sourceFileURL = temporaryDirectoryURL.appendingPathComponent("document.pdf")
        try Self.testData.write(to: sourceFileURL)
        for statusCode in [200, 500] {
            let stubDescriptor = stub(condition: { $0.url?.host == "uploads.stripe.com" }) { _ in
                HTTPStubsResponse(data: Data("invalid JSON".utf8), statusCode: Int32(statusCode), headers: ["Content-Type": "application/json"])
            }
            do {
                _ = try await stubbedAPIClient().uploadFile(at: sourceFileURL, purpose: StripeFile.Purpose.cryptoOnrampKYCDocument.rawValue, authorizationSecret: "lsk_test")
                XCTFail("Expected an invalid response error")
            } catch FileUploadError.invalidResponse(let actualStatusCode, let underlyingError) {
                XCTAssertEqual(actualStatusCode, statusCode)
                if statusCode == 200 {
                    XCTAssertTrue(underlyingError is DecodingError)
                } else {
                    XCTAssertEqual((underlyingError as NSError).domain, STPError.stripeDomain)
                    XCTAssertEqual((underlyingError as NSError).code, STPErrorCode.apiError.rawValue)
                }
            }
            HTTPStubs.removeStub(stubDescriptor)
        }
    }

    func testFileAndImageUploadsRetryRateLimitedRequests() async throws {
        let originalMaxRetries = StripeAPI.maxRetries
        StripeAPI.maxRetries = 1
        defer { StripeAPI.maxRetries = originalMaxRetries }
        let sourceFileURL = temporaryDirectoryURL.appendingPathComponent("document.pdf")
        try Self.testData.write(to: sourceFileURL)
        let apiClient = stubbedAPIClient()
        for uploadImage in [false, true] {
            var attempts = 0
            var requestBodies: [Data?] = []
            let stubDescriptor = stub(condition: { $0.url?.path == "/v1/files" }) { request in
                attempts += 1
                requestBodies.append(request.httpBodyOrBodyStream ?? request.ohhttpStubs_httpBody)
                return attempts == 1 ? self.makeRateLimitResponse() : self.makeSuccessResponse()
            }

            let file: StripeFile
            if uploadImage {
                let image = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { _ in }
                file = try await withCheckedThrowingContinuation { continuation in
                    apiClient.uploadImage(image, purpose: "crypto_onramp_kyc_document", ephemeralKeySecret: "lsk_test") {
                        continuation.resume(with: $0)
                    }
                }
            } else {
                file = try await apiClient.uploadFile(at: sourceFileURL, purpose: StripeFile.Purpose.cryptoOnrampKYCDocument.rawValue, authorizationSecret: "lsk_test")
            }

            XCTAssertEqual(file.id, "file_test")
            XCTAssertEqual(file.purpose, .cryptoOnrampKYCDocument)
            XCTAssertEqual(attempts, 2)
            XCTAssertNotNil(requestBodies.first.flatMap { $0 })
            XCTAssertEqual(requestBodies.first, requestBodies.last)
            HTTPStubs.removeStub(stubDescriptor)
        }
    }

    func testUploadHonorsRetryLimit() async throws {
        let originalMaxRetries = StripeAPI.maxRetries
        defer { StripeAPI.maxRetries = originalMaxRetries }
        let sourceFileURL = temporaryDirectoryURL.appendingPathComponent("document.pdf")
        try Self.testData.write(to: sourceFileURL)
        for retries in [0, 1] {
            StripeAPI.maxRetries = retries
            var attempts = 0
            let stubDescriptor = stub(condition: { $0.url?.host == "uploads.stripe.com" }) { _ in
                attempts += 1
                return self.makeRateLimitResponse()
            }
            do {
                _ = try await stubbedAPIClient().uploadFile(at: sourceFileURL, purpose: StripeFile.Purpose.cryptoOnrampKYCDocument.rawValue, authorizationSecret: "lsk_test")
                XCTFail("Expected the rate limit to fail after retries are exhausted")
            } catch FileUploadError.apiError(let apiError) {
                XCTAssertEqual(apiError.httpStatusCode, 429)
            }
            XCTAssertEqual(attempts, retries + 1)
            HTTPStubs.removeStub(stubDescriptor)
        }
    }

    func testCancelingUploadPreservesSourceFile() async throws {
        let sourceFileURL = temporaryDirectoryURL.appendingPathComponent("document.pdf")
        try Self.testData.write(to: sourceFileURL)
        let requested = expectation(description: "Upload reached the server")
        stub(condition: { $0.url?.host == "uploads.stripe.com" }) { _ in
            requested.fulfill()
            let response = HTTPStubsResponse(jsonObject: [:], statusCode: 200, headers: nil)
            response.responseTime = 10
            return response
        }
        let apiClient = stubbedAPIClient()
        let uploadTask = Task {
            try await apiClient.uploadFile(at: sourceFileURL, purpose: StripeFile.Purpose.cryptoOnrampKYCDocument.rawValue, authorizationSecret: "lsk_test")
        }
        await fulfillment(of: [requested], timeout: 2)

        uploadTask.cancel()
        do {
            _ = try await uploadTask.value
            XCTFail("Expected cancellation")
        } catch FileUploadError.cancelled {
            // Expected.
        }

        XCTAssertTrue(FileManager.default.fileExists(atPath: sourceFileURL.path))
    }

    func testCancellationStopsRetries() async throws {
        let originalMaxRetries = StripeAPI.maxRetries
        StripeAPI.maxRetries = 1
        defer { StripeAPI.maxRetries = originalMaxRetries }
        let sourceFileURL = temporaryDirectoryURL.appendingPathComponent("document.pdf")
        try Self.testData.write(to: sourceFileURL)
        let requested = expectation(description: "Initial request")
        let retried = expectation(description: "Canceled upload is not retried")
        retried.isInverted = true
        var attempts = 0
        stub(condition: { $0.url?.host == "uploads.stripe.com" }) { _ in
            attempts += 1
            (attempts == 1 ? requested : retried).fulfill()
            return self.makeRateLimitResponse()
        }
        let apiClient = stubbedAPIClient()
        let uploadTask = Task {
            try await apiClient.uploadFile(at: sourceFileURL, purpose: StripeFile.Purpose.cryptoOnrampKYCDocument.rawValue, authorizationSecret: "lsk_test")
        }
        await fulfillment(of: [requested], timeout: 2)
        // Allow the immediate 429 response to start the backoff, which lasts at least one second.
        try await Task.sleep(nanoseconds: 100_000_000)
        uploadTask.cancel()
        do {
            _ = try await uploadTask.value
            XCTFail("Expected cancellation during backoff")
        } catch FileUploadError.cancelled {
            // Expected.
        }
        await fulfillment(of: [retried], timeout: 1.6)
    }

    private func makeSuccessResponse() -> HTTPStubsResponse {
        HTTPStubsResponse(jsonObject: ["id": "file_test", "created": 1_700_000_000, "purpose": "crypto_onramp_kyc_document", "size": 16, "type": "pdf"], statusCode: 200, headers: ["Content-Type": "application/json"])
    }

    private func makeRateLimitResponse() -> HTTPStubsResponse {
        HTTPStubsResponse(jsonObject: ["error": ["type": "api_error", "message": "Rate limited"]], statusCode: 429, headers: ["Content-Type": "application/json"])
    }
}

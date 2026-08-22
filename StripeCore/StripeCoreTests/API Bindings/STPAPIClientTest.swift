//
//  STPAPIClientTest.swift
//  StripeCoreTests
//
//  Created by Yuki Tokuhiro on 8/22/26.
//

import Foundation
import OHHTTPStubs
import OHHTTPStubsSwift
@testable @_spi(STP) import StripeCore
import StripeCoreTestUtils
import XCTest

final class STPAPIClientTest: APIStubbedTestCase {
    func testGetAppliesTimeoutAndRetryCount() {
        // Given a 429 response and a default retry count greater than zero
        let originalMaxRetries = StripeAPI.maxRetries
        StripeAPI.maxRetries = 1
        defer { StripeAPI.maxRetries = originalMaxRetries }

        let recorder = RequestRecorder()
        stub(condition: { _ in true }) { request in
            recorder.record(request)
            return HTTPStubsResponse(
                jsonObject: [
                    "error": [
                        "type": "api_error",
                        "message": "Rate limited",
                    ],
                ],
                statusCode: 429,
                headers: nil
            )
        }

        let completion = expectation(description: "Request completed")
        let apiClient = stubbedAPIClient()
        let expectedTimeout: TimeInterval = 0.25

        // When GET is called with a custom timeout and no retries
        apiClient.get(
            resource: "test",
            parameters: [:],
            timeout: expectedTimeout,
            retryCount: 0
        ) { (result: Result<EmptyResponse, Error>) in
            guard case .failure = result else {
                XCTFail("Expected the 429 response to fail")
                completion.fulfill()
                return
            }
            completion.fulfill()
        }

        wait(for: [completion], timeout: 5)

        // Then the timeout is applied and the 429 is not retried
        XCTAssertEqual(recorder.requestCount, 1)
        XCTAssertEqual(recorder.timeoutInterval, expectedTimeout, accuracy: 0.001)
    }
}

private final class RequestRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var requests: [URLRequest] = []

    var requestCount: Int {
        lock.withLock { requests.count }
    }

    var timeoutInterval: TimeInterval {
        lock.withLock { requests.last?.timeoutInterval ?? 0 }
    }

    func record(_ request: URLRequest) {
        lock.withLock { requests.append(request) }
    }
}

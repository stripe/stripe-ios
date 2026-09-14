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
    func testGetAppliesTimeoutAndDisablesRetries() {
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
            retriesEnabled: false
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

    func testGetUsesAdditionalHeaders() {
        let apiClient = stubbedAPIClient()
        apiClient.publishableKey = "pk_test_headers"

        let headers = [
            "Stripe-Consumer-Auth-Token": "cscs_test",
            "Stripe-Version": "test_version",
        ]

        stub(condition: { _ in true }) { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Stripe-Consumer-Auth-Token"), "cscs_test")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Stripe-Version"), "test_version")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer pk_test_headers")
            XCTAssertEqual(request.url?.query, "key=value")
            return HTTPStubsResponse(jsonObject: [:], statusCode: 200, headers: nil)
        }

        let completion = expectation(description: "All GET overloads completed")
        completion.expectedFulfillmentCount = 3

        let handler: (Result<EmptyResponse, Error>) -> Void = { result in
            if case .failure(let error) = result {
                XCTFail("Unexpected request failure: \(error)")
            }
            completion.fulfill()
        }

        apiClient.get(
            resource: "test",
            parameters: ["key": "value"],
            additionalHeaders: headers,
            completion: handler
        )

        apiClient.get(
            url: apiClient.apiURL.appendingPathComponent("test"),
            parameters: ["declaration_type": "terms"],
            additionalHeaders: headers,
            completion: handler
        )

        let promise: Promise<EmptyResponse> = apiClient.get(
            resource: "test",
            parameters: ["declaration_type": "terms"],
            additionalHeaders: headers
        )

        promise.observe(using: handler)
        wait(for: [completion], timeout: 5)
    }

    func testPostUsesAdditionalHeaders() {
        let apiClient = stubbedAPIClient()
        apiClient.publishableKey = "pk_test_headers"

        let headers = [
            "Stripe-Consumer-Auth-Token": "cscs_test",
            "Stripe-Version": "test_version",
        ]

        stub(condition: { _ in true }) { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Stripe-Consumer-Auth-Token"), "cscs_test")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Stripe-Version"), "test_version")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer pk_test_headers")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/x-www-form-urlencoded")
            let body = request.ohhttpStubs_httpBody ?? Data()
            XCTAssertEqual(String(data: body, encoding: .utf8), "key=value")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Length"), String(body.count))
            return HTTPStubsResponse(jsonObject: [:], statusCode: 200, headers: nil)
        }

        let completion = expectation(description: "All POST overloads completed")
        completion.expectedFulfillmentCount = 5
        let handler: (Result<EmptyResponse, Error>) -> Void = { result in
            if case .failure(let error) = result {
                XCTFail("Unexpected request failure: \(error)")
            }
            completion.fulfill()
        }

        let parameters = ["key": "value"]
        apiClient.post(resource: "test", parameters: parameters, additionalHeaders: headers, completion: handler)

        let parametersPromise: Promise<EmptyResponse> = apiClient.post(
            resource: "test",
            parameters: parameters,
            additionalHeaders: headers
        )

        parametersPromise.observe(using: handler)
        apiClient.post(resource: "test", object: parameters, additionalHeaders: headers, completion: handler)

        apiClient.post(
            url: apiClient.apiURL.appendingPathComponent("test"),
            object: parameters,
            additionalHeaders: headers,
            completion: handler
        )

        let objectPromise: Promise<EmptyResponse> = apiClient.post(
            resource: "test",
            object: parameters,
            additionalHeaders: headers
        )

        objectPromise.observe(using: handler)
        wait(for: [completion], timeout: 5)
    }

    func testDeleteUsesAdditionalHeaders() {
        let apiClient = stubbedAPIClient()
        apiClient.publishableKey = "pk_test_headers"

        stub(condition: { _ in true }) { request in
            XCTAssertEqual(request.httpMethod, "DELETE")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Stripe-Consumer-Auth-Token"), "cscs_test")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Stripe-Version"), "test_version")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer pk_test_headers")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/x-www-form-urlencoded")
            let body = request.ohhttpStubs_httpBody ?? Data()
            XCTAssertEqual(String(data: body, encoding: .utf8), "key=value")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Length"), String(body.count))
            return HTTPStubsResponse(jsonObject: [:], statusCode: 200, headers: nil)
        }

        let completion = expectation(description: "DELETE completed")

        apiClient.delete(
            resource: "test",
            parameters: ["wallet_id": "wallet_test"],
            additionalHeaders: [
                "Stripe-Consumer-Auth-Token": "cscs_test",
                "Stripe-Version": "test_version",
            ]
        ) { (result: Result<EmptyResponse, Error>) in
            if case .failure(let error) = result {
                XCTFail("Unexpected request failure: \(error)")
            }
            completion.fulfill()
        }

        wait(for: [completion], timeout: 5)
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

//
//  NetworkedIdentityAPIClientTest.swift
//  StripeIdentityTests
//

import OHHTTPStubs
import OHHTTPStubsSwift
@_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils
@testable import StripeIdentity
import XCTest

final class NetworkedIdentityAPIClientTest: APIStubbedTestCase {
    private static let merchantPublishableKey = "pk_test_merchant"
    private static let consumerPublishableKey = "pk_test_consumer"
    private static let requestSurface = "web_identity_product"
    private static let consumerSessionClientSecret = "css_123"

    private var backingAPIClient: STPAPIClient!
    private var apiClient: NetworkedIdentityAPIClientImpl!

    override func setUp() {
        super.setUp()
        backingAPIClient = STPAPIClient(publishableKey: Self.merchantPublishableKey)
        let configuration = URLSessionConfiguration.default
        HTTPStubs.setEnabled(true, for: configuration)
        backingAPIClient.urlSession = URLSession(configuration: configuration)
        apiClient = makeAPIClient()
    }

    func testListIdentityDocumentsRetriesOneServerError() {
        var requestCount = 0
        var retryDelay: TimeInterval?
        apiClient = makeAPIClient { delay, action in
            retryDelay = delay
            action()
        }
        stubRequest(
            path: "/v1/consumers/identity_documents/list",
            authorizationKey: Self.consumerPublishableKey,
            expectedParameters: consumerParameters(),
            response: { _ in
                requestCount += 1
                if requestCount == 1 {
                    return HTTPStubsResponse(data: Data(), statusCode: 500, headers: nil)
                }
                return HTTPStubsResponse(
                    data: Data(
                        """
                        {
                          "data": [
                            {
                              "id": "id_doc_123",
                              "document_type": "driving_license",
                              "created": 1700000000,
                              "country": "US",
                              "region": "NY",
                              "redacted_document_number": "******1234",
                              "expiration_date": 1800000000,
                              "live_captured": true
                            },
                            {
                              "id": "id_doc_future",
                              "document_type": "future_document_type",
                              "created": 1700000001
                            }
                          ]
                        }
                        """.utf8
                    ),
                    statusCode: 200,
                    headers: nil
                )
            }
        )

        assertSuccess(
            apiClient.listIdentityDocuments(
                consumerSessionClientSecret: Self.consumerSessionClientSecret,
                consumerPublishableKey: Self.consumerPublishableKey
            )
        ) { response in
            XCTAssertEqual(requestCount, 2)
            XCTAssertEqual(retryDelay, 0.25)
            XCTAssertEqual(response.data.first?.documentType, .drivingLicense)
            XCTAssertEqual(response.data.first?.expirationDate, 1_800_000_000)
            XCTAssertEqual(response.data.last?.documentType, .unparsable)
        }
    }

    func testListIdentityDocumentsStopsAfterTwoServerErrors() {
        var requestCount = 0
        var retryDelays: [TimeInterval] = []
        apiClient = makeAPIClient { delay, action in
            retryDelays.append(delay)
            action()
        }
        stubRequest(
            path: "/v1/consumers/identity_documents/list",
            authorizationKey: Self.consumerPublishableKey,
            expectedParameters: consumerParameters(),
            response: { _ in
                requestCount += 1
                return HTTPStubsResponse(
                    data: Data(
                        """
                        {
                          "error": {
                            "type": "api_error",
                            "code": "server_error",
                            "message": "Server error"
                          }
                        }
                        """.utf8
                    ),
                    statusCode: 500,
                    headers: nil
                )
            }
        )

        assertFailure(
            apiClient.listIdentityDocuments(
                consumerSessionClientSecret: Self.consumerSessionClientSecret,
                consumerPublishableKey: Self.consumerPublishableKey
            )
        ) { _ in
            XCTAssertEqual(requestCount, 2)
            XCTAssertEqual(retryDelays, [0.25])
        }
    }

    func testListIdentityDocumentsDoesNotRetryClientError() {
        var requestCount = 0
        var didScheduleRetry = false
        apiClient = makeAPIClient { _, action in
            didScheduleRetry = true
            action()
        }
        stubRequest(
            path: "/v1/consumers/identity_documents/list",
            authorizationKey: Self.consumerPublishableKey,
            expectedParameters: consumerParameters(),
            response: { _ in
                requestCount += 1
                return HTTPStubsResponse(
                    data: Data(
                        """
                        {
                          "error": {
                            "type": "invalid_request_error",
                            "code": "invalid_request",
                            "message": "Invalid request"
                          }
                        }
                        """.utf8
                    ),
                    statusCode: 400,
                    headers: nil
                )
            }
        )

        assertFailure(
            apiClient.listIdentityDocuments(
                consumerSessionClientSecret: Self.consumerSessionClientSecret,
                consumerPublishableKey: Self.consumerPublishableKey
            )
        ) { _ in
            XCTAssertEqual(requestCount, 1)
            XCTAssertFalse(didScheduleRetry)
        }
    }

    func testCreateAssociationTokenIsBoundToTheTargetSession() {
        stubRequest(
            path: "/v1/consumers/identity_documents/id_doc_123/association_token",
            authorizationKey: Self.consumerPublishableKey,
            expectedParameters: consumerParameters(
                additionalParameters: ["verification_session": "vs_target"]
            ),
            responseJSON: """
                { "association_token": "assoc_123" }
                """
        )

        assertSuccess(
            apiClient.createAssociationToken(
                identityDocumentID: "id_doc_123",
                verificationSessionID: "vs_target",
                consumerSessionClientSecret: Self.consumerSessionClientSecret,
                consumerPublishableKey: Self.consumerPublishableKey
            )
        ) { response in
            XCTAssertEqual(response.associationToken, "assoc_123")
        }
    }

    func testCreateSaveAssociationTokenUsesConsumerAuthorizationAndTargetSession() {
        stubRequest(
            path: "/v1/consumers/identity_documents/save_association_token",
            authorizationKey: Self.consumerPublishableKey,
            expectedParameters: consumerParameters(
                additionalParameters: ["verification_session": "vs_target"]
            )
        ) { request in
            XCTAssertNil(request.value(forHTTPHeaderField: "X-Stripe-Mock-Request"))
            return HTTPStubsResponse(
                data: Data("{\"association_token\":\"save_token\"}".utf8),
                statusCode: 200,
                headers: nil
            )
        }

        // When creating a save token, separate from a saved-document reuse token
        assertSuccess(
            apiClient.createSaveAssociationToken(
                verificationSessionID: "vs_target",
                consumerSessionClientSecret: Self.consumerSessionClientSecret,
                consumerPublishableKey: Self.consumerPublishableKey
            )
        ) { response in
            XCTAssertEqual(response.associationToken, "save_token")
        }
    }

    func testCreateSaveAssociationTokenDoesNotRetry() {
        apiClient = makeAPIClient { _, _ in
            XCTFail("Save token creation must not schedule a retry")
        }
        for statusCode in [Int32(429), Int32(500)] {
            var requestCount = 0
            stubRequest(
                path: "/v1/consumers/identity_documents/save_association_token",
                authorizationKey: Self.consumerPublishableKey,
                expectedParameters: consumerParameters(
                    additionalParameters: ["verification_session": "vs_target"]
                )
            ) { _ in
                requestCount += 1
                return HTTPStubsResponse(data: Data(), statusCode: statusCode, headers: nil)
            }

            assertFailure(
                apiClient.createSaveAssociationToken(
                    verificationSessionID: "vs_target",
                    consumerSessionClientSecret: Self.consumerSessionClientSecret,
                    consumerPublishableKey: Self.consumerPublishableKey
                )
            ) { _ in
                XCTAssertEqual(requestCount, 1)
            }
        }
    }

    func testCreateSaveAssociationTokenDoesNotRetryTransportFailure() {
        // Given a timed-out mint request whose server outcome is unknown
        apiClient = makeAPIClient { _, _ in
            XCTFail("Save token creation must not schedule a retry")
        }
        var requestCount = 0
        stubRequest(
            path: "/v1/consumers/identity_documents/save_association_token",
            authorizationKey: Self.consumerPublishableKey,
            expectedParameters: consumerParameters(
                additionalParameters: ["verification_session": "vs_target"]
            )
        ) { _ in
            requestCount += 1
            return HTTPStubsResponse(error: URLError(.timedOut))
        }

        // When minting fails, then return the failure without an automatic replay
        assertFailure(
            apiClient.createSaveAssociationToken(
                verificationSessionID: "vs_target",
                consumerSessionClientSecret: Self.consumerSessionClientSecret,
                consumerPublishableKey: Self.consumerPublishableKey
            )
        ) { error in
            XCTAssertEqual((error as NSError).code, NSURLErrorTimedOut)
            XCTAssertEqual(requestCount, 1)
        }
    }

    private func makeAPIClient(
        retryScheduler: @escaping NetworkedIdentityAPIClientImpl.RetryScheduler = { delay, action in
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + delay) {
                action()
            }
        }
    ) -> NetworkedIdentityAPIClientImpl {
        return NetworkedIdentityAPIClientImpl(
            apiClient: backingAPIClient,
            retryScheduler: retryScheduler
        )
    }

    private func consumerParameters(
        additionalParameters: [String: Any] = [:]
    ) -> [String: Any] {
        var parameters: [String: Any] = [
            "credentials": [
                "consumer_session_client_secret": Self.consumerSessionClientSecret,
            ],
            "request_surface": Self.requestSurface,
        ]
        parameters.merge(additionalParameters) { _, new in new }
        return parameters
    }

    private func stubRequest(
        path: String,
        authorizationKey: String,
        expectedParameters: [String: Any],
        responseJSON: String
    ) {
        stubRequest(
            path: path,
            authorizationKey: authorizationKey,
            expectedParameters: expectedParameters
        ) { _ in
            HTTPStubsResponse(
                data: Data(responseJSON.utf8),
                statusCode: 200,
                headers: nil
            )
        }
    }

    private func stubRequest(
        path: String,
        authorizationKey: String,
        expectedParameters: [String: Any],
        response: @escaping (URLRequest) -> HTTPStubsResponse
    ) {
        let defaultRequest = backingAPIClient.configuredRequest(for: URL(string: "https://api.stripe.com/v1")!)
        stub { request in
            XCTAssertEqual(request.url?.path, path)
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer \(authorizationKey)")
            XCTAssertNil(request.value(forHTTPHeaderField: "X-Stripe-Identity-Client-Version"))
            XCTAssertEqual(
                request.value(forHTTPHeaderField: "Stripe-Version"),
                defaultRequest.value(forHTTPHeaderField: "Stripe-Version")
            )
            let userAgent = request.value(forHTTPHeaderField: "X-Stripe-User-Agent")
                .flatMap { $0.data(using: .utf8) }
                .flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: String] }
            XCTAssertEqual(userAgent?["bindings_version"], STPAPIClient.STPSDKVersion)
            XCTAssertEqual(userAgent?["lang"], "objective-c")
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-Requested-With"), "fetch")
            XCTAssertEqual(
                request.value(forHTTPHeaderField: "Content-Type"),
                "application/x-www-form-urlencoded"
            )
            XCTAssertEqual(
                request.ohhttpStubs_httpBody.flatMap { String(data: $0, encoding: .utf8) },
                URLEncoder.queryString(from: expectedParameters)
            )
            return true
        } response: { request in
            response(request)
        }
    }

    private func assertSuccess<Value>(
        _ promise: Promise<Value>,
        assertions: @escaping (Value) -> Void
    ) {
        let expectation = expectation(description: "Request completed")
        promise.observe { result in
            switch result {
            case .success(let value):
                assertions(value)
            case .failure(let error):
                XCTFail("Request failed: \(error)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2)
    }

    private func assertFailure<Value>(
        _ promise: Promise<Value>,
        assertions: @escaping (Error) -> Void
    ) {
        let expectation = expectation(description: "Request failed")
        promise.observe { result in
            switch result {
            case .success:
                XCTFail("Expected request to fail")
            case .failure(let error):
                assertions(error)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2)
    }
}

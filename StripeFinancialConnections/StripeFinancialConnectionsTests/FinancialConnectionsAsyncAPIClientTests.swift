//
//  FinancialConnectionsAsyncAPIClientTests.swift
//  StripeFinancialConnectionsTests
//
//  Created by Mat Schmid on 2024-08-02.
//

import XCTest

@_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils
@testable @_spi(STP) import StripeFinancialConnections

class FinancialConnectionsAsyncAPIClientTests: XCTestCase {
    private enum TestError: Error {
        case sampleError
    }

    private class CallTracker {
        var sleepCallCount = 0
        var apiCallCount = 0
    }

    private class MockURLProtocol: URLProtocol {
        static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }

        override func startLoading() {
            guard let requestHandler = Self.requestHandler else {
                XCTFail("Missing request handler.")
                return
            }

            do {
                let (response, data) = try requestHandler(request)
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        }

        override func stopLoading() {}
    }

    private let mockApiClient = APIStubbedTestCase.stubbedAPIClient()
    private var apiClient: FinancialConnectionsAsyncAPIClient!
    private var tracker: CallTracker!

    override func setUp() {
        super.setUp()
        apiClient = FinancialConnectionsAsyncAPIClient(apiClient: mockApiClient)
        tracker = CallTracker()
    }

    override func tearDown() {
        super.tearDown()
        apiClient = nil
        tracker = nil
    }

    func testConusmerPublishableKeyProvider() {
        XCTAssertNil(apiClient.consumerPublishableKeyProvider(canUseConsumerKey: true))

        let consumerPublishableKey = "consumerPublishableKey"
        apiClient.consumerPublishableKey = consumerPublishableKey
        XCTAssertNil(apiClient.consumerPublishableKeyProvider(canUseConsumerKey: true))

        apiClient.isLinkWithStripe = true
        XCTAssertNil(apiClient.consumerPublishableKeyProvider(canUseConsumerKey: true))

        let unverifiedConsumerSession = ConsumerSessionData(
            clientSecret: "clientSecret",
            emailAddress: "emailAddress",
            redactedFormattedPhoneNumber: "redactedFormattedPhoneNumber",
            verificationSessions: []
        )
        apiClient.consumerSession = unverifiedConsumerSession
        XCTAssertNil(apiClient.consumerPublishableKeyProvider(canUseConsumerKey: true))

        let verifiedConsumerSession = ConsumerSessionData(
            clientSecret: "clientSecret",
            emailAddress: "emailAddress",
            redactedFormattedPhoneNumber: "redactedFormattedPhoneNumber",
            verificationSessions: [
                VerificationSession(
                    type: .sms,
                    state: .verified
                ),
            ]
        )
        apiClient.consumerSession = verifiedConsumerSession
        XCTAssertEqual(apiClient.consumerPublishableKeyProvider(canUseConsumerKey: true), consumerPublishableKey)

        XCTAssertNil(apiClient.consumerPublishableKeyProvider(canUseConsumerKey: false))
    }

    func testEmptyBillingAddressEncodedAsParameters() throws {
        let billingAddress = BillingAddress()
        let encodedBillingAddress = try FinancialConnectionsAsyncAPIClient.encodeAsParameters(billingAddress)

        XCTAssertNil(encodedBillingAddress)
    }

    func testBillingAddressEncodedAsParameters() throws {
        let billingAddress = BillingAddress(
            name: "Bobby Tables",
            line1: "123 Fake St",
            line2: nil,
            city: "Utopia",
            state: "CA",
            postalCode: "90210",
            countryCode: "US"
        )
        let encodedBillingAddress = try FinancialConnectionsAsyncAPIClient.encodeAsParameters(billingAddress)

        XCTAssertEqual(encodedBillingAddress?["name"] as? String, "Bobby Tables")
        XCTAssertEqual(encodedBillingAddress?["line_1"] as? String, "123 Fake St")
        XCTAssertNil(encodedBillingAddress?["line_2"])
        XCTAssertEqual(encodedBillingAddress?["locality"] as? String, "Utopia")
        XCTAssertEqual(encodedBillingAddress?["administrative_area"] as? String, "CA")
        XCTAssertEqual(encodedBillingAddress?["postal_code"] as? String, "90210")
        XCTAssertEqual(encodedBillingAddress?["country_code"] as? String, "US")
    }

    func testBillingAddressEncodedAsParametersNonNilLine2() throws {
        let billingAddress = BillingAddress(
            name: "Bobby Tables",
            line1: "123 Fake St",
            line2: "",
            city: "Utopia",
            state: "CA",
            postalCode: "90210",
            countryCode: "US"
        )
        let encodedBillingAddress = try FinancialConnectionsAsyncAPIClient.encodeAsParameters(billingAddress)

        XCTAssertEqual(encodedBillingAddress?["name"] as? String, "Bobby Tables")
        XCTAssertEqual(encodedBillingAddress?["line_1"] as? String, "123 Fake St")
        XCTAssertNil(encodedBillingAddress?["line_2"])
        XCTAssertEqual(encodedBillingAddress?["locality"] as? String, "Utopia")
        XCTAssertEqual(encodedBillingAddress?["administrative_area"] as? String, "CA")
        XCTAssertEqual(encodedBillingAddress?["postal_code"] as? String, "90210")
        XCTAssertEqual(encodedBillingAddress?["country_code"] as? String, "US")
    }

    func testApplyAttestationParameters() async {
        // Mark API client as testmode to use a mock assertion
        mockApiClient.publishableKey = "pk_test"

        let baseParameters: [String: Any] = [
            "base_parameter": true,
        ]
        let apiClient = FinancialConnectionsAsyncAPIClient(apiClient: mockApiClient)
        let updatedParameters = await apiClient.assertAndApplyAttestationParameters(
            to: baseParameters,
            api: .linkSignUp,
            pane: .consent
        )

        XCTAssertNotNil(updatedParameters["base_parameter"])
        XCTAssertNotNil(updatedParameters["app_id"])
        XCTAssertNotNil(updatedParameters["key_id"])
        XCTAssertNotNil(updatedParameters["device_id"])
        XCTAssertNotNil(updatedParameters["ios_assertion_object"])
    }

    // MARK: Polling

    func testSuccessfulFirstAttempt() async throws {
        let expectedResult = "Success"

        let result = try await apiClient.poll(
            initialPollDelay: 0.1,
            maxNumberOfRetries: 3,
            retryInterval: 0.1,
            sleepAction: { _ in
                self.tracker.sleepCallCount += 1
            },
            apiCall: {
                self.tracker.apiCallCount += 1
                return expectedResult
            }
        )

        XCTAssertEqual(result, expectedResult)
        XCTAssertEqual(tracker.apiCallCount, 1)
        XCTAssertEqual(tracker.sleepCallCount, 1)
    }

    func testRetrySuccessOnSecondAttempt() async throws {
        let expectedResult = "Success after retry"

        let result = try await apiClient.poll(
            initialPollDelay: 0.1,
            maxNumberOfRetries: 3,
            retryInterval: 0.1,
            sleepAction: { _ in
                self.tracker.sleepCallCount += 1
            },
            apiCall: {
                self.tracker.apiCallCount += 1
                if self.tracker.apiCallCount == 1 {
                    throw TestError.sampleError
                }
                return expectedResult
            }
        )

        XCTAssertEqual(result, expectedResult)
        XCTAssertEqual(self.tracker.apiCallCount, 2)
        XCTAssertEqual(self.tracker.sleepCallCount, 2)
    }

    func testMaxRetriesReached() async {
        let maxRetries = 3

        do {
            _ = try await apiClient.poll(
                initialPollDelay: 0.01,
                maxNumberOfRetries: maxRetries,
                retryInterval: 0.01,
                sleepAction: { _ in
                    self.tracker.sleepCallCount += 1
                },
                apiCall: {
                    self.tracker.apiCallCount += 1
                    throw TestError.sampleError
                }
            )
            XCTFail("Should throw an error")
        } catch let error as FinancialConnectionsAsyncAPIClient.PollingError {
            XCTAssertEqual(error, FinancialConnectionsAsyncAPIClient.PollingError.maxRetriesReached)
            XCTAssertEqual(self.tracker.apiCallCount, maxRetries)
            XCTAssertEqual(self.tracker.sleepCallCount, maxRetries)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testPollDoesNotRetryOnClientError() async throws {
        // Given an API call that fails with a 4xx carrying details the caller needs
        let extraFields: [String: Any] = ["reason": "missing_required_data"]
        let clientError = try MakeStripeAPIError(statusCode: 400, extraFields: extraFields)

        do {
            // When we poll
            _ = try await apiClient.poll(
                initialPollDelay: 0.01,
                maxNumberOfRetries: 3,
                retryInterval: 0.01,
                sleepAction: { _ in
                    self.tracker.sleepCallCount += 1
                },
                apiCall: {
                    self.tracker.apiCallCount += 1
                    throw clientError
                }
            )
            XCTFail("Should throw an error")
        } catch {
            // Then the original error surfaces immediately, with its `extra_fields` intact,
            // rather than being retried and replaced by `maxRetriesReached`
            XCTAssertEqual(error.extraFields?["reason"] as? String, "missing_required_data")
            XCTAssertEqual(self.tracker.apiCallCount, 1)
            // only the initial poll delay, no retry intervals
            XCTAssertEqual(self.tracker.sleepCallCount, 1)
        }
    }

    func testPollRetriesOnServerError() async throws {
        // Given an API call that fails with a 5xx, which may well succeed on retry
        let maxRetries = 3
        let serverError = try MakeStripeAPIError(statusCode: 500)

        do {
            // When we poll
            _ = try await apiClient.poll(
                initialPollDelay: 0.01,
                maxNumberOfRetries: maxRetries,
                retryInterval: 0.01,
                sleepAction: { _ in
                    self.tracker.sleepCallCount += 1
                },
                apiCall: {
                    self.tracker.apiCallCount += 1
                    throw serverError
                }
            )
            XCTFail("Should throw an error")
        } catch let error as FinancialConnectionsAsyncAPIClient.PollingError {
            // Then we retry as usual
            XCTAssertEqual(error, .maxRetriesReached)
            XCTAssertEqual(self.tracker.apiCallCount, maxRetries)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testPollRetriesOnTransientClientError() async throws {
        // Given a 4xx that's transient by design and may well succeed on retry
        let maxRetries = 3
        for statusCode in [408, 429] {
            tracker = CallTracker()
            let transientError = try MakeStripeAPIError(statusCode: statusCode)

            do {
                // When we poll
                _ = try await apiClient.poll(
                    initialPollDelay: 0.01,
                    maxNumberOfRetries: maxRetries,
                    retryInterval: 0.01,
                    sleepAction: { _ in
                        self.tracker.sleepCallCount += 1
                    },
                    apiCall: {
                        self.tracker.apiCallCount += 1
                        throw transientError
                    }
                )
                XCTFail("Should throw an error")
            } catch let error as FinancialConnectionsAsyncAPIClient.PollingError {
                // Then we retry as usual, rather than aborting after one attempt
                XCTAssertEqual(error, .maxRetriesReached, "Status code \(statusCode)")
                XCTAssertEqual(self.tracker.apiCallCount, maxRetries, "Status code \(statusCode)")
            } catch {
                XCTFail("Wrong error type for status code \(statusCode): \(error)")
            }
        }
    }

    func testDefaultParameters() async throws {
        var callCount = 0

        let result = try await apiClient.poll(
            sleepAction: { _ in },
            apiCall: {
                callCount += 1
                return "Default Success"
            }
        )

        XCTAssertEqual(result, "Default Success")
        XCTAssertEqual(callCount, 1)
    }

    func testSaveAccountsToNetworkAndLink_pollAccountNumbersUsesClientSecretParameter() async throws {
        var pollRequestQuery: String?
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let stpAPIClient = STPAPIClient(publishableKey: "pk_test_123")
        stpAPIClient.urlSession = URLSession(configuration: configuration)
        let apiClient = FinancialConnectionsAsyncAPIClient(apiClient: stpAPIClient)

        MockURLProtocol.requestHandler = { request in
            guard let url = request.url else {
                throw TestError.sampleError
            }

            let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!

            if url.path.hasSuffix(FinancialConnectionsAPIEndpoint.pollAccountNumbers.rawValue) {
                pollRequestQuery = url.query
                return (response, Data("{}".utf8))
            }

            if url.path.hasSuffix(FinancialConnectionsAPIEndpoint.saveAccountsToLink.rawValue) {
                let data = try JSONSerialization.data(withJSONObject: self.makeMinimalManifestResponse())
                return (response, data)
            }

            throw TestError.sampleError
        }
        defer {
            MockURLProtocol.requestHandler = nil
        }

        _ = try await apiClient.saveAccountsToNetworkAndLink(
            shouldPollAccounts: true,
            selectedAccounts: [try makePartnerAccount(linkedAccountId: "linked_account_123")],
            emailAddress: nil,
            phoneNumber: nil,
            country: nil,
            consumerSessionClientSecret: nil,
            clientSecret: "las_client_secret_123",
            isRelink: false
        )

        XCTAssertEqual(pollRequestQuery?.contains("client_secret=las_client_secret_123"), true)
        XCTAssertEqual(pollRequestQuery?.contains("clientSecret="), false)
    }

    private func makePartnerAccount(linkedAccountId: String) throws -> FinancialConnectionsPartnerAccount {
        let jsonObject: [String: Any] = [
            "id": "fca_123",
            "name": "Checking",
            "linked_account_id": linkedAccountId,
            "supported_payment_method_types": ["us_bank_account"],
        ]
        let data = try JSONSerialization.data(withJSONObject: jsonObject)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(FinancialConnectionsPartnerAccount.self, from: data)
    }

    private func makeMinimalManifestResponse() -> [String: Any] {
        return [
            "allow_manual_entry": false,
            "consent_required": false,
            "custom_manual_entry_handling": false,
            "disable_link_more_accounts": false,
            "id": "las_123",
            "instant_verification_disabled": false,
            "institution_search_disabled": false,
            "livemode": false,
            "manual_entry_mode": "automatic",
            "manual_entry_uses_microdeposits": false,
            "next_pane": "success",
            "permissions": [],
            "product": "bank_account",
            "single_account": false,
        ]
    }
}

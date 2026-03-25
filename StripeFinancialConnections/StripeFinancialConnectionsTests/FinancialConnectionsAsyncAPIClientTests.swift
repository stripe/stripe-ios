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
}

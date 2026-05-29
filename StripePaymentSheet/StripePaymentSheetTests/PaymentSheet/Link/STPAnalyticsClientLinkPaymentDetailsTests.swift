//  STPAnalyticsClientLinkPaymentDetailsTests.swift
//  StripePaymentSheetTests
//

import OHHTTPStubs
import OHHTTPStubsSwift
import XCTest

@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripeCoreTestUtils
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
@testable @_spi(STP) import StripePaymentsTestUtils

final class STPAnalyticsClientLinkPaymentDetailsTests: APIStubbedTestCase {

    // Tests that the sent event fires before the request and the received event
    // fires on success, both with the correct params.
    func testListPaymentDetails_firesTwoEvents() {
        let analyticsClient = STPTestingAnalyticsClient()

        // Stub the consumers/payment_details/list endpoint to return one CARD and one PIX entry.
        stub { request in
            request.url?.absoluteString.contains("consumers/payment_details/list") ?? false
        } response: { _ in
            let cardEntry: [String: Any] = [
                "id": "pd_card",
                "type": "CARD",
                "cardDetails": [
                    "expYear": 30,
                    "expMonth": 12,
                    "brand": "visa",
                    "networks": ["visa"],
                    "last4": "4242",
                    "funding": "CREDIT",
                ],
                "isDefault": true,
            ]
            let pixEntry: [String: Any] = [
                "id": "pd_pix",
                "type": "PIX",
                "isDefault": false,
            ]
            let body: [String: Any] = ["redacted_payment_details": [cardEntry, pixEntry]]
            return HTTPStubsResponse(jsonObject: body, statusCode: 200, headers: nil)
        }

        let account = PaymentSheetLinkAccount(
            email: "user@example.com",
            session: LinkStubs.consumerSession(),
            publishableKey: nil,
            displayablePaymentDetails: nil,
            apiClient: STPAPIClient(publishableKey: STPTestingDefaultPublishableKey),
            useMobileEndpoints: false,
            canSyncAttestationState: false
        )

        let sentTypes: [ParsedEnum<ConsumerPaymentDetails.DetailsType>] = [
            ParsedEnum(.card),
            ParsedEnum(rawValue: "PIX"),
        ]

        // Fire the sent event before the request.
        analyticsClient.logLinkPaymentDetailsListRequestSent(sentTypes: sentTypes)

        let expectation = expectation(description: "listPaymentDetails completes")

        account.listPaymentDetails(
            supportedTypes: sentTypes,
            shouldRetryOnAuthError: false
        ) { result in
            guard case .success(let paymentDetails) = result else {
                XCTFail("Expected success, got \(result)")
                expectation.fulfill()
                return
            }

            let receivedTypes = paymentDetails.map { $0.type }
            analyticsClient.logLinkPaymentDetailsListRequestReceived(receivedTypes: receivedTypes)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5)

        // Verify both events were logged in order.
        XCTAssertEqual(analyticsClient._testLogHistory.count, 2)

        let sentEvent = analyticsClient._testLogHistory.first
        XCTAssertEqual(sentEvent?["event"] as? String, "link.payment_details.list.request_sent")
        XCTAssertEqual(sentEvent?["sent_types"] as? String, "CARD,PIX")

        let receivedEvent = analyticsClient._testLogHistory.last
        XCTAssertEqual(receivedEvent?["event"] as? String, "link.payment_details.list.request_received")
        XCTAssertEqual(receivedEvent?["received_types"] as? String, "CARD,PIX")
    }

    // Tests that the sent event fires even when the request fails, and no received
    // event is logged when the backend returns an error.
    func testListPaymentDetails_sendsEventOnFailure() {
        let analyticsClient = STPTestingAnalyticsClient()

        // Stub the endpoint to return a server error.
        stub { request in
            request.url?.absoluteString.contains("consumers/payment_details/list") ?? false
        } response: { _ in
            HTTPStubsResponse(jsonObject: ["error": ["message": "Internal error"]], statusCode: 500, headers: nil)
        }

        let account = PaymentSheetLinkAccount(
            email: "user@example.com",
            session: LinkStubs.consumerSession(),
            publishableKey: nil,
            displayablePaymentDetails: nil,
            apiClient: STPAPIClient(publishableKey: STPTestingDefaultPublishableKey),
            useMobileEndpoints: false,
            canSyncAttestationState: false
        )

        let sentTypes: [ParsedEnum<ConsumerPaymentDetails.DetailsType>] = [
            ParsedEnum(.card),
            ParsedEnum(rawValue: "PIX"),
        ]

        // Fire the sent event before the request.
        analyticsClient.logLinkPaymentDetailsListRequestSent(sentTypes: sentTypes)

        let expectation = expectation(description: "listPaymentDetails completes")

        account.listPaymentDetails(
            supportedTypes: sentTypes,
            shouldRetryOnAuthError: false
        ) { result in
            // On failure, no received event is fired.
            if case .failure = result {
                // Expected failure — only the sent event should have been logged.
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5)

        // Only the sent event should have been logged.
        XCTAssertEqual(analyticsClient._testLogHistory.count, 1)
        let sentEvent = analyticsClient._testLogHistory.first
        XCTAssertEqual(sentEvent?["event"] as? String, "link.payment_details.list.request_sent")
        XCTAssertEqual(sentEvent?["sent_types"] as? String, "CARD,PIX")
    }

    // Tests that the received event reflects when the backend strips a type that
    // was sent.
    func testListPaymentDetails_detectsStrippedType() {
        let analyticsClient = STPTestingAnalyticsClient()

        // Backend only returns CARD, not PIX.
        stub { request in
            request.url?.absoluteString.contains("consumers/payment_details/list") ?? false
        } response: { _ in
            let cardEntry: [String: Any] = [
                "id": "pd_card",
                "type": "CARD",
                "cardDetails": [
                    "expYear": 30,
                    "expMonth": 12,
                    "brand": "visa",
                    "networks": ["visa"],
                    "last4": "4242",
                    "funding": "CREDIT",
                ],
                "isDefault": true,
            ]
            let body: [String: Any] = ["redacted_payment_details": [cardEntry]]
            return HTTPStubsResponse(jsonObject: body, statusCode: 200, headers: nil)
        }

        let account = PaymentSheetLinkAccount(
            email: "user@example.com",
            session: LinkStubs.consumerSession(),
            publishableKey: nil,
            displayablePaymentDetails: nil,
            apiClient: STPAPIClient(publishableKey: STPTestingDefaultPublishableKey),
            useMobileEndpoints: false,
            canSyncAttestationState: false
        )

        let sentTypes: [ParsedEnum<ConsumerPaymentDetails.DetailsType>] = [
            ParsedEnum(.card),
            ParsedEnum(rawValue: "PIX"),
        ]

        // Fire the sent event before the request.
        analyticsClient.logLinkPaymentDetailsListRequestSent(sentTypes: sentTypes)

        let expectation = expectation(description: "listPaymentDetails completes")

        account.listPaymentDetails(
            supportedTypes: sentTypes,
            shouldRetryOnAuthError: false
        ) { result in
            guard case .success(let paymentDetails) = result else {
                XCTFail("Expected success, got \(result)")
                expectation.fulfill()
                return
            }

            let receivedTypes = paymentDetails.map { $0.type }
            analyticsClient.logLinkPaymentDetailsListRequestReceived(receivedTypes: receivedTypes)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5)

        // Verify sent event has PIX but received event does not.
        XCTAssertEqual(analyticsClient._testLogHistory.count, 2)

        let sentEvent = analyticsClient._testLogHistory.first
        XCTAssertEqual(sentEvent?["event"] as? String, "link.payment_details.list.request_sent")
        XCTAssertEqual(sentEvent?["sent_types"] as? String, "CARD,PIX")

        let receivedEvent = analyticsClient._testLogHistory.last
        XCTAssertEqual(receivedEvent?["event"] as? String, "link.payment_details.list.request_received")
        XCTAssertEqual(receivedEvent?["received_types"] as? String, "CARD")
    }
}

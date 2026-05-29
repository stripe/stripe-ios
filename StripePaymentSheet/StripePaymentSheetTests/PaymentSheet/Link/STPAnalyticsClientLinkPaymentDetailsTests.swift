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

    // Tests that `logLinkPaymentDetailsListRequest` fires an event with the correct
    // `sent_types` and `received_types` params when the backend returns a mix of
    // known and unknown payment detail types.
    func testListPaymentDetails_firesAnalyticsEvent() {
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
            analyticsClient.logLinkPaymentDetailsListRequest(
                sentTypes: sentTypes,
                receivedTypes: receivedTypes
            )
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5)

        // Verify the event was logged.
        let loggedEvent = analyticsClient._testLogHistory.last
        XCTAssertEqual(loggedEvent?["event"] as? String, "link.payment_details.list.request")
        XCTAssertEqual(loggedEvent?["sent_types"] as? String, "CARD,PIX")
        XCTAssertEqual(loggedEvent?["received_types"] as? String, "CARD,PIX")
    }

    // Tests that `logLinkPaymentDetailsListRequest` correctly reflects when
    // the backend strips a type that was sent (simulating LPM kill switch behavior).
    func testListPaymentDetails_detectsStrippedType() {
        let analyticsClient = STPTestingAnalyticsClient()

        // Backend only returns CARD, not PIX (simulating kill switch removing PIX).
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
            analyticsClient.logLinkPaymentDetailsListRequest(
                sentTypes: sentTypes,
                receivedTypes: receivedTypes
            )
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5)

        // Verify sent_types includes PIX but received_types does not.
        let loggedEvent = analyticsClient._testLogHistory.last
        XCTAssertEqual(loggedEvent?["event"] as? String, "link.payment_details.list.request")
        XCTAssertEqual(loggedEvent?["sent_types"] as? String, "CARD,PIX")
        XCTAssertEqual(loggedEvent?["received_types"] as? String, "CARD")
    }
}

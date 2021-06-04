//
//  STPAnalyticsClientPaymentsTest.swift
//  StripeiOS Tests
//
//  Created by Mel Ludowise on 5/26/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest

@testable import Stripe

class STPAnalyticsClientPaymentsTest: XCTestCase {
    private var client: STPAnalyticsClient!

    override func setUp() {
        super.setUp()
        client = STPAnalyticsClient()
    }

    func testAdditionalInfo() {
        XCTAssertEqual(client.additionalInfo(), [])

        // Add some info
        client.addAdditionalInfo("hello")
        client.addAdditionalInfo("i'm additional info")
        client.addAdditionalInfo("how are you?")

        XCTAssertEqual(client.additionalInfo(), ["hello", "how are you?", "i'm additional info"])

        // Clear it
        client.clearAdditionalInfo()
        XCTAssertEqual(client.additionalInfo(), [])
    }

    func testProductUsageFull() {
        client.addClass(toProductUsageIfNecessary: MockAnalyticsClass1.self)
        client.addClass(toProductUsageIfNecessary: STPPaymentContext.self)

        let usageLevel = STPAnalyticsClient.uiUsageLevelString(from: client.productUsage)

        XCTAssertEqual(usageLevel, "full")
        XCTAssertEqual(client.productUsage, Set([
            MockAnalyticsClass1.stp_analyticsIdentifier,
            STPPaymentContext.stp_analyticsIdentifier,
        ]))
    }

    func testProductUsageCardTextField() {
        client.addClass(toProductUsageIfNecessary: STPPaymentCardTextField.self)

        let usageLevel = STPAnalyticsClient.uiUsageLevelString(from: client.productUsage)

        XCTAssertEqual(usageLevel, "card_text_field")
        XCTAssertEqual(client.productUsage, Set([
            STPPaymentCardTextField.stp_analyticsIdentifier,
        ]))
    }

    func testProductUsagePartial() {
        client.addClass(toProductUsageIfNecessary: STPPaymentCardTextField.self)
        client.addClass(toProductUsageIfNecessary: MockAnalyticsClass1.self)
        client.addClass(toProductUsageIfNecessary: MockAnalyticsClass2.self)

        let usageLevel = STPAnalyticsClient.uiUsageLevelString(from: client.productUsage)

        XCTAssertEqual(usageLevel, "partial")
        XCTAssertEqual(client.productUsage, Set([
            MockAnalyticsClass1.stp_analyticsIdentifier,
            MockAnalyticsClass2.stp_analyticsIdentifier,
            STPPaymentCardTextField.stp_analyticsIdentifier,
        ]))
    }

    func testProductUsageNone() {
        let usageLevel = STPAnalyticsClient.uiUsageLevelString(from: client.productUsage)

        XCTAssertEqual(usageLevel, "none")
        XCTAssert(client.productUsage.isEmpty)
    }

    func testPayloadFromAnalytic() {
        client.addAdditionalInfo("test_additional_info")

        let mockAnalytic = MockAnalytic()
        let payload = client.payload(from: mockAnalytic)

        // Verify event name is included
        XCTAssertEqual(payload["event"] as? String, mockAnalytic.event.rawValue)

        // Verify additionalInfo is included
        XCTAssertEqual(payload["additional_info"] as? [String], ["test_additional_info"])

        // Verify all the analytic params are in the payload
        XCTAssertEqual(payload["test_param1"] as? Int, 1)
        XCTAssertEqual(payload["test_param2"] as? String, "two")

        // Verify productUsage is included
        XCTAssertNotNil(payload["product_usage"])
    }

}

// MARK: - Mock types

private struct MockAnalytic: Analytic {
    let event = STPAnalyticEvent.sourceCreation

    let params: [String : Any] = [
        "test_param1": 1,
        "test_param2": "two",
    ]
}

private struct MockAnalyticsClass1: STPAnalyticsProtocol {
    static let stp_analyticsIdentifier = "MockAnalyticsClass1"
}

private struct MockAnalyticsClass2: STPAnalyticsProtocol {
    static let stp_analyticsIdentifier = "MockAnalyticsClass2"
}

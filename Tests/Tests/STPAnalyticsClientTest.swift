//
//  STPAnalyticsTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 12/15/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import XCTest

@testable import Stripe

class STPAnalyticsClientTestSwift: XCTestCase {
    private var client: STPAnalyticsClient!

    override func setUp() {
        super.setUp()
        client = STPAnalyticsClient()
    }

    func makeConfig(
        applePay: PaymentSheet.ApplePayConfiguration?, customer: PaymentSheet.CustomerConfiguration?
    ) -> PaymentSheet.Configuration {
        var config = PaymentSheet.Configuration()
        config.applePay = applePay
        config.customer = customer
        return config
    }

    func testPaymentSheetInit() {
        let customerConfig = PaymentSheet.CustomerConfiguration(id: "", ephemeralKeySecret: "")
        let applePayConfig = PaymentSheet.ApplePayConfiguration(
            merchantId: "", merchantCountryCode: "")
        XCTAssertEqual(
            client.paymentSheetInitEventValue(
                isCustom: false, configuration: makeConfig(applePay: nil, customer: nil)),
            "mc_complete_init_default")
        XCTAssertEqual(
            client.paymentSheetInitEventValue(
                isCustom: true, configuration: makeConfig(applePay: nil, customer: nil)),
            "mc_custom_init_default")
        XCTAssertEqual(
            client.paymentSheetInitEventValue(
                isCustom: false, configuration: makeConfig(applePay: applePayConfig, customer: nil)),
            "mc_complete_init_applepay")
        XCTAssertEqual(
            client.paymentSheetInitEventValue(
                isCustom: true, configuration: makeConfig(applePay: applePayConfig, customer: nil)),
            "mc_custom_init_applepay")
        XCTAssertEqual(
            client.paymentSheetInitEventValue(
                isCustom: false, configuration: makeConfig(applePay: nil, customer: customerConfig)),
            "mc_complete_init_customer")
        XCTAssertEqual(
            client.paymentSheetInitEventValue(
                isCustom: true, configuration: makeConfig(applePay: nil, customer: customerConfig)),
            "mc_custom_init_customer")
        XCTAssertEqual(
            client.paymentSheetInitEventValue(
                isCustom: false,
                configuration: makeConfig(applePay: applePayConfig, customer: customerConfig)),
            "mc_complete_init_customer_applepay")
        XCTAssertEqual(
            client.paymentSheetInitEventValue(
                isCustom: true,
                configuration: makeConfig(applePay: applePayConfig, customer: customerConfig)),
            "mc_custom_init_customer_applepay")
    }

    func testPaymentSheetAddsUsage() {
        let client = STPAnalyticsClient.sharedClient
        let _ = PaymentSheet(
            paymentIntentClientSecret: "", configuration: PaymentSheet.Configuration())
        XCTAssertTrue(client.productUsage.contains("PaymentSheet"))

        let _ = PaymentSheet.FlowController(
            intent: .paymentIntent(STPFixtures.paymentIntent()), savedPaymentMethods: [],
            configuration: PaymentSheet.Configuration())
        XCTAssertTrue(client.productUsage.contains("PaymentSheet.FlowController"))
    }

    func testVariousPaymentSheetEvents() {
        let client = STPTestingAnalyticsClient()
        let event1 = XCTestExpectation(description: "mc_custom_sheet_newpm_show")
        client.registerExpectation(event1)
        client.logPaymentSheetShow(isCustom: true, paymentMethod: .newPM)

        let event2 = XCTestExpectation(description: "mc_complete_sheet_savedpm_show")
        client.registerExpectation(event2)
        client.logPaymentSheetShow(isCustom: false, paymentMethod: .savedPM)

        let event3 = XCTestExpectation(description: "mc_complete_payment_savedpm_success")
        client.registerExpectation(event3)
        client.logPaymentSheetPayment(isCustom: false, paymentMethod: .savedPM, result: .completed)

        let event4 = XCTestExpectation(description: "mc_custom_payment_applepay_failure")
        client.registerExpectation(event4)
        client.logPaymentSheetPayment(isCustom: true, paymentMethod: .applePay, result: .failed(error: PaymentSheetError.unknown(debugDescription: "Error")))

        let event5 = XCTestExpectation(description: "mc_custom_paymentoption_applepay_select")
        client.registerExpectation(event5)
        client.logPaymentSheetPaymentOptionSelect(isCustom: true, paymentMethod: .applePay)

        let event6 = XCTestExpectation(description: "mc_complete_paymentoption_newpm_select")
        client.registerExpectation(event6)
        client.logPaymentSheetPaymentOptionSelect(isCustom: false, paymentMethod: .newPM)


        wait(for: [event1, event2, event3, event4, event5, event6], timeout: STPTestingNetworkRequestTimeout)
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

    func testSerializeError() {
        let userInfo = [
            "key1": "value1",
            "key2": "value2",
        ]
        let error = NSError(domain: "test_domain", code: 42, userInfo: userInfo)
        let serializedError = STPAnalyticsClient.serializeError(error)
        XCTAssertEqual(serializedError.count, 3)
        XCTAssertEqual(serializedError["domain"] as? String, "test_domain")
        XCTAssertEqual(serializedError["code"] as? Int, 42)
        XCTAssertEqual(serializedError["user_info"] as? [String: String], userInfo)
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

class STPTestingAnalyticsClient: STPAnalyticsClient {
    var expectedEvents: [String: XCTestExpectation] = [:]

    func registerExpectation(_ expectation: XCTestExpectation) {
        expectedEvents[expectation.description] = expectation
    }

    override func logPayload(_ payload: [String: Any]) {
        if let event = payload["event"] as? String,
           let expectedEvent = expectedEvents[event] {
            expectedEvent.fulfill()
        }
    }
}

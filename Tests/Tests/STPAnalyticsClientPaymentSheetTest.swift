//
//  STPAnalyticsClientPaymentSheetTest.swift
//  StripeiOS Tests
//
//  Created by Mel Ludowise on 5/26/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest

import StripeCoreTestUtils
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import Stripe

class STPAnalyticsClientPaymentSheetTest: XCTestCase {
    private var client: STPAnalyticsClient!

    override func setUp() {
        super.setUp()
        client = STPAnalyticsClient()
    }

    func testPaymentSheetInit() {
        let customerConfig = PaymentSheet.CustomerConfiguration(id: "", ephemeralKeySecret: "")
        let applePayConfig = PaymentSheet.ApplePayConfiguration(
            merchantId: "", merchantCountryCode: "")
        XCTAssertEqual(
            client.paymentSheetInitEventValue(
                isCustom: false, configuration: makeConfig(applePay: nil, customer: nil)).rawValue,
            "mc_complete_init_default")
        XCTAssertEqual(
            client.paymentSheetInitEventValue(
                isCustom: true, configuration: makeConfig(applePay: nil, customer: nil)).rawValue,
            "mc_custom_init_default")
        XCTAssertEqual(
            client.paymentSheetInitEventValue(
                isCustom: false, configuration: makeConfig(applePay: applePayConfig, customer: nil)).rawValue,
            "mc_complete_init_applepay")
        XCTAssertEqual(
            client.paymentSheetInitEventValue(
                isCustom: true, configuration: makeConfig(applePay: applePayConfig, customer: nil)).rawValue,
            "mc_custom_init_applepay")
        XCTAssertEqual(
            client.paymentSheetInitEventValue(
                isCustom: false, configuration: makeConfig(applePay: nil, customer: customerConfig)).rawValue,
            "mc_complete_init_customer")
        XCTAssertEqual(
            client.paymentSheetInitEventValue(
                isCustom: true, configuration: makeConfig(applePay: nil, customer: customerConfig)).rawValue,
            "mc_custom_init_customer")
        XCTAssertEqual(
            client.paymentSheetInitEventValue(
                isCustom: false,
                configuration: makeConfig(applePay: applePayConfig, customer: customerConfig)).rawValue,
            "mc_complete_init_customer_applepay")
        XCTAssertEqual(
            client.paymentSheetInitEventValue(
                isCustom: true,
                configuration: makeConfig(applePay: applePayConfig, customer: customerConfig)).rawValue,
            "mc_custom_init_customer_applepay")
    }

    func testPaymentSheetAddsUsage() {
        let client = STPAnalyticsClient.sharedClient
        let _ = PaymentSheet(
            paymentIntentClientSecret: "", configuration: PaymentSheet.Configuration())
        XCTAssertTrue(client.productUsage.contains("PaymentSheet"))

        let _ = PaymentSheet.FlowController(
            intent: .paymentIntent(STPFixtures.paymentIntent()), savedPaymentMethods: [],
            linkAccount: nil,
            configuration: PaymentSheet.Configuration())
        XCTAssertTrue(client.productUsage.contains("PaymentSheet.FlowController"))
    }

    func testVariousPaymentSheetEvents() {
        let client = STPTestingAnalyticsClient()
        let event1 = XCTestExpectation(description: "mc_custom_sheet_newpm_show")
        client.registerExpectation(event1)
        client.logPaymentSheetShow(isCustom: true, paymentMethod: .newPM, linkEnabled: false, activeLinkSession: false)

        let event2 = XCTestExpectation(description: "mc_complete_sheet_savedpm_show")
        client.registerExpectation(event2)
        client.logPaymentSheetShow(isCustom: false, paymentMethod: .savedPM, linkEnabled: false, activeLinkSession: false)

        let event3 = XCTestExpectation(description: "mc_complete_payment_savedpm_success")
        client.registerExpectation(event3)
        client.logPaymentSheetPayment(
            isCustom: false,
            paymentMethod: .savedPM,
            result: .completed,
            linkEnabled: false,
            activeLinkSession: false)

        let event4 = XCTestExpectation(description: "mc_custom_payment_applepay_failure")
        client.registerExpectation(event4)
        client.logPaymentSheetPayment(
            isCustom: true,
            paymentMethod: .applePay,
            result: .failed(error: PaymentSheetError.unknown(debugDescription: "Error")),
            linkEnabled: false,
            activeLinkSession: false)

        let event5 = XCTestExpectation(description: "mc_custom_paymentoption_applepay_select")
        client.registerExpectation(event5)
        client.logPaymentSheetPaymentOptionSelect(isCustom: true, paymentMethod: .applePay)

        let event6 = XCTestExpectation(description: "mc_complete_paymentoption_newpm_select")
        client.registerExpectation(event6)
        client.logPaymentSheetPaymentOptionSelect(isCustom: false, paymentMethod: .newPM)


        wait(for: [event1, event2, event3, event4, event5, event6], timeout: STPTestingNetworkRequestTimeout)
    }
    
    func testPaymentSheetAnalyticPayload() throws {
        // setup
        let analytic = PaymentSheetAnalytic(event: STPAnalyticEvent.mcInitCompleteApplePay,
                                            paymentConfiguration: nil,
                                            productUsage: Set<String>([STPPaymentContext.stp_analyticsIdentifier]),
                                            additionalParams: ["testKey": "testVal"])

        let client = STPAnalyticsClient()
        client.addAdditionalInfo("test-additional-info")
        client.addClass(toProductUsageIfNecessary: STPPaymentContext.self)

        // test
        let apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let payload = client.payload(from: analytic, apiClient: apiClient)

        // verify
        XCTAssertEqual(15, payload.count)
        XCTAssertNotNil(payload["device_type"] as? String)
        // In xctest, this is the version of Xcode
        XCTAssertNotNil(payload["app_version"] as? String)
        XCTAssertEqual("none", payload["ocr_type"] as? String)
        XCTAssertEqual(STPAnalyticEvent.mcInitCompleteApplePay.rawValue, payload["event"] as? String)
        XCTAssertEqual(STPTestingDefaultPublishableKey, payload["publishable_key"] as? String)
        XCTAssertEqual("analytics.stripeios-1.0", payload["analytics_ua"] as? String)
        XCTAssertEqual("xctest", payload["app_name"] as? String)
        XCTAssertNotNil(payload["os_version"] as? String)
        XCTAssertNil(payload["ui_usage_level"])
        XCTAssertTrue(payload["apple_pay_enabled"] as? Bool ?? false)
        XCTAssertEqual("legacy", payload["pay_var"] as? String)
        XCTAssertEqual(STPAPIClient.STPSDKVersion, payload["bindings_version"] as? String)
        XCTAssertEqual("testVal", payload["testKey"] as? String)
        XCTAssertEqual("X", payload["install"] as? String)

        let additionalInfo = try XCTUnwrap(payload["additional_info"] as? [String])
        XCTAssertEqual(1, additionalInfo.count)
        XCTAssertEqual("test-additional-info", additionalInfo[0])

        let productUsage = try XCTUnwrap(payload["product_usage"] as? [String])
        XCTAssertEqual(1, productUsage.count)
        XCTAssertEqual(STPPaymentContext.stp_analyticsIdentifier, productUsage[0])
    }

    func testLogPaymentSheetPayment_shouldIncludeDuration() throws {
        let client = STPTestingAnalyticsClient()

        client.logPaymentSheetShow(
            isCustom: false,
            paymentMethod: .newPM,
            linkEnabled: false,
            activeLinkSession: false
        )

        client.logPaymentSheetPayment(
            isCustom: false,
            paymentMethod: .savedPM,
            result: .completed,
            linkEnabled: false,
            activeLinkSession: false
        )

        let duration = client.lastPayload?["duration"] as? TimeInterval
        XCTAssertNotNil(duration)
    }
}

// MARK: - Helpers

private extension STPAnalyticsClientPaymentSheetTest {
    func makeConfig(
        applePay: PaymentSheet.ApplePayConfiguration?, customer: PaymentSheet.CustomerConfiguration?
    ) -> PaymentSheet.Configuration {
        var config = PaymentSheet.Configuration()
        config.applePay = applePay
        config.customer = customer
        return config
    }
}

// MARK: - Mock types

private class STPTestingAnalyticsClient: STPAnalyticsClient {
    var expectedEvents: [String: XCTestExpectation] = [:]

    var lastPayload: [String: Any]?

    func registerExpectation(_ expectation: XCTestExpectation) {
        expectedEvents[expectation.description] = expectation
    }

    override func logPayload(_ payload: [String: Any]) {
        if let event = payload["event"] as? String,
           let expectedEvent = expectedEvents[event] {
            expectedEvent.fulfill()
        }

        lastPayload = payload
    }
}

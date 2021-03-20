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
            intentClientSecret: "", configuration: PaymentSheet.Configuration())
        XCTAssertTrue(client.productUsage.contains("PaymentSheet"))

        let _ = PaymentSheet.FlowController(
            intent: .paymentIntent(STPFixtures.paymentIntent()), savedPaymentMethods: [],
            configuration: PaymentSheet.Configuration())
        XCTAssertTrue(client.productUsage.contains("PaymentSheet.FlowController"))
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

    func testProductUsageDictionaryFull() {
        client.addClass(toProductUsageIfNecessary: MockAnalyticsClass1.self)
        client.addClass(toProductUsageIfNecessary: STPPaymentContext.self)

        let usageDict = client.productUsageDictionary()
        XCTAssertEqual(usageDict.count, 2)
        XCTAssertEqual(usageDict["ui_usage_level"] as? String, "full")
        XCTAssertEqual(usageDict["product_usage"] as? [String], [
            MockAnalyticsClass1.stp_analyticsIdentifier,
            STPPaymentContext.stp_analyticsIdentifier,
        ])
    }

    func testProductUsageDictionaryCardTextField() {
        client.addClass(toProductUsageIfNecessary: STPPaymentCardTextField.self)

        let usageDict = client.productUsageDictionary()
        XCTAssertEqual(usageDict.count, 2)
        XCTAssertEqual(usageDict["ui_usage_level"] as? String, "card_text_field")
        XCTAssertEqual(usageDict["product_usage"] as? [String], [
            STPPaymentCardTextField.stp_analyticsIdentifier,
        ])
    }

    func testProductUsageDictionaryPartial() {
        client.addClass(toProductUsageIfNecessary: STPPaymentCardTextField.self)
        client.addClass(toProductUsageIfNecessary: MockAnalyticsClass1.self)
        client.addClass(toProductUsageIfNecessary: MockAnalyticsClass2.self)

        let usageDict = client.productUsageDictionary()
        XCTAssertEqual(usageDict.count, 2)
        XCTAssertEqual(usageDict["ui_usage_level"] as? String, "partial")
        XCTAssertEqual(usageDict["product_usage"] as? [String], [
            MockAnalyticsClass1.stp_analyticsIdentifier,
            MockAnalyticsClass2.stp_analyticsIdentifier,
            STPPaymentCardTextField.stp_analyticsIdentifier,
        ])
    }

    func testProductUsageDictionaryNone() {
        let usageDict = client.productUsageDictionary()
        XCTAssertEqual(usageDict.count, 2)
        XCTAssertEqual(usageDict["ui_usage_level"] as? String, "none")
        XCTAssertEqual(usageDict["product_usage"] as? [String], [])
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
        XCTAssertNotNil(payload["ui_usage_level"])
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

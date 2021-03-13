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
    var testingClient: STPTestingAnalyticsClient!
    
    override func setUp() {
        testingClient = STPTestingAnalyticsClient()
        STPAnalyticsClient.sharedClient = testingClient
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
        let client = STPAnalyticsClient.sharedClient
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
    
    func testPaymentSheetShowEvent() {
        let initEvent = XCTestExpectation(description: "mc_complete_init_default")
        testingClient.expectedEvents[initEvent.description] = initEvent
        let _ = PaymentSheet(intentClientSecret: "", configuration: PaymentSheet.Configuration())
        wait(for: [initEvent], timeout: STPTestingNetworkRequestTimeout)
    }
    
    func testVariousPaymentSheetEvents() {
        let event1 = XCTestExpectation(description: "mc_custom_sheet_newpm_show")
        testingClient.registerExpectation(event1)
        testingClient.logPaymentSheetShow(isCustom: true, paymentMethod: .newPM)

        let event2 = XCTestExpectation(description: "mc_complete_sheet_savedpm_show")
        testingClient.registerExpectation(event2)
        testingClient.logPaymentSheetShow(isCustom: false, paymentMethod: .savedPM)

        let event3 = XCTestExpectation(description: "mc_complete_payment_savedpm_success")
        testingClient.registerExpectation(event3)
        testingClient.logPaymentSheetPayment(isCustom: false, paymentMethod: .savedPM, result: .completed)
        
        let event4 = XCTestExpectation(description: "mc_custom_payment_applepay_failure")
        testingClient.registerExpectation(event4)
        testingClient.logPaymentSheetPayment(isCustom: true, paymentMethod: .applePay, result: .failed(error: PaymentSheetError.unknown(debugDescription: "Error")))

        let event5 = XCTestExpectation(description: "mc_custom_paymentoption_applepay_select")
        testingClient.registerExpectation(event5)
        testingClient.logPaymentSheetPaymentOptionSelect(isCustom: true, paymentMethod: .applePay)

        let event6 = XCTestExpectation(description: "mc_complete_paymentoption_newpm_select")
        testingClient.registerExpectation(event6)
        testingClient.logPaymentSheetPaymentOptionSelect(isCustom: false, paymentMethod: .newPM)
        

        wait(for: [event1, event2, event3, event4, event5, event6], timeout: STPTestingNetworkRequestTimeout)
    }
    
    override func tearDown() {
        // STPAnalyticsClient has no mutable state. Set it back to a fresh normal instance for the benefit of anyone else living in this test process.
        STPAnalyticsClient.sharedClient = STPAnalyticsClient()
    }
}

class STPTestingAnalyticsClient: STPAnalyticsClient {
    var expectedEvents: [String: XCTestExpectation] = [:]

    func registerExpectation(_ expectation: XCTestExpectation) {
        expectedEvents[expectation.description] = expectation
    }
    
    override func logPayload(_ payload: [String: Any], unconditionally: Bool = false) {
        if let event = payload["event"] as? String,
           let expectedEvent = expectedEvents[event] {
            expectedEvent.fulfill()
        }
    }
}

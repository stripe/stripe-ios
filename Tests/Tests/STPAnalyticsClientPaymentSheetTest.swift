//
//  STPAnalyticsClientPaymentSheetTest.swift
//  StripeiOS Tests
//
//  Created by Mel Ludowise on 5/26/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest

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

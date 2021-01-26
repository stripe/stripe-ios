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
    func makeConfig(applePay: PaymentSheet.ApplePayConfiguration?, customer: PaymentSheet.CustomerConfiguration?) -> PaymentSheet.Configuration {
        var config = PaymentSheet.Configuration()
        config.applePay = applePay
        config.customer = customer
        return config
    }

    func testPaymentSheetInit() {
        let customerConfig = PaymentSheet.CustomerConfiguration(id: "", ephemeralKeySecret: "")
        let applePayConfig = PaymentSheet.ApplePayConfiguration(merchantId: "", merchantCountryCode: "")
        let client = STPAnalyticsClient.sharedClient
        XCTAssertEqual(client.paymentSheetInitEventValue(isCustom: false, configuration: makeConfig(applePay: nil, customer: nil)),
                       "mc_complete_init_default")
        XCTAssertEqual(client.paymentSheetInitEventValue(isCustom: true, configuration: makeConfig(applePay: nil, customer: nil)),
                       "mc_custom_init_default")
        XCTAssertEqual(client.paymentSheetInitEventValue(isCustom: false, configuration: makeConfig(applePay: applePayConfig, customer: nil)),
                       "mc_complete_init_applepay")
        XCTAssertEqual(client.paymentSheetInitEventValue(isCustom: true, configuration: makeConfig(applePay: applePayConfig, customer: nil)),
                       "mc_custom_init_applepay")
        XCTAssertEqual(client.paymentSheetInitEventValue(isCustom: false, configuration: makeConfig(applePay: nil, customer: customerConfig)),
                       "mc_complete_init_customer")
        XCTAssertEqual(client.paymentSheetInitEventValue(isCustom: true, configuration: makeConfig(applePay: nil, customer: customerConfig)),
                       "mc_custom_init_customer")
        XCTAssertEqual(client.paymentSheetInitEventValue(isCustom: false, configuration: makeConfig(applePay: applePayConfig, customer: customerConfig)),
                       "mc_complete_init_customer_applepay")
        XCTAssertEqual(client.paymentSheetInitEventValue(isCustom: true, configuration: makeConfig(applePay: applePayConfig, customer: customerConfig)),
                       "mc_custom_init_customer_applepay")
    }

    func testPaymentSheetAddsUsage() {
        let client = STPAnalyticsClient.sharedClient
        let _ = PaymentSheet(paymentIntentClientSecret: "", configuration: PaymentSheet.Configuration())
        XCTAssertTrue(client.productUsage.contains("PaymentSheet"))

        let _ = PaymentSheet.FlowController(paymentIntent: STPFixtures.paymentIntent(), savedPaymentMethods: [], configuration: PaymentSheet.Configuration())
        XCTAssertTrue(client.productUsage.contains("PaymentSheet.FlowController"))
    }
}

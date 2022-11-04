//
//  STPAnalyticsClient+StripePayments.swift
//  StripePaymentsTests
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import XCTest

// swift-format-ignore
@_spi(STP) @testable import StripeCore

// swift-format-ignore
@_spi(STP) @testable import StripePayments

class STPAnalyticsClientPaymentsUITest: XCTestCase {
    func testPaymentsSDKVariantPayload() throws {
        // setup
        let analytic = GenericPaymentAnalytic(
            event: .paymentMethodCreation,
            paymentConfiguration: nil,
            productUsage: [],
            additionalParams: [:]
        )
        let client = STPAnalyticsClient()
        let payload = client.payload(from: analytic)
        XCTAssertEqual("payments-api", payload["pay_var"] as? String)
    }
}

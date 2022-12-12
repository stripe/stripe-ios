//
//  STPAnalyticsClient+PaymentsUITests.swift
//  StripePaymentsUITests
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import XCTest

// swift-format-ignore
@_spi(STP) @testable import StripeCore

// swift-format-ignore
@_spi(STP) @testable import StripePayments

// swift-format-ignore
@_spi(STP) @testable import StripePaymentsUI

class STPAnalyticsClientPaymentsUITest: XCTestCase {
    func testPaymentsUISDKVariantPayload() throws {
        // setup
        let analytic = GenericPaymentAnalytic(
            event: .paymentMethodCreation,
            paymentConfiguration: nil,
            productUsage: [],
            additionalParams: [:]
        )
        let client = STPAnalyticsClient()
        let payload = client.payload(from: analytic)
        XCTAssertEqual("payments-ui", payload["pay_var"] as? String)
    }
}

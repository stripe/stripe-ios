//
//  STPAnalyticsClient+PaymentsUITests.swift
//  StripePaymentsUITests
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import XCTest

// swift-format-ignore
@_spi(InternalOnlyAPI) @testable import StripeCore

// swift-format-ignore
@_spi(InternalOnlyAPI) @testable import StripePayments

// swift-format-ignore
@_spi(InternalOnlyAPI) @testable import StripePaymentsUI

class STPAnalyticsClientPaymentsUITests: XCTestCase {
    func testPaymentsUISDKVariantPayload() throws {
        // setup
        let analytic = GenericPaymentAnalytic(
            event: .paymentMethodCreation,
            additionalParams: [:]
        )
        let client = STPAnalyticsClient()
        let payload = client.payload(from: analytic)
        XCTAssertEqual("payments-ui", payload["pay_var"] as? String)
    }
}

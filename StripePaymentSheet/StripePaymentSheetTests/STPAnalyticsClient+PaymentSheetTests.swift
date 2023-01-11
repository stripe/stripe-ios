//
//  STPAnalyticsClient+PaymentSheetTests.swift
//  StripePaymentSheetTests
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) @testable import StripeCore
@_spi(STP) @testable import StripePaymentSheet
import XCTest

class STPAnalyticsClientPaymentSheetTest: XCTestCase {
    func testPaymentSheetSDKVariantPayload() throws {
        // setup
        let analytic = PaymentSheetAnalytic(
            event: .paymentMethodCreation,
            productUsage: [],
            additionalParams: [:]
        )
        let client = STPAnalyticsClient()
        let payload = client.payload(from: analytic)
        XCTAssertEqual("paymentsheet", payload["pay_var"] as? String)
    }
}

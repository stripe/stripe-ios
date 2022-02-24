//
//  STPAnalyticsClient+ApplePayTest.swift
//  StripeApplePayTests
//
//  Created by David Estes on 2/3/22.
//

import Foundation
import XCTest
@_spi(STP) @testable import StripeApplePay
@_spi(STP) @testable import StripeCore

class STPAnalyticsClientApplePayTest: XCTestCase {
    func testApplePaySDKVariantPayload() throws {
        // setup
        let analytic = PaymentAPIAnalytic(
            event: .paymentMethodCreation,
            productUsage: [],
            additionalParams: [:]
        )
        let client = STPAnalyticsClient()
        let payload = client.payload(from: analytic)
        XCTAssertEqual("applepay", payload["pay_var"] as? String)
    }
}

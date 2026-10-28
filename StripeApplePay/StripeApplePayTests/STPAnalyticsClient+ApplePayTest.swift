//
//  STPAnalyticsClient+ApplePayTest.swift
//  StripeApplePayTests
//
//  Created by David Estes on 2/3/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import XCTest

// swift-format-ignore
@_spi(InternalOnlyAPI) @testable import StripeApplePay

// swift-format-ignore
@_spi(InternalOnlyAPI) @testable import StripeCore

class STPAnalyticsClientApplePayTest: XCTestCase {
    func testApplePaySDKVariantPayload() throws {
        // setup
        let analytic = PaymentAPIAnalytic(
            event: .paymentMethodCreation,
            additionalParams: [:]
        )
        let client = STPAnalyticsClient()
        let payload = client.payload(from: analytic)
        XCTAssertEqual("applepay", payload["pay_var"] as? String)
    }
}

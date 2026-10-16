//
//  STPPaymentMethodTouchNGoTest.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 9/16/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
import XCTest

final class STPPaymentMethodTouchNGoTest: XCTestCase {
    func testParamsEncoding() {
        let params = STPPaymentMethodParams(
            touchNGo: STPPaymentMethodTouchNGoParams(),
            billingDetails: nil,
            metadata: nil
        )

        let encoded = STPFormEncoder.dictionary(forObject: params)

        XCTAssertEqual(encoded["type"] as? String, "touch_n_go")
    }

    func testDecoding() {
        let paymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_touch_n_go",
            "created": 1_725_000_000,
            "type": "touch_n_go",
            "touch_n_go": [:],
        ])

        XCTAssertEqual(paymentMethod?.type, .touchNGo)
        XCTAssertNotNil(paymentMethod?.touchNGo)
    }

    func testTypeInitializerCreatesTouchNGoParams() {
        let params = STPPaymentMethodParams(type: .touchNGo)

        XCTAssertNotNil(params.touchNGo)
    }
}

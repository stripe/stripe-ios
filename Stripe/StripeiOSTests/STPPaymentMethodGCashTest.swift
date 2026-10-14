//
//  STPPaymentMethodGCashTest.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 9/16/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
import XCTest

final class STPPaymentMethodGCashTest: XCTestCase {
    func testParamsEncoding() {
        let params = STPPaymentMethodParams(
            gcash: STPPaymentMethodGCashParams(),
            billingDetails: nil,
            metadata: nil
        )

        let encoded = STPFormEncoder.dictionary(forObject: params)

        XCTAssertEqual(encoded["type"] as? String, "gcash")
    }

    func testDecoding() {
        let paymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_gcash",
            "created": 1_725_000_000,
            "type": "gcash",
            "gcash": [:],
        ])

        XCTAssertEqual(paymentMethod?.type, .gcash)
        XCTAssertNotNil(paymentMethod?.gcash)
    }

    func testTypeInitializerCreatesGCashParams() {
        let params = STPPaymentMethodParams(type: .gcash)

        XCTAssertNotNil(params.gcash)
    }
}

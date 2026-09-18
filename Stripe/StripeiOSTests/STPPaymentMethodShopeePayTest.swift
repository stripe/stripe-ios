//
//  STPPaymentMethodShopeePayTest.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 9/16/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
import XCTest

final class STPPaymentMethodShopeePayTest: XCTestCase {
    func testParamsEncoding() {
        let params = STPPaymentMethodParams(
            shopeePay: STPPaymentMethodShopeePayParams(),
            billingDetails: nil,
            metadata: nil
        )

        let encoded = STPFormEncoder.dictionary(forObject: params)

        XCTAssertEqual(encoded["type"] as? String, "shopeepay")
    }

    func testDecoding() {
        let paymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_shopeepay",
            "created": 1_725_000_000,
            "type": "shopeepay",
            "shopeepay": [:],
        ])

        XCTAssertEqual(paymentMethod?.type, .shopeePay)
        XCTAssertNotNil(paymentMethod?.shopeePay)
    }

    func testTypeInitializerCreatesShopeePayParams() {
        let params = STPPaymentMethodParams(type: .shopeePay)

        XCTAssertNotNil(params.shopeePay)
    }
}

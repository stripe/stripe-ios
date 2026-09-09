//
//  STPPaymentMethodPaycoTest.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 8/27/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
import XCTest

final class STPPaymentMethodPaycoTest: XCTestCase {
    func testParamsEncoding() {
        let params = STPPaymentMethodParams(
            payco: STPPaymentMethodPaycoParams(),
            billingDetails: nil,
            metadata: nil
        )

        let encoded = STPFormEncoder.dictionary(forObject: params)

        XCTAssertEqual(encoded["type"] as? String, "payco")
    }

    func testDecoding() {
        let paymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_payco",
            "created": 1_725_000_000,
            "type": "payco",
            "payco": [:],
        ])

        XCTAssertEqual(paymentMethod?.type, .payco)
        XCTAssertNotNil(paymentMethod?.payco)
    }

    func testTypeInitializerCreatesPaycoParams() {
        let params = STPPaymentMethodParams(type: .payco)

        XCTAssertNotNil(params.payco)
    }
}

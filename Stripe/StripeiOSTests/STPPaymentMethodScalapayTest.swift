//
//  STPPaymentMethodScalapayTest.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 9/8/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
import XCTest

final class STPPaymentMethodScalapayTest: XCTestCase {
    func testParamsEncoding() {
        let params = STPPaymentMethodParams(
            scalapay: STPPaymentMethodScalapayParams(),
            billingDetails: nil,
            metadata: nil
        )

        let encoded = STPFormEncoder.dictionary(forObject: params)

        XCTAssertEqual(encoded["type"] as? String, "scalapay")
    }

    func testDecoding() {
        let paymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_scalapay",
            "created": 1_725_000_000,
            "type": "scalapay",
            "scalapay": [:],
        ])

        XCTAssertEqual(paymentMethod?.type, .scalapay)
        XCTAssertNotNil(paymentMethod?.scalapay)
    }

    func testTypeInitializerCreatesScalapayParams() {
        let params = STPPaymentMethodParams(type: .scalapay)

        XCTAssertNotNil(params.scalapay)
    }
}

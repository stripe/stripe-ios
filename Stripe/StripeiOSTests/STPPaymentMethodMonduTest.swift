//
//  STPPaymentMethodMonduTest.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 9/16/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
import XCTest

final class STPPaymentMethodMonduTest: XCTestCase {
    func testParamsEncoding() {
        let params = STPPaymentMethodParams(
            mondu: STPPaymentMethodMonduParams(),
            billingDetails: nil,
            metadata: nil
        )

        let encoded = STPFormEncoder.dictionary(forObject: params)

        XCTAssertEqual(encoded["type"] as? String, "mondu")
    }

    func testDecoding() {
        let paymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_mondu",
            "created": 1_725_000_000,
            "type": "mondu",
            "mondu": [:],
        ])

        XCTAssertEqual(paymentMethod?.type, .mondu)
        XCTAssertNotNil(paymentMethod?.mondu)
    }

    func testTypeInitializerCreatesMonduParams() {
        let params = STPPaymentMethodParams(type: .mondu)

        XCTAssertNotNil(params.mondu)
    }
}

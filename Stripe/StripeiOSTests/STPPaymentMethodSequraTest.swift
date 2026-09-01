//
//  STPPaymentMethodSequraTest.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 8/28/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
import XCTest

final class STPPaymentMethodSequraTest: XCTestCase {
    func testParamsEncoding() {
        let params = STPPaymentMethodParams(
            sequra: STPPaymentMethodSequraParams(),
            billingDetails: nil,
            metadata: nil
        )

        let encoded = STPFormEncoder.dictionary(forObject: params)

        XCTAssertEqual(encoded["type"] as? String, "sequra")
    }

    func testDecoding() {
        let paymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_sequra",
            "created": 1_725_000_000,
            "type": "sequra",
            "sequra": [:],
        ])

        XCTAssertEqual(paymentMethod?.type, .sequra)
        XCTAssertNotNil(paymentMethod?.sequra)
    }

    func testTypeInitializerCreatesSequraParams() {
        let params = STPPaymentMethodParams(type: .sequra)

        XCTAssertNotNil(params.sequra)
    }
}

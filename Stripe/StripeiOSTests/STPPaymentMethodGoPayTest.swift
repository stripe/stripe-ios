//
//  STPPaymentMethodGoPayTest.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 9/16/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
import XCTest

final class STPPaymentMethodGoPayTest: XCTestCase {
    func testParamsEncoding() {
        let params = STPPaymentMethodParams(
            goPay: STPPaymentMethodGoPayParams(),
            billingDetails: nil,
            metadata: nil
        )

        let encoded = STPFormEncoder.dictionary(forObject: params)

        XCTAssertEqual(encoded["type"] as? String, "gopay")
    }

    func testDecoding() {
        let paymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_gopay",
            "created": 1_725_000_000,
            "type": "gopay",
            "gopay": [:],
        ])

        XCTAssertEqual(paymentMethod?.type, .goPay)
        XCTAssertNotNil(paymentMethod?.goPay)
    }

    func testTypeInitializerCreatesGoPayParams() {
        let params = STPPaymentMethodParams(type: .goPay)

        XCTAssertNotNil(params.goPay)
    }
}

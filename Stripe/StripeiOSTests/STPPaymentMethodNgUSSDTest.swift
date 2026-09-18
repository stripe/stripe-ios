//
//  STPPaymentMethodNgUSSDTest.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 9/16/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
import XCTest

final class STPPaymentMethodNgUSSDTest: XCTestCase {
    func testParamsEncoding() {
        let params = STPPaymentMethodParams(
            ngUSSD: STPPaymentMethodNgUSSDParams(),
            billingDetails: nil,
            metadata: nil
        )

        let encoded = STPFormEncoder.dictionary(forObject: params)

        XCTAssertEqual(encoded["type"] as? String, "ng_ussd")
    }

    func testDecoding() {
        let paymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_ng_ussd",
            "created": 1_725_000_000,
            "type": "ng_ussd",
            "ng_ussd": [:],
        ])

        XCTAssertEqual(paymentMethod?.type, .ngUSSD)
        XCTAssertNotNil(paymentMethod?.ngUSSD)
    }

    func testTypeInitializerCreatesNgUSSDParams() {
        let params = STPPaymentMethodParams(type: .ngUSSD)

        XCTAssertNotNil(params.ngUSSD)
    }
}

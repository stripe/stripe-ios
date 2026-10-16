//
//  STPPaymentMethodTrueMoneyTest.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 9/16/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
import XCTest

final class STPPaymentMethodTrueMoneyTest: XCTestCase {
    func testParamsEncoding() {
        let params = STPPaymentMethodParams(
            trueMoney: STPPaymentMethodTrueMoneyParams(),
            billingDetails: nil,
            metadata: nil
        )

        let encoded = STPFormEncoder.dictionary(forObject: params)

        XCTAssertEqual(encoded["type"] as? String, "truemoney")
    }

    func testDecoding() {
        let paymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_truemoney",
            "created": 1_725_000_000,
            "type": "truemoney",
            "truemoney": [:],
        ])

        XCTAssertEqual(paymentMethod?.type, .trueMoney)
        XCTAssertNotNil(paymentMethod?.trueMoney)
    }

    func testTypeInitializerCreatesTrueMoneyParams() {
        let params = STPPaymentMethodParams(type: .trueMoney)

        XCTAssertNotNil(params.trueMoney)
    }
}

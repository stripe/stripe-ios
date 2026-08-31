//
//  STPPaymentMethodKakaoPayTest.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 8/27/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
import XCTest

final class STPPaymentMethodKakaoPayTest: XCTestCase {
    func testParamsEncoding() {
        let params = STPPaymentMethodParams(
            kakaoPay: STPPaymentMethodKakaoPayParams(),
            billingDetails: nil,
            metadata: nil
        )

        let encoded = STPFormEncoder.dictionary(forObject: params)

        XCTAssertEqual(encoded["type"] as? String, "kakao_pay")
    }

    func testDecoding() {
        let paymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_kakao_pay",
            "created": 1_725_000_000,
            "type": "kakao_pay",
            "kakao_pay": [:],
        ])

        XCTAssertEqual(paymentMethod?.type, .kakaoPay)
        XCTAssertNotNil(paymentMethod?.kakaoPay)
    }

    func testTypeInitializerCreatesKakaoPayParams() {
        let params = STPPaymentMethodParams(type: .kakaoPay)

        XCTAssertNotNil(params.kakaoPay)
    }
}

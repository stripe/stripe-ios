//
//  STPPaymentMethodNaverPayTest.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 8/27/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
import XCTest

final class STPPaymentMethodNaverPayTest: XCTestCase {
    func testParamsEncoding() {
        let naverPay = STPPaymentMethodNaverPayParams()
        naverPay.funding = .points
        let params = STPPaymentMethodParams(
            naverPay: naverPay,
            billingDetails: nil,
            metadata: nil
        )

        let encoded = STPFormEncoder.dictionary(forObject: params)

        XCTAssertEqual(encoded["type"] as? String, "naver_pay")
        XCTAssertEqual(encoded["naver_pay"] as? [String: String], ["funding": "points"])
    }

    func testDecoding() {
        let paymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_naver_pay",
            "created": 1_725_000_000,
            "type": "naver_pay",
            "naver_pay": [
                "buyer_id": "buyer_123",
                "funding": "card",
            ],
        ])

        XCTAssertEqual(paymentMethod?.type, .naverPay)
        XCTAssertEqual(paymentMethod?.naverPay?.buyerId, "buyer_123")
        XCTAssertEqual(paymentMethod?.naverPay?.funding, .card)
    }

    func testDecodingPreservesUnknownFundingSource() {
        let naverPay = STPPaymentMethodNaverPay.decodedObject(fromAPIResponse: [
            "buyer_id": NSNull(),
            "funding": "new_funding_source",
        ])

        XCTAssertNotNil(naverPay)
        XCTAssertNil(naverPay?.buyerId)
        XCTAssertEqual(naverPay?.funding, .unknown)
        XCTAssertEqual(naverPay?.allResponseFields["funding"] as? String, "new_funding_source")
    }

    func testTypeInitializerCreatesNaverPayParams() {
        let params = STPPaymentMethodParams(type: .naverPay)

        XCTAssertNotNil(params.naverPay)
    }
}

//
//  STPPaymentMethodKrCardTest.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 8/27/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
import XCTest

final class STPPaymentMethodKrCardTest: XCTestCase {
    func testParamsEncoding() {
        let params = STPPaymentMethodParams(
            krCard: STPPaymentMethodKrCardParams(),
            billingDetails: nil,
            metadata: nil
        )

        let encoded = STPFormEncoder.dictionary(forObject: params)

        XCTAssertEqual(encoded["type"] as? String, "kr_card")
        XCTAssertEqual(encoded["kr_card"] as? [String: String], [:])
    }

    func testDecoding() {
        let paymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_kr_card",
            "created": 1_725_000_000,
            "type": "kr_card",
            "kr_card": [
                "brand": "shinhan",
                "last4": "4242",
            ],
        ])

        XCTAssertEqual(paymentMethod?.type, .krCard)
        XCTAssertEqual(paymentMethod?.krCard?.brand, .shinhan)
        XCTAssertEqual(paymentMethod?.krCard?.last4, "4242")
    }

    func testDecodingPreservesUnknownBrand() {
        let krCard = STPPaymentMethodKrCard.decodedObject(fromAPIResponse: [
            "brand": "new_brand",
            "last4": NSNull(),
        ])

        XCTAssertNotNil(krCard)
        XCTAssertEqual(krCard?.brand, .unknown)
        XCTAssertNil(krCard?.last4)
        XCTAssertEqual(krCard?.allResponseFields["brand"] as? String, "new_brand")
    }

    func testTypeInitializerCreatesKrCardParams() {
        let params = STPPaymentMethodParams(type: .krCard)

        XCTAssertNotNil(params.krCard)
    }
}

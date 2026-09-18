//
//  STPPaymentMethodNgCardTest.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 9/16/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
import XCTest

final class STPPaymentMethodNgCardTest: XCTestCase {
    func testParamsEncoding() {
        let params = STPPaymentMethodParams(
            ngCard: STPPaymentMethodNgCardParams(),
            billingDetails: nil,
            metadata: nil
        )

        let encoded = STPFormEncoder.dictionary(forObject: params)

        XCTAssertEqual(encoded["type"] as? String, "ng_card")
    }

    func testDecoding() {
        let paymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_ng_card",
            "created": 1_725_000_000,
            "type": "ng_card",
            "ng_card": [:],
        ])

        XCTAssertEqual(paymentMethod?.type, .ngCard)
        XCTAssertNotNil(paymentMethod?.ngCard)
    }

    func testTypeInitializerCreatesNgCardParams() {
        let params = STPPaymentMethodParams(type: .ngCard)

        XCTAssertNotNil(params.ngCard)
    }

    func testDecodesLocalCardDetails() {
        // Given each brand returned by the Naira card API
        let brands: [String: STPPaymentMethodNgCardBrand] = [
            "amex": .amex, "mastercard": .mastercard, "verve": .verve, "visa": .visa,
        ]
        for (value, expected) in brands {
            // When the card details are decoded
            let card = STPPaymentMethodNgCard.decodedObject(fromAPIResponse: ["brand": value, "last4": "1234"])

            // Then both the local brand and last four digits are preserved
            XCTAssertEqual(card?.brand, expected)
            XCTAssertEqual(card?.brand.stringValue, value)
            XCTAssertEqual(card?.last4, "1234")
        }
    }

    func testDecodesUnknownAndMissingCardDetails() {
        // Given an unrecognized brand and an absent card number
        let card = STPPaymentMethodNgCard.decodedObject(fromAPIResponse: ["brand": "future_brand", "last4": NSNull()])

        // Then unknown values are handled without losing the response
        XCTAssertEqual(card?.brand, .unknown)
        XCTAssertNil(card?.last4)
        XCTAssertEqual(card?.allResponseFields["brand"] as? String, "future_brand")
        XCTAssertNil(STPPaymentMethodNgCard.decodedObject(fromAPIResponse: nil))
        XCTAssertEqual(STPPaymentMethodNgCard.decodedObject(fromAPIResponse: [:])?.brand, .unknown)
    }
}

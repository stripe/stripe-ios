//
//  STPCheckoutSessionLineItemAndShippingTest.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 3/3/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
import StripePaymentsObjcTestUtils
import XCTest

class STPCheckoutSessionLineItemAndShippingTest: XCTestCase {

    // MARK: - Line Item Tests

    func testDecodedObjectLineItemsParsing() {
        let json = STPTestUtils.jsonNamed("CheckoutSession")!
        let session = STPCheckoutSessionAPIResponse.decodedObject(fromAPIResponse: json)!

        XCTAssertEqual(session.lineItems.count, 2)

        let first = session.lineItems[0]
        XCTAssertEqual(first.id, "li_1abc")
        XCTAssertEqual(first.name, "Widget")
        XCTAssertEqual(first.quantity, 2)
        XCTAssertEqual(first.unitAmount?.minorUnitsAmount, 750)

        let second = session.lineItems[1]
        XCTAssertEqual(second.id, "li_2def")
        XCTAssertEqual(second.name, "Gadget")
        XCTAssertEqual(second.quantity, 1)
        XCTAssertEqual(second.unitAmount?.minorUnitsAmount, 500)
    }

    func testDecodedObjectWithNoLineItems() {
        let json: [String: Any] = [
            "session_id": "cs_test_no_items",
            "object": "checkout.session",
            "livemode": false,
            "mode": "payment",
            "payment_status": "unpaid",
            "payment_method_types": ["card"],
            "elements_session": [
                "session_id": "es_test",
                "payment_method_preference": ["ordered_payment_method_types": ["card"]],
            ],
        ]

        let session = STPCheckoutSessionAPIResponse.decodedObject(fromAPIResponse: json)
        XCTAssertNotNil(session)
        XCTAssertEqual(session?.lineItems.count, 0)
    }

    // MARK: - Shipping Option Tests

    func testDecodedObjectShippingOptionsParsing() {
        let json = STPTestUtils.jsonNamed("CheckoutSession")!
        let session = STPCheckoutSessionAPIResponse.decodedObject(fromAPIResponse: json)!

        XCTAssertEqual(session.shippingOptions.count, 2)

        let standard = session.shippingOptions[0]
        XCTAssertEqual(standard.id, "shr_standard")
        XCTAssertEqual(standard.displayName, "Standard Shipping")
        XCTAssertEqual(standard.amount.minorUnitsAmount, 500)
        XCTAssertEqual(standard.currency, "usd")

        let express = session.shippingOptions[1]
        XCTAssertEqual(express.id, "shr_express")
        XCTAssertEqual(express.displayName, "Express Shipping")
        XCTAssertEqual(express.amount.minorUnitsAmount, 1500)
        XCTAssertEqual(express.currency, "usd")
    }

    func testDecodedObjectWithNoShippingOptions() {
        let json: [String: Any] = [
            "session_id": "cs_test_no_shipping",
            "object": "checkout.session",
            "livemode": false,
            "mode": "payment",
            "payment_status": "unpaid",
            "payment_method_types": ["card"],
            "elements_session": [
                "session_id": "es_test",
                "payment_method_preference": ["ordered_payment_method_types": ["card"]],
            ],
        ]

        let session = STPCheckoutSessionAPIResponse.decodedObject(fromAPIResponse: json)
        XCTAssertNotNil(session)
        XCTAssertEqual(session?.shippingOptions.count, 0)
    }

}

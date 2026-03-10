//
//  STPCheckoutSessionLineItemAndShippingTest.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 3/3/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) @_spi(CheckoutSessionsPreview) import StripePaymentSheet
import StripePaymentsObjcTestUtils
import XCTest

class STPCheckoutSessionLineItemAndShippingTest: XCTestCase {

    // MARK: - Line Item Tests

    func testDecodedObjectLineItemsParsing() {
        let json = STPTestUtils.jsonNamed("CheckoutSession")!
        let session = STPCheckoutSession.decodedObject(fromAPIResponse: json)!

        XCTAssertEqual(session.lineItems.count, 2)

        let first = session.lineItems[0]
        XCTAssertEqual(first.id, "li_1abc")
        XCTAssertEqual(first.name, "Widget")
        XCTAssertEqual(first.quantity, 2)
        XCTAssertEqual(first.unitAmount, 750)
        XCTAssertEqual(first.currency, "usd")

        let second = session.lineItems[1]
        XCTAssertEqual(second.id, "li_2def")
        XCTAssertEqual(second.name, "Gadget")
        XCTAssertEqual(second.quantity, 1)
        XCTAssertEqual(second.unitAmount, 500)
        XCTAssertEqual(second.currency, "usd")
    }

    func testDecodedObjectWithNoLineItems() {
        let json: [String: Any] = [
            "session_id": "cs_test_no_items",
            "object": "checkout.session",
            "livemode": false,
            "mode": "payment",
            "payment_status": "unpaid",
            "payment_method_types": ["card"],
        ]

        let session = STPCheckoutSession.decodedObject(fromAPIResponse: json)
        XCTAssertNotNil(session)
        XCTAssertEqual(session?.lineItems.count, 0)
    }

    // MARK: - Shipping Option Tests

    func testDecodedObjectShippingOptionsParsing() {
        let json = STPTestUtils.jsonNamed("CheckoutSession")!
        let session = STPCheckoutSession.decodedObject(fromAPIResponse: json)!

        XCTAssertEqual(session.shippingOptions.count, 2)

        let standard = session.shippingOptions[0]
        XCTAssertEqual(standard.id, "shr_standard")
        XCTAssertEqual(standard.displayName, "Standard Shipping")
        XCTAssertEqual(standard.amount, 500)
        XCTAssertEqual(standard.currency, "usd")

        let express = session.shippingOptions[1]
        XCTAssertEqual(express.id, "shr_express")
        XCTAssertEqual(express.displayName, "Express Shipping")
        XCTAssertEqual(express.amount, 1500)
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
        ]

        let session = STPCheckoutSession.decodedObject(fromAPIResponse: json)
        XCTAssertNotNil(session)
        XCTAssertEqual(session?.shippingOptions.count, 0)
    }

    func testDecodedObjectSelectedShippingOption() {
        let json = STPTestUtils.jsonNamed("CheckoutSession")!
        let session = STPCheckoutSession.decodedObject(fromAPIResponse: json)!

        XCTAssertEqual(session.selectedShippingOptionId, "shr_standard")
        XCTAssertEqual(session.totals?.shipping, 500)
    }

    func testSelectedShippingOptionProtocolProperty() {
        let json = STPTestUtils.jsonNamed("CheckoutSession")!
        let session: Checkout.Session = STPCheckoutSession.decodedObject(fromAPIResponse: json)!

        let selected = session.selectedShippingOption
        XCTAssertNotNil(selected)
        XCTAssertEqual(selected?.id, "shr_standard")
        XCTAssertEqual(selected?.displayName, "Standard Shipping")
        XCTAssertEqual(selected?.amount, 500)
        XCTAssertEqual(selected?.currency, "usd")
    }

    func testSelectedShippingOptionNilWhenNoSelection() {
        let json: [String: Any] = [
            "session_id": "cs_test_no_selection",
            "object": "checkout.session",
            "livemode": false,
            "mode": "payment",
            "payment_status": "unpaid",
            "payment_method_types": ["card"],
            "shipping_options": [
                [
                    "shipping_rate": [
                        "id": "shr_standard",
                        "display_name": "Standard Shipping",
                        "amount": 500,
                        "currency": "usd",
                    ],
                ],
            ],
        ]

        let session: Checkout.Session = STPCheckoutSession.decodedObject(fromAPIResponse: json)!
        XCTAssertNil(session.selectedShippingOption)
    }

}

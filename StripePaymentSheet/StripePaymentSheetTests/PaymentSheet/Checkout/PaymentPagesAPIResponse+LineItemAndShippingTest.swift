//
//  PaymentPagesAPIResponse+LineItemAndShippingTest.swift
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
        let session = PaymentPagesAPIResponse.decodedObject(fromAPIResponse: json)!

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
        let session = CheckoutTestHelpers.makeSession()

        XCTAssertEqual(session.lineItems.count, 0)
    }

    // MARK: - Shipping Option Tests

    func testDecodedObjectShippingOptionsParsing() {
        let json = STPTestUtils.jsonNamed("CheckoutSession")!
        let session = PaymentPagesAPIResponse.decodedObject(fromAPIResponse: json)!

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
        let session = CheckoutTestHelpers.makeSession()

        XCTAssertEqual(session.shippingOptions.count, 0)
    }

}

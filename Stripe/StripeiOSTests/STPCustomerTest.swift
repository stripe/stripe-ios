//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
import Foundation
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI
//
//  STPCustomerTest.swift
//  Stripe
//
//  Created by Ben Guo on 7/14/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

class STPCustomerTest: XCTestCase {
    func testDecoding_invalidJSON() {
        let sut = STPCustomer.decodedObject(fromAPIResponse: [:])
        XCTAssertNil(Int(sut ?? 0))
    }

    func testDecoding_validJSON() {
        var card1 = STPTestUtils.jsonNamed("Card")
        card1?["id"] = "card_123"

        var card2 = STPTestUtils.jsonNamed("Card")
        card2?["id"] = "card_456"

        var applePayCard1 = STPTestUtils.jsonNamed("Card")
        applePayCard1?["id"] = "card_apple_pay1"
        applePayCard1?["tokenization_method"] = "apple_pay"

        var applePayCard2 = applePayCard1
        applePayCard2?["id"] = "card_apple_pay2"

        let cardSource = STPTestUtils.jsonNamed("CardSource")
        let threeDSSource = STPTestUtils.jsonNamed("3DSSource")

        var customer = STPTestUtils.jsonNamed("Customer")
        var sources = customer?["sources"] as? [AnyHashable : Any]
        sources?["data"] = [applePayCard1, card1, applePayCard2, card2, cardSource, threeDSSource]
        customer?["default_source"] = card1?["id"]
        customer?["sources"] = sources

        let sut = STPCustomer.decodedObject(fromAPIResponse: customer)
        XCTAssertNotNil(Int(sut ?? 0))
        XCTAssertEqual(sut?.stripeID, customer?["id"])
        XCTAssertTrue(sut?.sources.count == 4)
        XCTAssertEqual(sut?.sources[0].stripeID, card1?["id"])
        XCTAssertEqual(sut?.sources[1].stripeID, card2?["id"])
        XCTAssertEqual(sut?.defaultSource.stripeID, card1?["id"])
        XCTAssertEqual(sut?.sources[2].stripeID, cardSource?["id"])
        XCTAssertEqual(sut?.sources[3].stripeID, threeDSSource?["id"])

        XCTAssertEqual(sut?.shippingAddress.name, customer?["shipping"]["name"])
        XCTAssertEqual(sut?.shippingAddress.phone, customer?["shipping"]["phone"])
        XCTAssertEqual(sut?.shippingAddress.city, customer?["shipping"]["address"]["city"])
        XCTAssertEqual(sut?.shippingAddress.country, customer?["shipping"]["address"]["country"])
        XCTAssertEqual(sut?.shippingAddress.line1, customer?["shipping"]["address"]["line1"])
        XCTAssertEqual(sut?.shippingAddress.line2, customer?["shipping"]["address"]["line2"])
        XCTAssertEqual(sut?.shippingAddress.postalCode, customer?["shipping"]["address"]["postal_code"])
        XCTAssertEqual(sut?.shippingAddress.state, customer?["shipping"]["address"]["state"])
    }
}

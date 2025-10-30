//
//  STPSourceParamsTest.swift
//  StripeiOS Tests
//
//  Created by Ben Guo on 1/25/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPSourceParamsTest: XCTestCase {
    // MARK: -
    func testInit() {
        let sourceParams = STPSourceParams()
        XCTAssertEqual(sourceParams.rawTypeString, "")
        XCTAssertEqual(sourceParams.usage, .unknown)
        XCTAssertEqual(sourceParams.additionalAPIParameters as NSDictionary, [:] as NSDictionary)
    }

    func testType() {
        let sourceParams = STPSourceParams()
        XCTAssertEqual(sourceParams.type, .unknown)

        sourceParams.rawTypeString = "card"
        XCTAssertEqual(sourceParams.type, .card)

        sourceParams.rawTypeString = "three_d_secure"
        XCTAssertEqual(sourceParams.type, .threeDSecure)

        sourceParams.rawTypeString = "unknown"
        XCTAssertEqual(sourceParams.type, .unknown)

        sourceParams.rawTypeString = "garbage"
        XCTAssertEqual(sourceParams.type, .unknown)
    }

    func testSetType() {
        let sourceParams = STPSourceParams()
        XCTAssertEqual(sourceParams.type, .unknown)

        sourceParams.type = .card
        XCTAssertEqual(sourceParams.rawTypeString, "card")

        sourceParams.type = .threeDSecure
        XCTAssertEqual(sourceParams.rawTypeString, "three_d_secure")

        sourceParams.type = .unknown
        XCTAssertNil(sourceParams.rawTypeString)
    }

    func testSetTypePreserveUnknownRawTypeString() {
        let sourceParams = STPSourceParams()
        sourceParams.rawTypeString = "money"
        sourceParams.type = .unknown
        XCTAssertEqual(sourceParams.rawTypeString, "money")
    }

    func testRawTypeString() {
        let sourceParams = STPSourceParams()

        // Check defaults to unknown
        XCTAssertEqual(sourceParams.type, .unknown)

        // Check changing type sets rawTypeString
        sourceParams.type = .card
        XCTAssertEqual(sourceParams.rawTypeString, STPSource.string(from: .card))

        // Check changing to unknown raw string sets type to unknown
        sourceParams.rawTypeString = "new_source_type"
        XCTAssertEqual(sourceParams.type, .unknown)

        // Check once unknown that setting type to unknown doesnt clobber string
        sourceParams.type = .unknown
        XCTAssertEqual(sourceParams.rawTypeString, "new_source_type")

        // Check setting string to known type sets type correctly
        sourceParams.rawTypeString = STPSource.string(from: .card)
        XCTAssertEqual(sourceParams.type, .card)
    }

    // MARK: - Constructors Tests
    func testCardParamsWithCard() {
        let card = STPCardParams()
        card.number = "4242 4242 4242 4242"
        card.cvc = "123"
        card.expMonth = 6
        card.expYear = 2024
        card.currency = "usd"
        card.name = "Jenny Rosen"
        card.address.line1 = "123 Fake Street"
        card.address.line2 = "Apartment 4"
        card.address.city = "New York"
        card.address.state = "NY"
        card.address.country = "USA"
        card.address.postalCode = "10002"

        let source = STPSourceParams.cardParams(withCard: card)
        let sourceCard = source.additionalAPIParameters["card"] as! [String: AnyHashable]
        XCTAssertEqual(sourceCard["number"], card.number)
        XCTAssertEqual(sourceCard["cvc"], card.cvc)
        XCTAssertEqual(sourceCard["exp_month"], NSNumber(value: card.expMonth))
        XCTAssertEqual(sourceCard["exp_year"], NSNumber(value: card.expYear))
        XCTAssertEqual(source.owner!["name"] as? String, card.name)
        let sourceAddress = source.owner!["address"] as! [AnyHashable: Any]
        XCTAssertEqual(sourceAddress["line1"] as? String, card.address.line1)
        XCTAssertEqual(sourceAddress["line2"] as? String, card.address.line2)
        XCTAssertEqual(sourceAddress["city"] as? String, card.address.city)
        XCTAssertEqual(sourceAddress["state"] as? String, card.address.state)
        XCTAssertEqual(sourceAddress["postal_code"] as? String, card.address.postalCode)
        XCTAssertEqual(sourceAddress["country"] as? String, card.address.country)
    }

    func testParamsWithVisaCheckout() {
        let params = STPSourceParams.visaCheckoutParams(withCallId: "12345678")

        XCTAssertEqual(params.type, .card)
        let sourceCard = params.additionalAPIParameters["card"] as? [AnyHashable: Any]
        XCTAssertNotNil(sourceCard)
        let sourceVisaCheckout = sourceCard!["visa_checkout"] as? [AnyHashable: Any]
        XCTAssertNotNil(sourceVisaCheckout)
        XCTAssertEqual(sourceVisaCheckout!["callid"] as! String, "12345678")
    }

    func testParamsWithMasterPass() {
        let params = STPSourceParams.masterpassParams(
            withCartId: "12345678",
            transactionId: "87654321"
        )

        XCTAssertEqual(params.type, .card)
        let sourceCard = params.additionalAPIParameters["card"] as? [AnyHashable: Any]
        XCTAssertNotNil(sourceCard)
        let sourceMasterpass = sourceCard!["masterpass"] as? [AnyHashable: Any]
        XCTAssertNotNil(sourceMasterpass)
        XCTAssertEqual(sourceMasterpass!["cart_id"] as! String, "12345678")
        XCTAssertEqual(sourceMasterpass!["transaction_id"] as! String, "87654321")
    }

    // MARK: - STPFormEncodable Tests
    func testRootObjectName() {
        XCTAssertNil(STPSourceParams.rootObjectName())
    }

    func testPropertyNamesToFormFieldNamesMapping() {
        let sourceParams = STPSourceParams()

        let mapping = STPSourceParams.propertyNamesToFormFieldNamesMapping()

        for propertyName in mapping.keys {
            XCTAssertFalse(propertyName.contains(":"))
            XCTAssert(sourceParams.responds(to: NSSelectorFromString(propertyName)))
        }

        for formFieldName in mapping.values {
            XCTAssert(formFieldName.count > 0)
        }

        XCTAssertEqual(mapping.values.count, Set<String>(mapping.values).count)
    }
}

//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPCardParamsTest.m
//  Stripe
//
//  Created by Joey Dong on 6/19/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import StripePayments
import StripePaymentsTestUtils
import XCTest

class STPCardParamsTest: XCTestCase {
    // MARK: -

    func testLast4ReturnsCardNumberLast4() {
        let cardParams = STPCardParams()
        cardParams.number = "4242424242424242"
        XCTAssertEqual(cardParams.last4(), "4242")
    }

    func testLast4ReturnsNilWhenNoCardNumberSet() {
        let cardParams = STPCardParams()
        XCTAssertNil(cardParams.last4())
    }

    func testLast4ReturnsNilWhenCardNumberIsLessThanLength4() {
        let cardParams = STPCardParams()
        cardParams.number = "123"
        XCTAssertNil(cardParams.last4())
    }

    func testNameSharedWithAddress() {
        let cardParams = STPCardParams()

        cardParams.name = "James"
        XCTAssertEqual(cardParams.name, "James")
        XCTAssertEqual(cardParams.address.name, "James")

        let address = STPAddress()
        address.name = "Jim"

        cardParams.address = address
        XCTAssertEqual(cardParams.name, "Jim")
        XCTAssertEqual(cardParams.address.name, "Jim")

        // Doesn't update `name`, since mutation invisible to the STPCardParams
        cardParams.address.name = "Smith"
        XCTAssertEqual(cardParams.name, "Jim")
        XCTAssertEqual(cardParams.address.name, "Smith")
    }

    // #pragma clang diagnostic push
    // #pragma clang diagnostic ignored "-Wdeprecated"

    func testAddress() {
        let cardParams = STPCardParams()
        cardParams.name = "John Smith"
        cardParams.addressLine1 = "55 John St"
        cardParams.addressLine2 = "#3B"
        cardParams.addressCity = "New York"
        cardParams.addressState = "NY"
        cardParams.addressZip = "10002"
        cardParams.addressCountry = "US"

        let address = cardParams.address

        XCTAssertEqual(address.name, "John Smith")
        XCTAssertEqual(address.line1, "55 John St")
        XCTAssertEqual(address.line2, "#3B")
        XCTAssertEqual(address.city, "New York")
        XCTAssertEqual(address.state, "NY")
        XCTAssertEqual(address.postalCode, "10002")
        XCTAssertEqual(address.country, "US")
    }

    func testSetAddress() {
        let address = STPAddress()
        address.name = "John Smith"
        address.line1 = "55 John St"
        address.line2 = "#3B"
        address.city = "New York"
        address.state = "NY"
        address.postalCode = "10002"
        address.country = "US"

        let cardParams = STPCardParams()
        cardParams.address = address

        XCTAssertEqual(cardParams.name, "John Smith")
        XCTAssertEqual(cardParams.addressLine1, "55 John St")
        XCTAssertEqual(cardParams.addressLine2, "#3B")
        XCTAssertEqual(cardParams.addressCity, "New York")
        XCTAssertEqual(cardParams.addressState, "NY")
        XCTAssertEqual(cardParams.addressZip, "10002")
        XCTAssertEqual(cardParams.addressCountry, "US")
    }

    // #pragma clang diagnostic pop

    // MARK: - Description Tests

    func testDescription() {
        let cardParams = STPCardParams()
        XCTAssertNotNil(cardParams.description)
    }

    // MARK: - STPFormEncodable Tests

    func testRootObjectName() {
        XCTAssertEqual(STPCardParams.rootObjectName(), "card")
    }

    func testPropertyNamesToFormFieldNamesMapping() {
        let cardParams = STPCardParams()

        let mapping = STPCardParams.propertyNamesToFormFieldNamesMapping()

        for keyPath in mapping.keys {
            XCTAssertNotNil((cardParams as Any)[keyPath: keyPath], "\(keyPath) does not apply to \(type(of: cardParams))")
        }

        for formFieldName in mapping.values {
            XCTAssert(!formFieldName.isEmpty)
        }

        XCTAssertEqual(mapping.values.count, Set(mapping.values).count)
    }

    // MARK: - NSCopying Tests

    func testCopyWithZone() {
        let cardParams = STPFixtures.cardParams()
        cardParams.address = STPFixtures.address()
        let copiedCardParams = cardParams.copy() as! STPCardParams

        // STPAddress does not override isEqual:, and its description includes its address, so compare it separately
        XCTAssertFalse(cardParams.address === copiedCardParams.address)
        XCTAssertEqual(
            STPTestUtils.storedPropertyDescriptions(of: cardParams.address),
            STPTestUtils.storedPropertyDescriptions(of: copiedCardParams.address)
        )

        // Use reflection to find the list of stored properties. If a new property is
        // added to the fixture, but not the `copy(with:)` implementation, this should catch it
        let copiedValues = STPTestUtils.storedPropertyDescriptions(of: copiedCardParams)
        for (property, value) in STPTestUtils.storedPropertyDescriptions(of: cardParams) where !(value.contains("STPAddress")) {
            XCTAssertEqual(value, copiedValues[property], property)
        }
    }

    func testAddressIsNotCopied() {
        let cardParams = STPFixtures.cardParams()
        cardParams.address = STPFixtures.address()
        let secondCardParams = STPCardParams()

        secondCardParams.address = cardParams.address
        cardParams.address.line1 = "123 Main"

        XCTAssertEqual(cardParams.address.line1, "123 Main")
        XCTAssertEqual(secondCardParams.address.line1, "123 Main")
    }
}

//
//  AddressTests.swift
//  StripeCryptoOnrampTests
//
//  Created by Michael Liberatore on 3/19/26.
//

@testable
@_spi(CryptoOnrampAlpha)
import StripeCryptoOnramp

import XCTest

final class AddressTests: XCTestCase {

    func testIsEmptyReturnsTrueForDefaultAddress() {
        let address = Address()

        XCTAssertTrue(address.isEmpty)
    }

    func testIsEmptyReturnsFalseWhenCityIsPresent() {
        let address = Address(city: "Brooklyn")

        XCTAssertFalse(address.isEmpty)
    }

    func testIsEmptyReturnsFalseWhenCountryIsPresent() {
        let address = Address(country: "US")

        XCTAssertFalse(address.isEmpty)
    }

    func testIsEmptyReturnsFalseWhenLine1IsPresent() {
        let address = Address(line1: "123 Fake Street")

        XCTAssertFalse(address.isEmpty)
    }

    func testIsEmptyReturnsFalseWhenLine2IsPresent() {
        let address = Address(line2: "Apt 2")

        XCTAssertFalse(address.isEmpty)
    }

    func testIsEmptyReturnsFalseWhenPostalCodeIsPresent() {
        let address = Address(postalCode: "11201")

        XCTAssertFalse(address.isEmpty)
    }

    func testIsEmptyReturnsFalseWhenStateIsPresent() {
        let address = Address(state: "New York")

        XCTAssertFalse(address.isEmpty)
    }
}

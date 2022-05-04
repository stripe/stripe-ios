//
//  PhoneNumberElementTests.swift
//  StripeUICoreTests
//
//  Created by Ramon Torres on 4/29/22.
//

import XCTest
@testable @_spi(STP) import StripeUICore

class PhoneNumberElementTests: XCTestCase {

    func test_init() {
        let sut = PhoneNumberElement(
            defaultValue: "3105551234",
            defaultCountry: "PR",
            locale: Locale(identifier: "en_US")
        )
        XCTAssertEqual(sut.phoneNumber?.countryCode, "PR")
        XCTAssertEqual(sut.phoneNumber?.number, "3105551234")
    }

    func test_init_shouldFallbackToLocaleWhenNoCountryIsProvided() {
        let sut = PhoneNumberElement(
            defaultValue: "3105551234",
            locale: Locale(identifier: "es_DO")
        )
        XCTAssertEqual(sut.phoneNumber?.countryCode, "DO")
        XCTAssertEqual(sut.phoneNumber?.number, "3105551234")
    }

    func test_init_withE164() {
        let sut = PhoneNumberElement(defaultValue: "+445555555555", locale: Locale(identifier: "en_US"))
        XCTAssertEqual(sut.phoneNumber?.countryCode, "GB")
        XCTAssertEqual(sut.phoneNumber?.number, "5555555555")
    }

}


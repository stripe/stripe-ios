//
//  PhoneNumberElementV2Tests.swift
//  StripeUICoreTests
//
//  Created by Yuki Tokuhiro on 6/23/22.
//

import XCTest
@testable @_spi(STP) import StripeUICore

class PhoneNumberElementV2Tests: XCTestCase {

    func test_init_with_defaults() {
        let sut = PhoneNumberElementV2(
            allowedCountryCodes: ["PR"],
            defaultCountryCode: "PR",
            defaultPhoneNumber: "3105551234",
            locale: Locale(identifier: "en_US")
        )
        // 
        XCTAssertEqual(sut.textFieldElement.text, "3105551234")
        XCTAssertEqual(sut.phoneNumber?.countryCode, "PR")
        XCTAssertEqual(sut.phoneNumber?.number, "3105551234")
    }
    
    func test_no_default_country_and_locale_in_allowed_countries() {
        // A PhoneNumberElement initialized without a default country...
        // ...where the user's locale is in `allowedCountryCodes`...
        let sut = PhoneNumberElementV2(
            allowedCountryCodes: ["PR"],
            defaultPhoneNumber: "3105551234",
            locale: Locale(identifier: "es_PR")
        )
        // ...should default to the locale
        XCTAssertEqual(sut.textFieldElement.text, "3105551234")
        XCTAssertEqual(sut.phoneNumber?.countryCode, "PR")
        XCTAssertEqual(sut.phoneNumber?.number, "3105551234")
    }
    
    func test_no_default_country_and_locale_not_in_allowed_countries() {
        // A PhoneNumberElement initialized without a default country...
        // ...where the user's locale is **not** in `allowedCountryCodes`...
        let sut = PhoneNumberElementV2(
            allowedCountryCodes: ["US"],
            defaultPhoneNumber: "3105551234",
            locale: Locale(identifier: "es_PR")
        )
        // ...should default to the first country in the list
        XCTAssertEqual(sut.textFieldElement.text, "3105551234")
        XCTAssertEqual(sut.phoneNumber?.countryCode, "US")
        XCTAssertEqual(sut.phoneNumber?.number, "3105551234")
    }
}


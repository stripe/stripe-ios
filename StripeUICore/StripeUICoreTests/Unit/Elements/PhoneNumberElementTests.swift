//
//  PhoneNumberElementTests.swift
//  StripeUICoreTests
//
//  Created by Yuki Tokuhiro on 6/23/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@testable @_spi(STP) import StripeUICore
import XCTest

class PhoneNumberElementTests: XCTestCase {

    func test_init_with_defaults() {
        let sut = PhoneNumberElement(
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

    func test_init_with_default_e164_phone_number() {
        // Initializing a PhoneNumberElement....
        let sut = PhoneNumberElement(
            allowedCountryCodes: ["US", "PR"],
            defaultCountryCode: "PR",           // ...with a default country code...
            defaultPhoneNumber: "+13105551234", // ...and a phone number that also contains a country code...
            locale: Locale(identifier: "en_US")
        )
        // ...should favor the phone number's country code...
        XCTAssertEqual(sut.countryDropdownElement.selectedItem.rawData, "US")
        // ...and remove the country prefix from the number
        XCTAssertEqual(sut.textFieldElement.text, "3105551234")
        XCTAssertEqual(sut.phoneNumber?.countryCode, "US")
        XCTAssertEqual(sut.phoneNumber?.number, "3105551234")
    }

    func test_no_default_country_and_locale_in_allowed_countries() {
        // A PhoneNumberElement initialized without a default country...
        // ...where the user's locale is in `allowedCountryCodes`...
        let sut = PhoneNumberElement(
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
        let sut = PhoneNumberElement(
            allowedCountryCodes: ["US"],
            defaultPhoneNumber: "3105551234",
            locale: Locale(identifier: "es_PR")
        )
        // ...should default to the first country in the list
        XCTAssertEqual(sut.textFieldElement.text, "3105551234")
        XCTAssertEqual(sut.phoneNumber?.countryCode, "US")
        XCTAssertEqual(sut.phoneNumber?.number, "3105551234")
    }

    func test_autofill_removesMatchingCountryCode() {
        let sut = PhoneNumberElement(
            allowedCountryCodes: ["US"],
            locale: Locale(identifier: "en_US")
        )
        simulateAutofill(sut, autofilledPhoneNumber: "+1 (310) 555-1234")
        XCTAssertEqual(sut.textFieldElement.text, "3105551234")
        XCTAssertEqual(sut.phoneNumber?.number, "3105551234")
    }

    func test_autofill_preservesNonMatchingCountryCode() {
        let sut = PhoneNumberElement(
            allowedCountryCodes: ["US"],
            locale: Locale(identifier: "en_US")
        )
        simulateAutofill(sut, autofilledPhoneNumber: "+44 12 3456 7890")
        XCTAssertEqual(sut.textFieldElement.text, "441234567890")
        XCTAssertEqual(sut.phoneNumber?.number, "441234567890")
    }

    func test_hasBeenModified_noDefaults_noModification() {
        let sut = PhoneNumberElement(
            allowedCountryCodes: ["US"],
            locale: Locale(identifier: "en_US")
        )
        XCTAssertFalse(sut.hasBeenModified)
    }

    func test_hasBeenModified_defaultNumber() {
        let sut = PhoneNumberElement(
            allowedCountryCodes: ["US"],
            defaultPhoneNumber: "3105551234",
            locale: Locale(identifier: "en_US")
        )
        XCTAssertFalse(sut.hasBeenModified)
    }

    func test_hasBeenModified_isModified() {
        let sut = PhoneNumberElement(
            allowedCountryCodes: ["US"],
            locale: Locale(identifier: "en_US")
        )
        simulateAutofill(sut, autofilledPhoneNumber: "3")
        XCTAssertTrue(sut.hasBeenModified)
    }

    func test_hasBeenModified_defaultNumber_isModified() {
        let sut = PhoneNumberElement(
            allowedCountryCodes: ["US"],
            defaultPhoneNumber: "3105551234",
            locale: Locale(identifier: "en_US")
        )
        simulateAutofill(sut, autofilledPhoneNumber: "3")
        XCTAssertTrue(sut.hasBeenModified)
    }

    func test_hasBeenModified_isNotModified() {
        let sut = PhoneNumberElement(
            allowedCountryCodes: ["US"],
            locale: Locale(identifier: "en_US")
        )
        simulateAutofill(sut, autofilledPhoneNumber: "3")
        simulateAutofill(sut, autofilledPhoneNumber: "")
        XCTAssertFalse(sut.hasBeenModified)
    }

    func test_hasBeenModified_defaultNumber_isNotModified() {
        let sut = PhoneNumberElement(
            allowedCountryCodes: ["US"],
            defaultPhoneNumber: "3105551234",
            locale: Locale(identifier: "en_US")
        )
        simulateAutofill(sut, autofilledPhoneNumber: "3")
        simulateAutofill(sut, autofilledPhoneNumber: "3105551234")
        XCTAssertFalse(sut.hasBeenModified)
    }

    func test_selectCountry_dontUpdateDefault() {
        let sut = PhoneNumberElement(
            allowedCountryCodes: ["US", "CA"],
            locale: Locale(identifier: "en_US")
        )

        sut.selectCountry(index: 0, shouldUpdateDefaultNumber: false) // select CA
        XCTAssertEqual(sut.countryDropdownElement.selectedIndex, 0)
        XCTAssert(sut.hasBeenModified)
    }

    func test_selectCountry_updateDefault() {
        let sut = PhoneNumberElement(
            allowedCountryCodes: ["US", "CA"],
            locale: Locale(identifier: "en_US")
        )

        sut.selectCountry(index: 0, shouldUpdateDefaultNumber: true) // select CA
        XCTAssertEqual(sut.countryDropdownElement.selectedIndex, 0)
        XCTAssertFalse(sut.hasBeenModified)
    }

    private func simulateAutofill(_ sut: PhoneNumberElement, autofilledPhoneNumber: String) {
        let textField = sut.textFieldElement.textFieldView.textField
        _ = sut.textFieldElement.textFieldView.textField(textField, shouldChangeCharactersIn: NSRange(location: 0, length: 0), replacementString: autofilledPhoneNumber)
        textField.text = autofilledPhoneNumber
        sut.textFieldElement.textFieldView.textDidChange()

    }
}

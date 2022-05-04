//
//  PhoneNumberTests.swift
//  StripeUICoreTests
//
//  Created by Cameron Sabol on 10/11/21.
//

import XCTest

@_spi(STP) @testable import StripeUICore

class PhoneNumberTests: XCTestCase {

    func testFormats() {
        let cases: [(number: String, country: String, format: PhoneNumber.Format, formattedNumber: String)] = [
          (
            number: "",
            country: "US",
            format: .national,
            formattedNumber: ""
          ),
          (
            number: "4",
            country: "US",
            format: .national,
            formattedNumber: "(4"
          ),
          (
            number: "+",
            country: "US",
            format: .national,
            formattedNumber: "" // doesn't include + in national format
          ),
            (
                number: "+",
                country: "US",
                format: .international,
                formattedNumber: "" // empty input shouldn't get formatted
            ),
          (
            number: "a",
            country: "US",
            format: .national,
            formattedNumber: ""
          ),
          (
            number: "(", // PhoneNumberFormat only formats digits, +, and •
            country: "US",
            format: .national,
            formattedNumber: ""
          ),
          (
            number: "+49",
            country: "DE",
            format: .international,
            formattedNumber: "+49 49" // never treats input as country code
          ),
          (
            number: "160 1234567",
            country: "DE",
            format: .international,
            formattedNumber: "+49 160 1234567"
          ),
          (
            number: "5551231234",
            country: "US",
            format: .international,
            formattedNumber: "+1 (555) 123-1234"
          ),
          (
            number: "(555) 123-1234",
            country: "US",
            format: .international,
            formattedNumber: "+1 (555) 123-1234"
          ),
          (
            number: "555",
            country: "US",
            format: .international,
            formattedNumber: "+1 (555"
          ),
          (
            number: "(555) a",
            country: "US",
            format: .international,
            formattedNumber: "+1 (555"
          ),
          (
            number: "(403) 123-1234",
            country: "CA",
            format: .international,
            formattedNumber: "+1 (403) 123-1234"
          ),
          (
            number: "(403) 123-1234",
            country: "CA",
            format: .national,
            formattedNumber: "(403) 123-1234"
          ),
          (
            number: "4031231234",
            country: "CA",
            format: .national,
            formattedNumber: "(403) 123-1234"
          ),
          (
            number: "6711231234",
            country: "GU",
            format: .international,
            formattedNumber: "+1 (671) 123-1234"
          ),
          (
            number: "6711231234",
            country: "GU",
            format: .national,
            formattedNumber: "(671) 123-1234"
          ),
        ];
        
        for c in cases {
            guard let phoneNumber = PhoneNumber(number: c.number, countryCode: c.country) else {
                XCTFail("Could not create phone number for \(c.country), \(c.number)")
                continue
            }
            XCTAssertEqual(phoneNumber.string(as: c.format), c.formattedNumber)
        }
    }
    
    func teste164FormatDropsLeadingZeros() {
        guard let phoneNumber = PhoneNumber(number: "08022223333", countryCode: "JP") else {
            XCTFail("Could not create phone number")
            return
        }
        XCTAssertEqual(phoneNumber.string(as: .e164), "+818022223333")
    }
    
    func teste164MaxLength() {
        guard let phoneNumber = PhoneNumber(number: "123456789123456789", countryCode: "US") else {
            XCTFail("Could not create phone number")
            return
        }
        XCTAssertEqual(phoneNumber.string(as: .e164), "+112345678912345")
    }

    func testFromE164() {
        let gbPhone = PhoneNumber.fromE164("+445555555555")
        XCTAssertEqual(gbPhone?.countryCode, "GB")
        XCTAssertEqual(gbPhone?.number, "5555555555")

        let brPhone = PhoneNumber.fromE164("+5591155256325")
        XCTAssertEqual(brPhone?.countryCode, "BR")
        XCTAssertEqual(brPhone?.number, "91155256325")
    }

    func testFromE164_shouldHandleInvalidInput() {
        XCTAssertNil(PhoneNumber.fromE164(""))
        XCTAssertNil(PhoneNumber.fromE164("++"))
        XCTAssertNil(PhoneNumber.fromE164("+13"))
        XCTAssertNil(PhoneNumber.fromE164("1 (555) 555 5555"))
        XCTAssertNil(PhoneNumber.fromE164("+1555555555555555")) // too long
    }

    func testFromE164_shouldDisambiguateUsingLocale() {
        // This test number is very ambiguous, it can belong to ~25 countries/territories due to
        // the "+1" calling code/prefix being shared by many countries.
        let number = "+15555555555"

        XCTAssertEqual(PhoneNumber.fromE164(number, locale: .init(identifier: "en_US"))?.countryCode, "US")
        XCTAssertEqual(PhoneNumber.fromE164(number, locale: .init(identifier: "en_CA"))?.countryCode, "CA")
        XCTAssertEqual(PhoneNumber.fromE164(number, locale: .init(identifier: "es_DO"))?.countryCode, "DO")
        XCTAssertEqual(PhoneNumber.fromE164(number, locale: .init(identifier: "en_PR"))?.countryCode, "PR")
        XCTAssertEqual(PhoneNumber.fromE164(number, locale: .init(identifier: "en_JM"))?.countryCode, "JM")

        XCTAssertEqual(PhoneNumber.fromE164(number, locale: .init(identifier: "ja_JP"))?.countryCode, "US")
        XCTAssertEqual(PhoneNumber.fromE164(number, locale: .init(identifier: "ar_LB"))?.countryCode, "US")
    }

}

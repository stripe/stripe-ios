//
//  NSString+StripeTest.swift
//  StripeiOS Tests
//
//  Created by Ben Guo on 3/22/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI
import XCTest

class NSString_StripeTest: XCTestCase {

    func testIsBlank() {
        XCTAssertTrue("".isBlank)
        XCTAssertTrue(" ".isBlank)
        XCTAssertTrue("\t\t\t".isBlank)
        XCTAssertFalse("a".isBlank)
        XCTAssertFalse(" a ".isBlank)
    }

    func testSafeSubstringToIndex() {
        XCTAssertEqual("foo".stp_safeSubstring(to: 0), "")
        XCTAssertEqual("foo".stp_safeSubstring(to: 500), "foo")
        XCTAssertEqual("foo".stp_safeSubstring(to: 1), "f")
        XCTAssertEqual("foo".stp_safeSubstring(to: -1), "")
        XCTAssertEqual("foo".stp_safeSubstring(to: -100), "")
        XCTAssertEqual("".stp_safeSubstring(to: 0), "")
        XCTAssertEqual("".stp_safeSubstring(to: 1), "")
    }

    func testSafeSubstringFromIndex() {
        XCTAssertEqual("foo".stp_safeSubstring(from: 0), "foo")
        XCTAssertEqual("foo".stp_safeSubstring(from: 1), "oo")
        XCTAssertEqual("foo".stp_safeSubstring(from: 3), "")
        XCTAssertEqual("foo".stp_safeSubstring(from: -1), "foo")
        XCTAssertEqual("foo".stp_safeSubstring(from: -100), "foo")
        XCTAssertEqual("".stp_safeSubstring(from: 0), "")
        XCTAssertEqual("".stp_safeSubstring(from: 1), "")
    }

    func testStringByRemovingSuffix() {
        XCTAssertEqual("foobar".stp_string(byRemovingSuffix: "bar"), "foo")
        XCTAssertEqual("foobar".stp_string(byRemovingSuffix: "baz"), "foobar")
        XCTAssertEqual("foobar".stp_string(byRemovingSuffix: nil), "foobar")
        XCTAssertEqual("foobar".stp_string(byRemovingSuffix: "foobar"), "")
        XCTAssertEqual("foobar".stp_string(byRemovingSuffix: ""), "foobar")
        XCTAssertEqual("foobar".stp_string(byRemovingSuffix: "oba"), "foobar")

        XCTAssertEqual("foobar☺¿".stp_string(byRemovingSuffix: "bar☺¿"), "foo")
        XCTAssertEqual("foobar☺¿".stp_string(byRemovingSuffix: "bar¿"), "foobar☺¿")

        XCTAssertEqual("foobar\u{202C}".stp_string(byRemovingSuffix: "bar"), "foobar\u{202C}")
        XCTAssertEqual("foobar\u{202C}".stp_string(byRemovingSuffix: "bar\u{202C}"), "foo")

        // e + \u0041 => é
        XCTAssertEqual("foobare\u{0301}".stp_string(byRemovingSuffix: "bare"), "foobare\u{0301}")
        XCTAssertEqual("foobare\u{0301}".stp_string(byRemovingSuffix: "bare\u{0301}"), "foo")
        XCTAssertEqual("foobare".stp_string(byRemovingSuffix: "bare\u{0301}"), "foobare")

    }

    func testLocalizedAmountDisplayString() {
        XCTAssertEqual(String.localizedAmountDisplayString(for: 1099, currency: "USD"), "$10.99")
        XCTAssertEqual(
            String.localizedAmountDisplayString(
                for: 1099,
                currency: "USD",
                locale: Locale(identifier: "fr_FR")
            ),
            "10,99 $US"
        )
        XCTAssertEqual(
            String.localizedAmountDisplayString(
                for: 1099,
                currency: "USD",
                locale: Locale(identifier: "zh_HANT")
            ),
            "US$10.99"
        )

        XCTAssertEqual(
            String.localizedAmountDisplayString(
                for: 1099,
                currency: "ZZZ",
                locale: Locale(identifier: "z")
            ),
            "ZZZ 10.99"
        )
    }
}

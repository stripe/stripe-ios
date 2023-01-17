//
//  STPPostalCodeInputTextFieldFormatterTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 10/30/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPPostalCodeInputTextFieldFormatterTests: XCTestCase {

    func testIsAllowedInput() {
        let formatter = STPPostalCodeInputTextFieldFormatter()
        formatter.countryCode = "US"
        XCTAssertTrue(formatter.isAllowedInput("10002", to: "", at: NSRange(location: 0, length: 0)))
        XCTAssertTrue(formatter.isAllowedInput("21218", to: "", at: NSRange(location: 0, length: 0)))
        XCTAssertFalse(formatter.isAllowedInput("10002-1234", to: "", at: NSRange(location: 0, length: 0)))
        XCTAssertFalse(formatter.isAllowedInput("100021234", to: "", at: NSRange(location: 0, length: 0)))
        XCTAssertFalse(formatter.isAllowedInput("ABC10002", to: "", at: NSRange(location: 0, length: 0)))

        XCTAssertFalse(formatter.isAllowedInput("1", to: "100021234", at: NSRange(location: 10, length: 0)))
        XCTAssertFalse(formatter.isAllowedInput("1", to: "10002", at: NSRange(location: 4, length: 0)))
        XCTAssertTrue(formatter.isAllowedInput("1", to: "1000", at: NSRange(location: 4, length: 0)))

        formatter.countryCode = "UK"
        XCTAssertTrue(formatter.isAllowedInput("10002-1234", to: "", at: NSRange(location: 0, length: 0)))
        XCTAssertTrue(formatter.isAllowedInput("100021234", to: "", at: NSRange(location: 0, length: 0)))
        XCTAssertTrue(formatter.isAllowedInput("ABC10002", to: "", at: NSRange(location: 0, length: 0)))
    }

    func testFormattedString() {
        let formatter = STPPostalCodeInputTextFieldFormatter()
        formatter.countryCode = "US"

        XCTAssertEqual(
            NSAttributedString(string: ""),
            formatter.formattedText(from: "- ", with: [:])
        )
        XCTAssertEqual(
            NSAttributedString(string: "10002"),
            formatter.formattedText(from: "10002-1234", with: [:])
        )

        formatter.countryCode = "UK"
        XCTAssertEqual(
            NSAttributedString(string: "A B C D E F G"),
            formatter.formattedText(from: " a b c d e f g", with: [:])
        )
    }

}

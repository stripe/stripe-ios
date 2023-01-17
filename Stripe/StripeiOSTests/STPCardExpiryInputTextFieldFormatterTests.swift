//
//  STPCardExpiryInputTextFieldFormatterTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 10/28/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPCardExpiryInputTextFieldFormatterTests: XCTestCase {

    func testAllowedInput() {
        let formatter = STPCardExpiryInputTextFieldFormatter()
        XCTAssertTrue(formatter.isAllowedInput("1226", to: "", at: NSRange(location: 0, length: 0)))
        XCTAssertTrue(formatter.isAllowedInput("12/26", to: "", at: NSRange(location: 0, length: 0)))
        XCTAssertTrue(formatter.isAllowedInput("12 / 26", to: "", at: NSRange(location: 0, length: 0)))
        XCTAssertTrue(formatter.isAllowedInput("122026", to: "", at: NSRange(location: 0, length: 0)))
        XCTAssertTrue(formatter.isAllowedInput("12/2026", to: "", at: NSRange(location: 0, length: 0)))

        XCTAssertTrue(formatter.isAllowedInput("1", to: "", at: NSRange(location: 0, length: 0)))
        XCTAssertTrue(formatter.isAllowedInput("2", to: "1", at: NSRange(location: 1, length: 0)))
        XCTAssertTrue(formatter.isAllowedInput("2", to: "12", at: NSRange(location: 2, length: 0)))
        XCTAssertTrue(formatter.isAllowedInput("2", to: "12/", at: NSRange(location: 2, length: 0)))

        // the formatter does NOT verify that these are sensical dates (that is delegated to the validator)
        XCTAssertTrue(formatter.isAllowedInput("16/1901", to: "", at: NSRange(location: 0, length: 0)))

        XCTAssertFalse(formatter.isAllowedInput("12 / 25 / 26", to: "", at: NSRange(location: 0, length: 0)))
        XCTAssertFalse(formatter.isAllowedInput("12 / 25 / 26", to: "", at: NSRange(location: 0, length: 0)))
        XCTAssertFalse(formatter.isAllowedInput("12.26", to: "", at: NSRange(location: 0, length: 0)))
        XCTAssertFalse(formatter.isAllowedInput("2026/12", to: "", at: NSRange(location: 0, length: 0)))
    }

    func testFormattedText() {
        let formatter = STPCardExpiryInputTextFieldFormatter()
        XCTAssertEqual(
            formatter.formattedText(from: "1226", with: [:]),
            NSAttributedString(string: "12/26")
        )
        XCTAssertEqual(
            formatter.formattedText(from: "12/26", with: [:]),
            NSAttributedString(string: "12/26")
        )
        XCTAssertEqual(
            formatter.formattedText(from: "12 / 26", with: [:]),
            NSAttributedString(string: "12/26")
        )
        XCTAssertEqual(
            formatter.formattedText(from: "122026", with: [:]),
            NSAttributedString(string: "12/26")
        )
        XCTAssertEqual(
            formatter.formattedText(from: "12 / 2026", with: [:]),
            NSAttributedString(string: "12/26")
        )
    }
}

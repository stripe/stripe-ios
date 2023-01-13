//
//  STPCardNumberInputTextFieldFormatterTests.swift
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

class STPCardNumberInputTextFieldFormatterTests: XCTestCase {

    func testAllowedInput() {
        let formatter = STPCardNumberInputTextFieldFormatter()
        XCTAssertTrue(formatter.isAllowedInput("4242424242424242", to: "", at: NSRange(location: 0, length: 0)))
        XCTAssertTrue(formatter.isAllowedInput("424242424242424", to: "", at: NSRange(location: 0, length: 0)))
        XCTAssertTrue(
            formatter.isAllowedInput("4242 4242 4242 4242", to: "", at: NSRange(location: 0, length: 0))
        )
        XCTAssertTrue(formatter.isAllowedInput("42424242 42424242", to: "", at: NSRange(location: 0, length: 0)))
        XCTAssertTrue(formatter.isAllowedInput("4242 ", to: "", at: NSRange(location: 0, length: 0)))
        XCTAssertTrue(formatter.isAllowedInput("3566002020360505", to: "", at: NSRange(location: 0, length: 0)))
        XCTAssertTrue(formatter.isAllowedInput(" ", to: "4242", at: NSRange(location: 4, length: 0)))

        XCTAssertFalse(
            formatter.isAllowedInput("4242.4242.4242.4242", to: "", at: NSRange(location: 0, length: 0))
        )
        XCTAssertFalse(formatter.isAllowedInput("4", to: "4242424242424242", at: NSRange(location: 0, length: 0)))
    }

    func testFormatting() {
        let formatter = STPCardNumberInputTextFieldFormatter()
        var expected: NSMutableAttributedString = NSMutableAttributedString()

        expected = NSMutableAttributedString(string: "4242424242424242")
        expected.addAttribute(.kern, value: NSNumber(0), range: NSRange(location: 0, length: 3))
        expected.addAttribute(.kern, value: NSNumber(5), range: NSRange(location: 3, length: 1))
        expected.addAttribute(.kern, value: NSNumber(0), range: NSRange(location: 4, length: 3))
        expected.addAttribute(.kern, value: NSNumber(5), range: NSRange(location: 7, length: 1))
        expected.addAttribute(.kern, value: NSNumber(0), range: NSRange(location: 8, length: 3))
        expected.addAttribute(.kern, value: NSNumber(5), range: NSRange(location: 11, length: 1))
        expected.addAttribute(.kern, value: NSNumber(0), range: NSRange(location: 12, length: 4))
        XCTAssertEqual(formatter.formattedText(from: "4242424242424242", with: [:]), expected)
        XCTAssertEqual(formatter.formattedText(from: "4242 4242 4242 4242", with: [:]), expected)

        expected = NSMutableAttributedString(string: "4242")
        expected.addAttribute(.kern, value: NSNumber(0), range: NSRange(location: 0, length: 4))
        XCTAssertEqual(formatter.formattedText(from: "4242", with: [:]), expected)

        expected = NSMutableAttributedString(string: "42424")
        expected.addAttribute(.kern, value: NSNumber(0), range: NSRange(location: 0, length: 3))
        expected.addAttribute(.kern, value: NSNumber(5), range: NSRange(location: 3, length: 1))
        expected.addAttribute(.kern, value: NSNumber(0), range: NSRange(location: 4, length: 1))
        XCTAssertEqual(formatter.formattedText(from: "42424", with: [:]), expected)

        expected = NSMutableAttributedString(string: "378282246310005")  // 4, 6, 5,
        expected.addAttribute(.kern, value: NSNumber(0), range: NSRange(location: 0, length: 3))
        expected.addAttribute(.kern, value: NSNumber(5), range: NSRange(location: 3, length: 1))
        expected.addAttribute(.kern, value: NSNumber(0), range: NSRange(location: 4, length: 5))
        expected.addAttribute(.kern, value: NSNumber(5), range: NSRange(location: 9, length: 1))
        expected.addAttribute(.kern, value: NSNumber(0), range: NSRange(location: 10, length: 5))
        //        expected.addAttribute(.kern, value: NSNumber(5), range: NSMakeRange(11, 1))
        //        expected.addAttribute(.kern, value: NSNumber(0), range: NSMakeRange(12, 4))
        XCTAssertEqual(formatter.formattedText(from: "378282246310005", with: [:]), expected)
    }

}

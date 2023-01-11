//
//  STPNumericDigitInputTextFormatterTests.swift
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

class STPNumericDigitInputTextFormatterTests: XCTestCase {

    func testDisallowsNonDigits() {
        let formatter = STPNumericDigitInputTextFormatter()
        XCTAssertFalse(
            formatter.isAllowedInput("a", to: "", at: NSRange(location: 0, length: 1)),
            "Shouldn't allow non-digit in empty string"
        )
        XCTAssertFalse(
            formatter.isAllowedInput("1a", to: "", at: NSRange(location: 0, length: 1)),
            "Shouldn't allow digit + non-digit in empty string"
        )
        XCTAssertFalse(
            formatter.isAllowedInput("a", to: "1", at: NSRange(location: 0, length: 1)),
            "Shouldn't allow non-digit in digit string"
        )
        XCTAssertFalse(
            formatter.isAllowedInput("1a", to: "1", at: NSRange(location: 0, length: 1)),
            "Shouldn't allow digit + non-digit in digit string"
        )
        XCTAssertFalse(
            formatter.isAllowedInput(" ", to: "1", at: NSRange(location: 0, length: 1)),
            "Shouldn't allow spaces"
        )
        // for now we only validate the input, not the result
        XCTAssertTrue(
            formatter.isAllowedInput("1", to: "a", at: NSRange(location: 0, length: 1)),
            "Should allow digit added to non-digit string"
        )
    }

    func testAllowsDigits() {
        let formatter = STPNumericDigitInputTextFormatter()
        XCTAssertTrue(
            formatter.isAllowedInput("1", to: "", at: NSRange(location: 0, length: 1)),
            "Should allow digit in empty string"
        )
        XCTAssertTrue(
            formatter.isAllowedInput("2", to: "1", at: NSRange(location: 0, length: 1)),
            "Should allow digit insert at beginning of string"
        )
        XCTAssertTrue(
            formatter.isAllowedInput("3", to: "1", at: NSRange(location: 1, length: 1)),
            "Should allow digit insert at end of string"
        )
        XCTAssertTrue(
            formatter.isAllowedInput("45", to: "1", at: NSRange(location: 0, length: 1)),
            "Should allow multi-digit insert"
        )
    }

    func testFormattingCharacterSet() {
        let formatter = STPNumericDigitInputTextFormatter(
            allowedFormattingCharacterSet: CharacterSet(charactersIn: "xy")
        )
        XCTAssertTrue(
            formatter.isAllowedInput("x", to: "", at: NSRange(location: 0, length: 1)),
            "Should allow formatting character in empty string"
        )
        XCTAssertFalse(
            formatter.isAllowedInput("xa", to: "", at: NSRange(location: 0, length: 1)),
            "Shouldn't allow formatting + non-formatting in empty string"
        )
        XCTAssertTrue(
            formatter.isAllowedInput("x", to: "1", at: NSRange(location: 0, length: 1)),
            "Should allow formatting character in digit string"
        )
        XCTAssertTrue(
            formatter.isAllowedInput("1x", to: "1", at: NSRange(location: 0, length: 1)),
            "Should allow digit + formatting in digit string"
        )
        XCTAssertTrue(
            formatter.isAllowedInput("xxxxyyy", to: "1", at: NSRange(location: 0, length: 6)),
            "Should allow multiple formatting in digit string"
        )
    }

    // MARK: - Inherited Tests
    func testAllowsDeletion() {
        let formatter = STPNumericDigitInputTextFormatter()
        let textField = UITextField()
        XCTAssertTrue(
            formatter.textField(
                textField,
                shouldChangeCharactersIn: NSRange(location: 0, length: 2),
                replacementString: ""
            ),
            "Should allow deletion on empty"
        )
        textField.text = "12"
        XCTAssertTrue(
            formatter.textField(
                textField,
                shouldChangeCharactersIn: NSRange(location: 0, length: 2),
                replacementString: ""
            ),
            "Should allow full deletion"
        )
        textField.text = "12345"
        XCTAssertTrue(
            formatter.textField(
                textField,
                shouldChangeCharactersIn: NSRange(location: 4, length: 1),
                replacementString: ""
            ),
            "Should allow partial deletion at end"
        )
        textField.text = "12345"
        XCTAssertTrue(
            formatter.textField(
                textField,
                shouldChangeCharactersIn: NSRange(location: 3, length: 1),
                replacementString: ""
            ),
            "Should allow partial deletion in middle"
        )
        textField.text = "12345"
        XCTAssertTrue(
            formatter.textField(
                textField,
                shouldChangeCharactersIn: NSRange(location: 0, length: 1),
                replacementString: ""
            ),
            "Should allow partial deletion at beginning"
        )
    }

    func testAllowsInitialSpaceForAutofill() {
        let formatter = STPNumericDigitInputTextFormatter()
        let textField = UITextField()
        textField.textContentType = .nickname
        XCTAssertTrue(
            formatter.textField(
                textField,
                shouldChangeCharactersIn: NSRange(location: 0, length: 0),
                replacementString: " "
            )
        )
    }

}

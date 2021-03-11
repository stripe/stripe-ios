//
//  STPPostalCodeInputTextFieldValidatorTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 10/30/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import XCTest

@testable import Stripe

class STPPostalCodeInputTextFieldValidatorTests: XCTestCase {

    func testValidation() {
        let validator = STPPostalCodeInputTextFieldValidator()
        validator.countryCode = "US"

        validator.inputValue = nil
        XCTAssertEqual(
            STPValidatedInputState.incomplete(description: nil), validator.validationState)

        validator.inputValue = ""
        XCTAssertEqual(
            STPValidatedInputState.incomplete(description: nil), validator.validationState)

        validator.inputValue = "1234"
        XCTAssertEqual(
            STPValidatedInputState.incomplete(description: "Your ZIP is incomplete."),
            validator.validationState)

        validator.inputValue = "12345"
        XCTAssertEqual(STPValidatedInputState.valid(message: nil), validator.validationState)

        validator.inputValue = "12345678"
        XCTAssertEqual(
            STPValidatedInputState.incomplete(description: "Your ZIP is incomplete."),
            validator.validationState)

        validator.inputValue = "123456789"
        XCTAssertEqual(STPValidatedInputState.valid(message: nil), validator.validationState)

        validator.inputValue = "12345-6789"
        XCTAssertEqual(STPValidatedInputState.valid(message: nil), validator.validationState)

        validator.inputValue = "12-3456789"
        XCTAssertEqual(
            STPValidatedInputState.invalid(errorMessage: "Your ZIP is invalid."),
            validator.validationState)

        validator.inputValue = "12345-"
        XCTAssertEqual(
            STPValidatedInputState.incomplete(description: "Your ZIP is incomplete."),
            validator.validationState)

        validator.inputValue = "hi"
        XCTAssertEqual(
            STPValidatedInputState.invalid(errorMessage: "Your ZIP is invalid."),
            validator.validationState)

        validator.countryCode = "UK"
        validator.inputValue = "hi"
        XCTAssertEqual(STPValidatedInputState.valid(message: nil), validator.validationState)
    }

}

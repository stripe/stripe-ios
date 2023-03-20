//
//  STPGenericInputPickerFieldValidatorTest.swift
//  StripeiOS Tests
//
//  Created by Mel Ludowise on 2/9/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest

@testable import Stripe

final class STPGenericInputPickerFieldValidatorTest: XCTestCase {

    private var validator: STPGenericInputPickerField.Validator!

    override func setUp() {
        super.setUp()

        validator = STPGenericInputPickerField.Validator()
    }

    func testInitial() {
        XCTAssertEqual(validator.validationState, .unknown)
    }

    func testValidInput() {
        validator.inputValue = "hello"
        XCTAssertEqual(validator.validationState, .valid(message: nil))
    }

    func testEmptyInput() {
        validator.inputValue = ""
        XCTAssertEqual(validator.validationState, .incomplete(description: nil))
    }

    func testNilInput() {
        validator.inputValue = nil
        XCTAssertEqual(validator.validationState, .incomplete(description: nil))
    }
}

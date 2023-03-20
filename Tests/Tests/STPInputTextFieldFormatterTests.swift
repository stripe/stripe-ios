//
//  STPInputTextFieldFormatterTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 10/28/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import XCTest

@testable import Stripe

class STPInputTextFieldFormatterTests: XCTestCase {

    func testAllowsDeletion() {
        let formatter = STPInputTextFieldFormatter()
        let textField = UITextField()
        XCTAssertTrue(
            formatter.textField(
                textField, shouldChangeCharactersIn: NSMakeRange(0, 2), replacementString: ""),
            "Should allow deletion on empty")
        textField.text = "Hi"
        XCTAssertTrue(
            formatter.textField(
                textField, shouldChangeCharactersIn: NSMakeRange(0, 2), replacementString: ""),
            "Should allow full deletion")
        textField.text = "Hello"
        XCTAssertTrue(
            formatter.textField(
                textField, shouldChangeCharactersIn: NSMakeRange(4, 1), replacementString: ""),
            "Should allow partial deletion at end")
        textField.text = "Hello"
        XCTAssertTrue(
            formatter.textField(
                textField, shouldChangeCharactersIn: NSMakeRange(3, 1), replacementString: ""),
            "Should allow partial deletion in middle")
        textField.text = "Hello"
        XCTAssertTrue(
            formatter.textField(
                textField, shouldChangeCharactersIn: NSMakeRange(0, 1), replacementString: ""),
            "Should allow partial deletion at beginning")
    }

    func testAllowsInitialSpaceForAutofill() {
        let formatter = STPInputTextFieldFormatter()
        let textField = UITextField()
        textField.textContentType = .nickname
        XCTAssertTrue(
            formatter.textField(
                textField, shouldChangeCharactersIn: NSMakeRange(0, 0), replacementString: " "))
    }

}

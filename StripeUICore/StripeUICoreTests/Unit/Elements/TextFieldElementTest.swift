//
//  TextFieldElementTest.swift
//  StripeUICoreTests
//
//  Created by Yuki Tokuhiro on 8/23/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest
@testable @_spi(STP) import StripeUICore

class TextFieldElementTest: XCTestCase {
    struct Configuration: TextFieldElementConfiguration {
        var defaultValue: String?
        var label: String = "label"
        func maxLength(for text: String) -> Int { "default value".count }
        
        func validate(text: String, isOptional: Bool) -> TextFieldElement.ValidationState {
            return .invalid(TextFieldElement.Error.empty)
        }
    }
    
    func testNoDefaultValue() {
        let element = TextFieldElement(configuration: Configuration(defaultValue: nil))
        XCTAssertTrue(element.textFieldView.text.isEmpty)
        XCTAssertTrue(element.text.isEmpty)
    }
    
    func testDefaultValue() {
        let element = TextFieldElement(configuration: Configuration(defaultValue: "default value"))
        XCTAssertEqual(element.textFieldView.text, "default value")
        XCTAssertEqual(element.text, "default value")
    }
    
    func testInvalidDefaultValueIsSanitized() {
        let element = TextFieldElement(configuration: Configuration(
            defaultValue: "\ndefault\n value that is too long and contains disallowed characters")
        )
        XCTAssertEqual(element.textFieldView.text, "default value")
        XCTAssertEqual(element.text, "default value")
    }
}

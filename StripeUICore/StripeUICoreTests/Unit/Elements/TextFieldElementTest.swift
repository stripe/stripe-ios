//
//  TextFieldElementTest.swift
//  StripeUICoreTests
//
//  Created by Yuki Tokuhiro on 8/23/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@testable @_spi(STP) import StripeUICore
import XCTest

class TextFieldElementTest: XCTestCase {
    struct Configuration: TextFieldElementConfiguration {
        var defaultValue: String?
        var label: String = "label"
        func maxLength(for text: String) -> Int { "default value".count }
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

    func testEmptyStringsFailDefaultConfigurationValidation() {
        let sut = Configuration()
        XCTAssertEqual(sut.validate(text: "", isOptional: false), .invalid(TextFieldElement.Error.empty(localizedDescription: "")))
        XCTAssertEqual(sut.validate(text: " ", isOptional: false), .invalid(TextFieldElement.Error.empty(localizedDescription: "")))
        XCTAssertEqual(sut.validate(text: " \n", isOptional: false), .invalid(TextFieldElement.Error.empty(localizedDescription: "")))

    }

    func testMultipleCharacterChangeInEmptyFieldIsAutofill() {
        let element = TextFieldElement(configuration: Configuration(defaultValue: nil))
        XCTAssertEqual(element.didReceiveAutofill, false)
        _ = element.textFieldView.textField(element.textFieldView.textField, shouldChangeCharactersIn: NSRange(location: 0, length: 0), replacementString: "This is autofill")
        element.textFieldView.textDidChange()
        XCTAssertEqual(element.didReceiveAutofill, true)
    }

    func testSingleCharacterChangeInEmptyFieldIsNotAutofill() {
        let element = TextFieldElement(configuration: Configuration(defaultValue: nil))
        XCTAssertEqual(element.didReceiveAutofill, false)
        _ = element.textFieldView.textField(element.textFieldView.textField, shouldChangeCharactersIn: NSRange(location: 0, length: 0), replacementString: "T")
        element.textFieldView.textDidChange()
        XCTAssertEqual(element.didReceiveAutofill, false)
    }

    func testMultipleCharacterChangeInPopulatedFieldIsNotAutofill() {
        let element = TextFieldElement(configuration: Configuration(defaultValue: "default value"))
        XCTAssertEqual(element.didReceiveAutofill, false)
        _ = element.textFieldView.textField(element.textFieldView.textField, shouldChangeCharactersIn: NSRange(location: 0, length: 0), replacementString: "This is autofill")
        element.textFieldView.textDidChange()
        XCTAssertEqual(element.didReceiveAutofill, false)
    }

    func testSingleCharacterChangeInPopulatedFieldIsNotAutofill() {
        let element = TextFieldElement(configuration: Configuration(defaultValue: "default value"))
        XCTAssertEqual(element.didReceiveAutofill, false)
        _ = element.textFieldView.textField(element.textFieldView.textField, shouldChangeCharactersIn: NSRange(location: 0, length: 0), replacementString: "T")
        element.textFieldView.textDidChange()
        XCTAssertEqual(element.didReceiveAutofill, false)
    }

    func testSanitizeRemovesFaceEmojis() {
        let element = TextFieldElement(configuration: Configuration(defaultValue: nil))
        XCTAssertEqual(element.sanitize(text: "Hello 😀 World 🎉"), "Hello  World ")
    }

    func testSanitizeRemovesModifiedEmojis() {
        let element = TextFieldElement(configuration: Configuration(defaultValue: nil))
        // Test skin tone modifiers
        XCTAssertEqual(element.sanitize(text: "👋🏻👋🏼👋🏽👋🏾👋🏿"), "")
    }

    func testSanitizePreservesText() {
        let element = TextFieldElement(configuration: Configuration(defaultValue: nil))
        XCTAssertEqual(element.sanitize(text: "John Smith"), "John Smith")
        XCTAssertEqual(element.sanitize(text: "123 Main St"), "123 Main St")
        XCTAssertEqual(element.sanitize(text: "NY, NY 10001"), "NY, NY 10001")
    }

    func testSetTextRemovesEmojis() {
        let element = TextFieldElement(configuration: Configuration(defaultValue: nil))
        element.setText("John 😀 Doe")
        XCTAssertEqual(element.text, "John  Doe")
    }

    func testDefaultValueWithEmojisIsSanitized() {
        let element = TextFieldElement(configuration: Configuration(defaultValue: "Hello 🌍 World Test Test"))
        XCTAssertEqual(element.text, "Hello  World ") // Truncated to maxLength
    }
}

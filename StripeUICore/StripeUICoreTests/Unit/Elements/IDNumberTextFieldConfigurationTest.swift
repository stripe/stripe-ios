//
//  IDNumberTextFieldConfigurationTest.swift
//  StripeUICoreTests
//
//  Created by Mel Ludowise on 9/28/21.
//

import XCTest
@_spi(STP) @testable import StripeUICore

final class IDNumberTextFieldConfigurationTest: XCTestCase {

    func testValidationBR_CPF_CNPJ() {
        let config = IDNumberTextFieldConfiguration(type: .BR_CPF_CNPJ, label: "")

        // CPF is 11 digits
        verifyValid(config.validate(text: "12345678901", isOptional: false))
        // CNPJ is 14 digits
        verifyValid(config.validate(text: "12345678901234", isOptional: false))
        // Empty string is okay if optional
        verifyValid(config.validate(text: "", isOptional: true))

        // Anything else is invalid

        // Empty
        verifyInvalidEmpty(config.validate(text: "", isOptional: false))
        // Too few digits
        verifyInvalidIncomplete(config.validate(text: "1", isOptional: false))
        verifyInvalidIncomplete(config.validate(text: "1234567890", isOptional: false))
        // Between 11–14 digits
        verifyInvalidIncomplete(config.validate(text: "123456789012", isOptional: false))
        // > 14 digits
        verifyInvalidIncomplete(config.validate(text: "1234567890123456", isOptional: false))
    }

    func testValidationUnspecifiedType() {
        let config = IDNumberTextFieldConfiguration(type: nil, label: "")
        // Anything but empty string is valid
        verifyInvalidEmpty(config.validate(text: "", isOptional: false))
        verifyValid(config.validate(text: "a", isOptional: false))
        verifyValid(config.validate(text: "1", isOptional: false))
        verifyValid(config.validate(text: "/;'", isOptional: false))
        verifyValid(config.validate(text: "asdfghjklqwertyuiopzxcvbnm1234567890", isOptional: false))
        // Empty string is okay if optional
        verifyValid(config.validate(text: "", isOptional: true))
    }

    func testDisplayTextBR_CPF_CNPJ() {
        let config = IDNumberTextFieldConfiguration(type: .BR_CPF_CNPJ, label: "")

        XCTAssertEqual(config.makeDisplayText(for: "").string, "")

        // Format as CPF if <= 11 characters
        XCTAssertEqual(config.makeDisplayText(for: "123").string, "123")
        XCTAssertEqual(config.makeDisplayText(for: "123456789").string, "123.456.789")
        XCTAssertEqual(config.makeDisplayText(for: "12345678901").string, "123.456.789-01")

        // Format as CNPJ if > 11 characters
        XCTAssertEqual(config.makeDisplayText(for: "123456789012").string, "123.456.789/012")
        XCTAssertEqual(config.makeDisplayText(for: "12345678901234").string, "123.456.789/012-34")
        XCTAssertEqual(config.makeDisplayText(for: "12345678901234567").string, "123.456.789/012-34")
    }
}

private extension IDNumberTextFieldConfigurationTest {
    func verifyValid(_ validationState: TextFieldElement.ValidationState,
                     file: StaticString = #filePath,
                     line: UInt = #line) {
        XCTAssertEqual(validationState, .valid, file: file, line: line)
    }

    func getTextFieldError(_ validationState: TextFieldElement.ValidationState,
                           file: StaticString = #filePath,
                           line: UInt = #line) -> TextFieldElement.Error? {
        guard case let .invalid(error) = validationState else {
            XCTFail("Expected `.invalid` but was `.valid`", file: file, line: line)
            return nil
        }
        guard let textFieldError = error as? TextFieldElement.Error else {
            XCTFail("Expected `TextFieldElement.Error` but was `\(type(of: error))`", file: file, line: line)
            return nil
        }
        return textFieldError
    }

    func verifyInvalidIncomplete(_ validationState: TextFieldElement.ValidationState,
                                 file: StaticString = #filePath,
                                 line: UInt = #line) {
        guard let textFieldError = getTextFieldError(validationState, file: file, line: line) else {
            return
        }
        guard case .incomplete = textFieldError else {
            return XCTFail("Expected `.incomplete` but was `\(textFieldError)`", file: file, line: line)
        }
    }

    func verifyInvalidEmpty(_ validationState: TextFieldElement.ValidationState,
                            file: StaticString = #filePath,
                            line: UInt = #line) {
        guard let textFieldError = getTextFieldError(validationState, file: file, line: line) else {
            return
        }
        guard case .empty = textFieldError else {
            return XCTFail("Expected `.empty` but was `\(textFieldError)`", file: file, line: line)
        }
    }
}

//
//  TextFieldElement+AddressFactoryTest.swift
//  StripeUICoreTests
//
//  Created by Yuki Tokuhiro on 6/14/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) @testable import StripeUICore
import XCTest

typealias ValidationState = TextFieldElement.ValidationState

class TextFieldElementAddressFactoryTest: XCTestCase {
    // MARK: - Name

    func testNameConfigurationValidation() {
        let name = TextFieldElement.NameConfiguration(type: .full, defaultValue: nil)

        // MARK: Required
        let requiredTestcases: [String: ValidationState] = [
            "": .invalid(TextFieldElement.Error.empty),
            "0": .valid,
            "A": .valid,
            "; foo": .valid,
        ]
        requiredTestcases.forEach { testcase, expected in
            name.test(text: testcase, isOptional: false, matches: expected)
        }

        // MARK: Optional
        // Overwrite the required test cases with the ones whose expected value differs when the field is optional
        let optionalTestcases: [String: ValidationState] = requiredTestcases.merging([
            "": .valid,
        ]) { _, new in new }
        for (testcase, expected) in optionalTestcases {
            name.test(text: testcase, isOptional: true, matches: expected)
        }
    }

    // MARK: - Email

    func testEmailConfigurationValidation() {
        let email = TextFieldElement.EmailConfiguration(defaultValue: nil)

        // MARK: Required
        let requiredTestcases: [String: ValidationState] = [
            "": .invalid(TextFieldElement.Error.empty),
            "f": .invalid(email.invalidError),
            "f@": .invalid(email.invalidError),
            "f@z": .invalid(email.invalidError),
            "f@z.c": .valid,
        ]
        for (testcase, expected) in requiredTestcases {
            email.test(text: testcase, isOptional: false, matches: expected)
        }

        // MARK: Optional
        // Overwrite the required test cases with the ones whose expected value differs when the field is optional
        let optionalTestcases: [String: ValidationState] = requiredTestcases.merging([
            "": .valid,
        ]) { _, new in new }
        for (testcase, expected) in optionalTestcases {
            email.test(text: testcase, isOptional: true, matches: expected)
        }
    }

    // MARK: - Postal Code

    func testPostalCodeConfigurationValidationUS() {
        let config = TextFieldElement.Address.PostalCodeConfiguration(countryCode: "US", label: "ZIP", defaultValue: nil, isOptional: false)
        XCTAssertEqual(config.keyboardProperties(for: "").type, .numberPad)

        // valid cases
        config.test(text: "94115", isOptional: false, matches: .valid)
        config.test(text: "12345", isOptional: false, matches: .valid)

        // invalid cases
        config.test(text: "", isOptional: false, matches: .invalid(TextFieldElement.Error.empty))
        config.test(text: "1234", isOptional: false, matches: .invalid(TextFieldElement.Error.incomplete(localizedDescription: String.Localized.your_zip_is_incomplete)))
        config.test(text: "9411", isOptional: false, matches: .invalid(TextFieldElement.Error.incomplete(localizedDescription: String.Localized.your_zip_is_incomplete)))
        config.test(text: "abcde", isOptional: false, matches: .invalid(TextFieldElement.Error.invalid(localizedDescription: String.Localized.your_zip_is_invalid)))
    }

    func testPostalCodeConfigurationValidationGB() {
        let config = TextFieldElement.Address.PostalCodeConfiguration(countryCode: "GB", label: "Postal", defaultValue: nil, isOptional: false)
        XCTAssertEqual(config.keyboardProperties(for: "").type, .default)

        // valid cases
        config.test(text: "A99AA", isOptional: false, matches: .valid)
        config.test(text: "SW1W0NY", isOptional: false, matches: .valid)
        config.test(text: "OX12BQ", isOptional: false, matches: .valid)
        config.test(text: "G26AY", isOptional: false, matches: .valid)
        config.test(text: "M11AA", isOptional: false, matches: .valid)
        config.test(text: "B23DF", isOptional: false, matches: .valid)
        config.test(text: "CR26XH", isOptional: false, matches: .valid)
        config.test(text: "M60 1NW", isOptional: false, matches: .valid)
        config.test(text: "DN551PT", isOptional: false, matches: .valid)
        config.test(text: "EC1A1BB", isOptional: false, matches: .valid)

        // invalid cases
        config.test(text: "A99A", isOptional: false, matches: .invalid(TextFieldElement.Error.incomplete(localizedDescription: String.Localized.your_postal_code_is_incomplete)))
        config.test(text: "1W0NY", isOptional: false, matches: .invalid(TextFieldElement.Error.invalid(localizedDescription: String.Localized.your_postal_code_is_invalid)))
        config.test(text: "1M1AA", isOptional: false, matches: .invalid(TextFieldElement.Error.invalid(localizedDescription: String.Localized.your_postal_code_is_invalid)))
        config.test(text: "1M 1AA", isOptional: false, matches: .invalid(TextFieldElement.Error.invalid(localizedDescription: String.Localized.your_postal_code_is_invalid)))
    }

    func testPostalCodeConfigurationValidationCA() {
        let config = TextFieldElement.Address.PostalCodeConfiguration(countryCode: "CA", label: "Postal", defaultValue: nil, isOptional: false)
        XCTAssertEqual(config.keyboardProperties(for: "").type, .default)

        // valid cases
        config.test(text: "A9A9A9", isOptional: false, matches: .valid)
        config.test(text: "A9A 9A9", isOptional: false, matches: .valid)
        config.test(text: "A9A-9A9", isOptional: false, matches: .valid)
        config.test(text: "P0L 1N0", isOptional: false, matches: .valid)
        config.test(text: "A0A 0A0", isOptional: false, matches: .valid)
        config.test(text: "A0A0A0", isOptional: false, matches: .valid)

        // invalid cases
        config.test(text: "", isOptional: false, matches: .invalid(TextFieldElement.Error.empty))
        config.test(text: "AAA AAA", isOptional: false, matches: .invalid(TextFieldElement.Error.invalid(localizedDescription: String.Localized.your_postal_code_is_invalid)))
        config.test(text: "AAAAAA", isOptional: false, matches: .invalid(TextFieldElement.Error.invalid(localizedDescription: String.Localized.your_postal_code_is_invalid)))
        config.test(text: "1N8E8R", isOptional: false, matches: .invalid(TextFieldElement.Error.invalid(localizedDescription: String.Localized.your_postal_code_is_invalid)))
        config.test(text: "141124", isOptional: false, matches: .invalid(TextFieldElement.Error.invalid(localizedDescription: String.Localized.your_postal_code_is_invalid)))
        config.test(text: "A9A9A", isOptional: false, matches: .invalid(TextFieldElement.Error.incomplete(localizedDescription: String.Localized.your_postal_code_is_incomplete)))
        config.test(text: "A9AAA9", isOptional: false, matches: .invalid(TextFieldElement.Error.invalid(localizedDescription: String.Localized.your_postal_code_is_invalid)))
    }

    func testPostalCodeConfigurationValidationIN() {
        let config = TextFieldElement.Address.PostalCodeConfiguration(countryCode: "IN", label: "PIN", defaultValue: nil, isOptional: false)
        XCTAssertEqual(config.keyboardProperties(for: "").type, .default)

        // valid cases
        config.test(text: "a", isOptional: false, matches: .valid)
        config.test(text: "1", isOptional: false, matches: .valid)
        config.test(text: "aaaaa", isOptional: false, matches: .valid)
        config.test(text: "11111", isOptional: false, matches: .valid)

        // Invalid cases
        config.test(text: "", isOptional: false, matches: .invalid(TextFieldElement.Error.empty))
    }

    // MARK: - Phone Number
    func testPhoneNumberConfigurationValidation() {
        // US formatting
        let usConfiguration = TextFieldElement.PhoneNumberConfiguration {
            return "US"
        }

        // valid numbers
        for number in [
            "555-555-5555",
            "5555555555",
            "(555) 555-5555",
        ] {
            usConfiguration.test(text: number, isOptional: false, matches: .valid)
        }

        // incomplete
        for number in [
            "555-555-555",
            "555-555-A555", // the formatter should remove the A here
        ] {
            usConfiguration.test(text: number,
                                 isOptional: false,
                                 matches: .invalid(TextFieldElement.PhoneNumberConfiguration.incompleteError))
        }
    }
}

// MARK: - Helpers

// TODO(mludowise): These should get migrated to a shared StripeUICoreTestUtils target

extension TextFieldElementConfiguration {
    func test(text: String, isOptional: Bool, matches expected: ValidationState, file: StaticString = #filePath, line: UInt = #line) {
        let actual = validate(text: text, isOptional: isOptional)
        XCTAssertEqual(actual, expected, "\(text), \(isOptional): Expected \(expected) but got \(actual)", file: file, line: line)
    }
}

extension TextFieldElement.ValidationState: Equatable {
    public static func == (lhs: TextFieldElement.ValidationState, rhs: TextFieldElement.ValidationState) -> Bool {
        switch (lhs, rhs) {
        case (.valid, .valid):
            return true
        case let (.invalid(lhsError), .invalid(rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

func == (lhs: TextFieldValidationError, rhs: TextFieldValidationError) -> Bool {
    return (lhs as NSError).isEqual(rhs as NSError)
}

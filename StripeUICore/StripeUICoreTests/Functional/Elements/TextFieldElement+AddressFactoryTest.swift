//
//  TextFieldElement+AddressFactoryTest.swift
//  StripeUICoreTests
//
//  Created by Yuki Tokuhiro on 6/14/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest
@_spi(STP) @testable import StripeUICore

typealias ValidationState = TextFieldElement.ValidationState

class TextFieldElementAddressFactoryTest: XCTestCase {
    // MARK: - Name
    
    func testNameConfigurationValidation() {
        let name = TextFieldElement.Address.NameConfiguration(defaultValue: nil)
        
        // MARK: Required
        let requiredTestcases: [String: ValidationState] = [
            "": .invalid(TextFieldElement.Error.empty),
            "0": .valid,
            "A": .valid,
            "; foo": .valid
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
        let email = TextFieldElement.Address.EmailConfiguration(defaultValue: nil)
        
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

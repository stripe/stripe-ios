//
//  TextFieldElement+AddressTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 6/14/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest
@testable import Stripe

typealias ValidationState = TextFieldElement.ValidationState

class TextFieldElementAddressTest: XCTestCase {
    // MARK: - Name
    
    func testNameConfigurationValidation() {
        let name = TextFieldElement.Address.NameConfiguration()
        
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
    func testNameConfigurationParams() {
        let name = TextFieldElement.Address.NameConfiguration()
        let params = name.updateParams(for: "some name", params: IntentConfirmParams(type: .card))
        XCTAssertEqual(
            params?.paymentMethodParams.billingDetails?.name,
            "some name"
        )
    }
    
    // MARK: - Email

    func testEmailConfigurationValidation() {
        let email = TextFieldElement.Address.EmailConfiguration()
        
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
    
    func testEmailConfigurationParams() {
        let email = TextFieldElement.Address.EmailConfiguration()
        let params = email.updateParams(for: "stripe@stripe.com", params: IntentConfirmParams(type: .card))
        XCTAssertEqual(
            params?.paymentMethodParams.billingDetails?.email,
            "stripe@stripe.com"
        )
    }
}

// MARK: - Helpers

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

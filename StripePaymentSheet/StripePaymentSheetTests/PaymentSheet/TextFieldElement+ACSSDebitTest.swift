//
//  TextFieldElement+ACSSDebitTest.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 8/27/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripeUICore
import XCTest

@MainActor
final class TextFieldElementACSSDebitTest: XCTestCase {
    func testInstitutionNumberValidation() {
        let configuration = makeNumberConfiguration(validLengths: 3...3)

        XCTAssertEqual(
            errorDescription(configuration.validate(text: "", isOptional: false)),
            "Incomplete"
        )
        XCTAssertEqual(
            errorDescription(configuration.validate(text: "12", isOptional: false)),
            "Incomplete"
        )
        XCTAssertTrue(isValid(configuration.validate(text: "123", isOptional: false)))
    }

    func testTransitNumberValidation() {
        let configuration = makeNumberConfiguration(validLengths: 5...5)

        XCTAssertEqual(
            errorDescription(configuration.validate(text: "1234", isOptional: false)),
            "Incomplete"
        )
        XCTAssertTrue(isValid(configuration.validate(text: "12345", isOptional: false)))
    }

    func testAccountNumberValidation() {
        let configuration = makeNumberConfiguration(validLengths: 7...12)

        XCTAssertEqual(
            errorDescription(configuration.validate(text: "123456", isOptional: false)),
            "Incomplete"
        )
        XCTAssertTrue(isValid(configuration.validate(text: "1234567", isOptional: false)))
        XCTAssertTrue(isValid(configuration.validate(text: "123456789012", isOptional: false)))
        XCTAssertFalse(isValid(configuration.validate(text: "1234567890123", isOptional: false)))
    }

    func testAccountNumberConfirmationValidation() {
        var accountNumber = "000123456789"
        let configuration = TextFieldElement.ACSSDebit.ConfirmAccountNumberConfiguration(
            defaultValue: nil,
            accountNumber: { accountNumber }
        )

        XCTAssertEqual(
            errorDescription(configuration.validate(text: "", isOptional: false)),
            "Confirm the account number."
        )
        XCTAssertEqual(
            errorDescription(configuration.validate(text: "000123456788", isOptional: false)),
            "Your account numbers don’t match."
        )
        XCTAssertTrue(isValid(configuration.validate(text: "000123456789", isOptional: false)))

        accountNumber = "1234567"
        XCTAssertFalse(isValid(configuration.validate(text: "000123456789", isOptional: false)))
    }

    private func makeNumberConfiguration(validLengths: ClosedRange<Int>) -> TextFieldElement.ACSSDebit.NumberConfiguration {
        return .init(
            label: "Test",
            defaultValue: nil,
            validLengths: validLengths,
            incompleteErrorDescription: "Incomplete"
        )
    }

    private func isValid(_ state: TextFieldElement.ValidationState) -> Bool {
        if case .valid = state {
            return true
        }
        return false
    }

    private func errorDescription(_ state: TextFieldElement.ValidationState) -> String? {
        guard case .invalid(let error) = state else {
            return nil
        }
        return error.localizedDescription
    }
}

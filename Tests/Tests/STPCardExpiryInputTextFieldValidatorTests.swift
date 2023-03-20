//
//  STPCardExpiryInputTextFieldValidatorTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 10/28/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import XCTest

@testable import Stripe

class STPCardExpiryInputTextFieldValidatorTests: XCTestCase {

    func testValidation() {
        let now = Date()
        guard
            let nowMonth = Calendar(identifier: .gregorian).dateComponents(
                Set([Calendar.Component.month]), from: now
            ).month,
            let fullYear = Calendar(identifier: .gregorian).dateComponents(
                Set([Calendar.Component.year]), from: now
            ).year
        else {
            XCTFail("Chaos reigns")
            return
        }
        let nowYear = fullYear % 100

        let validator = STPCardExpiryInputTextFieldValidator()
        validator.inputValue = String(format: "01/%2d", (nowYear + 1) % 100)
        if case .valid = validator.validationState {
            XCTAssertTrue(true)
        } else {
            XCTFail("January of next year should be valid")
        }

        let oneMonthAhead: String = {
            if nowMonth == 12 {
                return String(format: "01/%2d", (nowYear + 1) % 100)
            } else {
                return String(format: "%02d/%2d", nowMonth + 1, nowYear)
            }
        }()
        validator.inputValue = oneMonthAhead
        if case .valid = validator.validationState {
            XCTAssertTrue(true)
        } else {
            XCTFail("One month ahead should be valid")
        }

        let oneMonthAgo: String = {
            if nowMonth == 1 {
                return String(format: "01/%2d", max(0, nowYear - 1))
            } else {
                return String(format: "%02d/%2d", nowMonth - 1, nowYear)
            }
        }()
        validator.inputValue = oneMonthAgo
        if case .invalid(let errorMessage) = validator.validationState {
            XCTAssertEqual(errorMessage, "Your card's expiration year is invalid.")
        } else {
            XCTFail("One month ago should be invalid")
        }

        let nonsensical = "16/55"
        validator.inputValue = nonsensical
        if case .invalid(let errorMessage) = validator.validationState {
            XCTAssertEqual(errorMessage, "Your card's expiration date is invalid.")
        } else {
            XCTFail("Invalid month+year should be invalid")
        }

        validator.inputValue = "2"
        if case .incomplete(let description) = validator.validationState {
            XCTAssertEqual(description, "Your card's expiration date is incomplete.")
        } else {
            XCTFail("One digit should be incomplete")
        }

        validator.inputValue = "2/"
        if case .incomplete(let description) = validator.validationState {
            XCTAssertEqual(description, "Your card's expiration date is incomplete.")
        } else {
            XCTFail("One digit with separator should be incomplete")
        }

        validator.inputValue = String(format: "1/%2d", (nowYear + 1) % 100)
        if case .incomplete(let description) = validator.validationState {
            XCTAssertEqual(description, "Your card's expiration date is incomplete.")
        } else {
            XCTFail("Single digit month should be incomplete")
        }
        
        validator.inputValue = "13/"
        if case .invalid(let description) = validator.validationState {
            XCTAssertEqual(description, "Your card's expiration month is invalid.")
        } else {
            XCTFail("Invalid month should be invalid")
        }
    }
    
    func testExpiryStringFormatsYear() throws {
        let validator = STPCardExpiryInputTextFieldValidator()
        
        validator.inputValue = "02/24"
        
        let expiryStrings = try XCTUnwrap(validator.expiryStrings)
        
        XCTAssertEqual(expiryStrings.month, "02")
        XCTAssertEqual(expiryStrings.year, "2024")
    }
    
    func testExpiryStringDoesNotFormatYear() throws {
        let validator = STPCardExpiryInputTextFieldValidator()
        
        validator.inputValue = "02/2024"
        
        let expiryStrings = try XCTUnwrap(validator.expiryStrings)
        
        XCTAssertEqual(expiryStrings.month, "02")
        XCTAssertEqual(expiryStrings.year, "2024")
    }

}

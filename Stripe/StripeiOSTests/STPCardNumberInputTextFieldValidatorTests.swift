//
//  STPCardNumberInputTextFieldValidatorTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 10/29/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPCardNumberInputTextFieldValidatorTests: XCTestCase {

    static let cardData: [(STPCardBrand, String, STPValidatedInputState)] = {
        return [
            (
                .visa,
                "4242424242424242",
                .valid(message: nil)
            ),
            (
                .visa,
                "4242424242422",
                .incomplete(description: "Your card number is incomplete.")
            ),
            (
                .visa,
                "4012888888881881",
                .valid(message: nil)
            ),
            (
                .visa,
                "4000056655665556",
                .valid(message: nil)
            ),
            (
                .mastercard,
                "5555555555554444",
                .valid(message: nil)
            ),
            (
                .mastercard,
                "5200828282828210",
                .valid(message: nil)
            ),
            (
                .mastercard,
                "5105105105105100",
                .valid(message: nil)
            ),
            (
                .mastercard,
                "2223000010089800",
                .valid(message: nil)
            ),
            (
                .amex,
                "378282246310005",
                .valid(message: nil)
            ),
            (
                .amex,
                "371449635398431",
                .valid(message: nil)
            ),
            (
                .discover,
                "6011111111111117",
                .valid(message: nil)
            ),
            (
                .discover,
                "6011000990139424",
                .valid(message: nil)
            ),
            (
                .dinersClub,
                "36227206271667",
                .valid(message: nil)
            ),
            (
                .dinersClub,
                "3056930009020004",
                .valid(message: nil)
            ),
            (
                .JCB,
                "3530111333300000",
                .valid(message: nil)
            ),
            (
                .JCB,
                "3566002020360505",
                .valid(message: nil)
            ),
            (
                .unknown,
                "1234567812345678",
                .invalid(errorMessage: "Your card number is invalid.")
            ),
        ]
    }()

    func testValidation() {
        // same tests as in STPCardValidatorTest#testNumberValidation
        var tests: [(STPValidatedInputState, String, STPCardBrand)] = []

        for card in STPCardNumberInputTextFieldValidatorTests.cardData {
            tests.append((card.2, card.1, card.0))
        }

        tests.append((.valid(message: nil), "4242 4242 4242 4242", .visa))
        tests.append((.valid(message: nil), "4136000000008", .visa))

        let badCardNumbers: [(String, STPCardBrand)] = [
            ("0000000000000000", .unknown),
            ("9999999999999995", .unknown),
            ("1", .unknown),
            ("1234123412341234", .unknown),
            ("xxx", .unknown),
            ("9999999999999999999999", .unknown),
            ("42424242424242424242", .visa),
            ("4242-4242-4242-4242", .visa),
        ]

        for card in badCardNumbers {
            tests.append((.invalid(errorMessage: "Your card number is invalid."), card.0, card.1))
        }

        let possibleCardNumbers: [(String, STPCardBrand)] = [
            ("4242", .visa), ("5", .mastercard), ("3", .unknown), ("", .unknown),
            ("    ", .unknown), ("6011", .discover), ("4012888888881", .visa),
        ]

        for card in possibleCardNumbers {
            tests.append(
                (
                    .incomplete(
                        description: card.0.isEmpty ? nil : "Your card number is incomplete."
                    ),
                    card.0, card.1
                )
            )
        }

        let validator = STPCardNumberInputTextFieldValidator()
        for test in tests {
            let card = test.1
            validator.inputValue = card
            let validationState = validator.validationState
            let expected = test.0
            if !(validationState == expected) {
                XCTFail("Expected \(expected), got \(validationState) for number \"\(card)\"")
            }
            let expectedCardBrand = test.2
            if !(validator.cardBrand == expectedCardBrand) {
                XCTFail(
                    "Expected \(expectedCardBrand), got \(validator.cardBrand) for number \(card)"
                )
            }
        }

        validator.inputValue = "1"
        XCTAssertEqual(
            .invalid(errorMessage: "Your card number is invalid."),
            validator.validationState
        )

        validator.inputValue = "0000000000000000"
        XCTAssertEqual(
            .invalid(errorMessage: "Your card number is invalid."),
            validator.validationState
        )

        validator.inputValue = "9999999999999995"
        XCTAssertEqual(
            .invalid(errorMessage: "Your card number is invalid."),
            validator.validationState
        )

        validator.inputValue = "0000000000000000000"
        XCTAssertEqual(
            .invalid(errorMessage: "Your card number is invalid."),
            validator.validationState
        )

        validator.inputValue = "9999999999999999998"
        XCTAssertEqual(
            .invalid(errorMessage: "Your card number is invalid."),
            validator.validationState
        )

        validator.inputValue = "4242424242424"
        XCTAssertEqual(
            .incomplete(description: "Your card number is incomplete."),
            validator.validationState
        )

        validator.inputValue = nil
        XCTAssertEqual(.incomplete(description: nil), validator.validationState)
    }
}

//
//  TextFieldElement+PANTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 2/25/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest
@_spi(STP) @testable import Stripe
@_spi(STP) @testable import StripeUICore
@_spi(STP) @testable import StripeCore

// ⚠️ If you run into mysteriously failing tests, beware: the code under test uses `STPBINRange`, a singleton whose state can't be reset ⚠️
// See https://jira.corp.stripe.com/browse/MOBILESDK-724
class TextFieldElementCardTest: XCTestCase {
    func testPANValidation() throws {
        // Set a publishable key for the metadata service
        STPAPIClient.shared.publishableKey = STPTestingDefaultPublishableKey
        typealias Error = TextFieldElement.PANConfiguration.Error
        let testcases: [String: TextFieldElement.ValidationState] = [
            "": .invalid(Error.empty),
            
            // Incomplete
            "4": .invalid(Error.incomplete),
            "424242424242": .invalid(Error.incomplete),
            "3622720627166" : .invalid(Error.incomplete),  // diners club (14 digit, but 13 digits given)
            
            // Unknown card brand
            "0000000000000000": .invalid(Error.invalidBrand),
            "1000000000000000": .invalid(Error.invalidBrand),
            "1234567812345678": .invalid(Error.invalidBrand),
            "9999999999999995": .invalid(Error.invalidBrand),
            "1234123412341234": .invalid(Error.invalidBrand),
            "9999999999999999999999": .invalid(Error.invalidBrand),
            
            // Fails luhn check
            "4012888888881889": .invalid(Error.invalidLuhn),
            "2223000010089809": .invalid(Error.invalidLuhn),
            "3530111333300009": .invalid(Error.invalidLuhn),
            "5105105105105109": .invalid(Error.invalidLuhn), // mastercard (prepaid)
            "6011111111111119": .invalid(Error.invalidLuhn), // discover
            "6200000000000009": .invalid(Error.invalidLuhn), // cup

            // Valid (luhn-passing) PANs
            "4012888888881881": .valid,
            "2223000010089800": .valid,
            "3530111333300000": .valid,
            "4242424242424242": .valid, // visa
            "4000056655665556": .valid, // visa (debit)
            "5555555555554444": .valid, // mastercard
            "2223003122003222": .valid, // mastercard (2-series)
            "5200828282828210": .valid, // mastercard (debit)
            "5105105105105100": .valid, // mastercard (prepaid)
            "378282246310005": .valid,  // amex
            "371449635398431": .valid,  // amex
            "6011111111111117": .valid, // discover
            "6011000990139424": .valid, // discover
            "3056930009020004": .valid, // diners club
            "36227206271667" : .valid,  // diners club (14 digit)
            "3566002020360505": .valid, // jcb
            "6200000000000005": .valid, // cup
            
            // Variable length PANs
            // We don't know the exact length without hitting the card metadata service, but if they pass luhn check they should be valid if the length is *possibly* valid
            "62435200000000": .invalid(Error.incomplete), // union pay (15 digits, too short)
            "6243520000000001": .valid, // union pay (16 digits)
            "6235510000000000009": .valid, // union pay (19 digits)
            
            // Non-US
            "4000000760000002": .valid, // br
            "4000001240000000": .valid, // ca
            "4000004840008001": .valid, // mx
        ]

        let configuration = TextFieldElement.PANConfiguration()
        for (text, expected) in testcases {
            let actual = configuration.simulateValidationState(text)
            XCTAssertTrue(
                actual == expected,
                "Input \"\(text)\": expected \(expected) but got \(actual)"
            )
        }
    }
    
    func testBINRangeThatRequiresNetworkCallToValidate() {
        // Set a publishable key for the metadata service
        STPAPIClient.shared.publishableKey = STPTestingDefaultPublishableKey
        let configuration = TextFieldElement.PANConfiguration()
        
        // Given a 19-digit Union Pay variable length number i.e., requires a network call in order to be know the correct length...
        // (I got this number from https://hubble.corp.stripe.com/queries/ek/5612e1d3)
        let unionPay19 = "6235510000000000009" // 19-digit, valid luhn Union Pay
        let unionPay19_but_16_digits_entered = "6235510000000002" // a 16-digit valid luhn Union Pay that should be 19 digits according to its BIN prefix.
        XCTAssertFalse(STPBINRange.hasBINRanges(forPrefix: unionPay19_but_16_digits_entered))
        XCTAssertFalse(STPBINRange.hasBINRanges(forPrefix: unionPay19))
        

        // ...we should allow a 16 digit number, since we don't know the correct length yet...
        XCTAssertEqual(
            configuration.simulateValidationState(unionPay19_but_16_digits_entered),
            .valid
        )
        
        // ...and load the BIN range.
        XCTAssertTrue(STPBINRange.isLoadingCardMetadata(forPrefix: unionPay19_but_16_digits_entered))
        
        // After we've loaded the bin range...
        let e = expectation(description: "Fetch BIN Range")
        STPBINRange.retrieveBINRanges(forPrefix: unionPay19_but_16_digits_entered) { _, _ in
            e.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
        XCTAssertTrue(STPBINRange.hasBINRanges(forPrefix: unionPay19_but_16_digits_entered))
        XCTAssertTrue(STPBINRange.hasBINRanges(forPrefix: unionPay19))
        // ...it should be considered incomplete
        XCTAssertEqual(
            configuration.simulateValidationState(unionPay19_but_16_digits_entered),
            .invalid(TextFieldElement.PANConfiguration.Error.incomplete)
        )
        
    }

    func testCVCValidation() {
        let emptyError = TextFieldElement.Error.empty
        let incompleteError = TextFieldElement.Error.incomplete(localizedDescription: .Localized.your_cards_security_code_is_incomplete)
        let testcases: [(String, STPCardBrand, TextFieldElement.ValidationState)] = [
            // VISA CVC are 3 digits
            ("", .visa, .invalid(emptyError)),
            ("1", .visa, .invalid(incompleteError)),
            ("12", .visa, .invalid(incompleteError)),
            ("123", .visa, .valid),
            
            // Unknown card brand allows 3 or 4 digits
            ("", .unknown, .invalid(emptyError)),
            ("1", .unknown, .invalid(incompleteError)),
            ("12", .unknown, .invalid(incompleteError)),
            ("123", .unknown, .valid),
            ("1234", .unknown, .valid),
            
            // Amex CVV allow 3 or 4 digits
            ("", .amex, .invalid(emptyError)),
            ("1", .amex, .invalid(incompleteError)),
            ("12", .amex, .invalid(incompleteError)),
            ("123", .amex, .valid),
            ("1234", .amex, .valid),
        ]
        for (text, brand, expected) in testcases {
            let config = TextFieldElement.CVCConfiguration {
                return brand
            }
            let actual = config.simulateValidationState(text)
            XCTAssertTrue(
                actual == expected,
                "Input \"\(text), \(brand)\": expected \(expected) but got \(actual)"
            )
        }
    }
    
    func testExpiryValidation() {
        typealias Error = TextFieldElement.ExpiryDateConfiguration.Error
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMYY"
        let firstDayOfThisMonth = Calendar.current.date(bySetting: .day, value: 1, of: Date())
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: firstDayOfThisMonth!)
        
        let testcases: [String: TextFieldElement.ValidationState] = [
            // Test empty -> incomplete -> complete
            "": .invalid(TextFieldElement.Error.empty),
            "0": .invalid(Error.incomplete),
            "1": .invalid(Error.incomplete),
            "12": .invalid(Error.incomplete),
            "12/2": .invalid(Error.incomplete),
            "12/50": .valid,
            
            // Test invalid months
            "00": .invalid(Error.invalidMonth),
            "00/9": .invalid(Error.invalidMonth),
            "00/99": .invalid(Error.invalidMonth),
            "2": .invalid(Error.invalidMonth),
            "13": .invalid(Error.invalidMonth),
            
            // Test expired dates
            "12/21": .invalid(Error.invalid),
            "01/22": .invalid(Error.invalid),
            dateFormatter.string(from: oneMonthAgo!): .invalid(Error.invalid),
        ]
        let configuration = TextFieldElement.ExpiryDateConfiguration()
        for (text, expected) in testcases {
            let actual = configuration.simulateValidationState(text)
            XCTAssertTrue(
                actual == expected,
                "Input \"\(text)\": expected \(expected) but got \(actual)"
            )
        }
    }
    
    func testExpiryDisplayText() {
        let configuration = TextFieldElement.ExpiryDateConfiguration()
        let textFieldElement = TextFieldElement(configuration: configuration)
        
        let testcases = [
            "0": "0",
            "1": "1",
            "2": "02",
            "3": "03",
            "4": "04",
            "5": "05",
            "6": "06",
            "7": "07",
            "8": "08",
            "9": "09",
            "10": "10",
            "102": "10/2",
            "1021": "10/21",
        ]
        
        for (text, expected) in testcases {
            // Simulate user input
           textFieldElement.textFieldView.textField.text = text
           textFieldElement.textFieldView.textDidChange()
           let actual = textFieldElement.textFieldView.textField.text
            XCTAssertTrue(
                actual == expected,
                "Input \"\(text)\": expected \(expected) but got \(actual!)"
            )
        }
    }
}

extension TextFieldElementConfiguration {
    // MARK: - Helpers
    func simulateValidationState(_ input: String) -> TextFieldElement.ValidationState {
        let textFieldElement = TextFieldElement(configuration: self)
        textFieldElement.textFieldView.textField.text = input
        textFieldElement.textFieldView.textDidChange()
        return textFieldElement.validationState
    }
}

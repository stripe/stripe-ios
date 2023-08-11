//
//  STPBlikCodeValidator.swift
//  StripeUICoreTests
//
//  Created by Fionn Barrett on 07/07/2023.
//

import Foundation
@_spi(STP) import StripeUICore
import XCTest

class STPBlikCodeValidatorTest: XCTestCase {
    func testBlikCode_0() {
        XCTAssertFalse(STPBlikCodeValidator.stringIsValidBlikCode("0"))
    }
    func testBlikCode_valid() {
        XCTAssertTrue(STPBlikCodeValidator.stringIsValidBlikCode("123456"))
    }

    func testBlikCode_lessThanSixDigits() {
        XCTAssertFalse(STPBlikCodeValidator.stringIsValidBlikCode("1234"))
    }

    func testBlikCode_moreThanSixDigits() {
        XCTAssertFalse(STPBlikCodeValidator.stringIsValidBlikCode("1234567"))
    }

    func testBlikCode_nil() {
        XCTAssertFalse(STPBlikCodeValidator.stringIsValidBlikCode(nil))
    }

    func testBlikCode_nonNumeric() {
        XCTAssertFalse(STPBlikCodeValidator.stringIsValidBlikCode("12a456"))
        XCTAssertFalse(STPBlikCodeValidator.stringIsValidBlikCode("abcdef"))
        XCTAssertFalse(STPBlikCodeValidator.stringIsValidBlikCode("stripe.com"))
    }
}

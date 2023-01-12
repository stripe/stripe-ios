//
//  STPCardCVCInputTextFieldFormatterTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 10/28/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPCardCVCInputTextFieldFormatterTests: XCTestCase {

    func testAllowedInput() {
        let formatter = STPCardCVCInputTextFieldFormatter()

        formatter.cardBrand = .unknown
        XCTAssertTrue(formatter.isAllowedInput("1", to: "", at: NSRange(location: 0, length: 1)))
        XCTAssertTrue(formatter.isAllowedInput("12", to: "", at: NSRange(location: 0, length: 2)))
        XCTAssertTrue(formatter.isAllowedInput("2", to: "1", at: NSRange(location: 1, length: 1)))
        XCTAssertTrue(formatter.isAllowedInput("3", to: "12", at: NSRange(location: 2, length: 1)))
        XCTAssertTrue(formatter.isAllowedInput("123", to: "", at: NSRange(location: 0, length: 1)))
        XCTAssertTrue(formatter.isAllowedInput("4", to: "123", at: NSRange(location: 3, length: 1)))
        XCTAssertFalse(formatter.isAllowedInput("5", to: "1234", at: NSRange(location: 4, length: 1)))

        formatter.cardBrand = .amex
        XCTAssertTrue(formatter.isAllowedInput("1", to: "", at: NSRange(location: 0, length: 1)))
        XCTAssertTrue(formatter.isAllowedInput("12", to: "", at: NSRange(location: 0, length: 2)))
        XCTAssertTrue(formatter.isAllowedInput("2", to: "1", at: NSRange(location: 1, length: 1)))
        XCTAssertTrue(formatter.isAllowedInput("3", to: "12", at: NSRange(location: 2, length: 1)))
        XCTAssertTrue(formatter.isAllowedInput("123", to: "", at: NSRange(location: 0, length: 1)))
        XCTAssertTrue(formatter.isAllowedInput("4", to: "123", at: NSRange(location: 3, length: 1)))
        XCTAssertFalse(formatter.isAllowedInput("5", to: "1234", at: NSRange(location: 4, length: 1)))

        formatter.cardBrand = .visa
        XCTAssertTrue(formatter.isAllowedInput("1", to: "", at: NSRange(location: 0, length: 1)))
        XCTAssertTrue(formatter.isAllowedInput("12", to: "", at: NSRange(location: 0, length: 2)))
        XCTAssertTrue(formatter.isAllowedInput("2", to: "1", at: NSRange(location: 1, length: 1)))
        XCTAssertTrue(formatter.isAllowedInput("3", to: "12", at: NSRange(location: 2, length: 1)))
        XCTAssertTrue(formatter.isAllowedInput("123", to: "", at: NSRange(location: 0, length: 1)))
        XCTAssertFalse(formatter.isAllowedInput("4", to: "123", at: NSRange(location: 3, length: 1)))
        XCTAssertFalse(formatter.isAllowedInput("5", to: "1234", at: NSRange(location: 4, length: 1)))

        XCTAssertFalse(formatter.isAllowedInput("a", to: "123", at: NSRange(location: 0, length: 1)))
    }

}

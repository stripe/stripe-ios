//
//  STPCardCVCInputTextFieldFormatterTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 10/28/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import XCTest

@testable import Stripe

class STPCardCVCInputTextFieldFormatterTests: XCTestCase {

    func testAllowedInput() {
        let formatter = STPCardCVCInputTextFieldFormatter()

        formatter.cardBrand = .unknown
        XCTAssertTrue(formatter.isAllowedInput("1", to: "", at: NSMakeRange(0, 1)))
        XCTAssertTrue(formatter.isAllowedInput("12", to: "", at: NSMakeRange(0, 2)))
        XCTAssertTrue(formatter.isAllowedInput("2", to: "1", at: NSMakeRange(1, 1)))
        XCTAssertTrue(formatter.isAllowedInput("3", to: "12", at: NSMakeRange(2, 1)))
        XCTAssertTrue(formatter.isAllowedInput("123", to: "", at: NSMakeRange(0, 1)))
        XCTAssertTrue(formatter.isAllowedInput("4", to: "123", at: NSMakeRange(3, 1)))
        XCTAssertFalse(formatter.isAllowedInput("5", to: "1234", at: NSMakeRange(4, 1)))

        formatter.cardBrand = .amex
        XCTAssertTrue(formatter.isAllowedInput("1", to: "", at: NSMakeRange(0, 1)))
        XCTAssertTrue(formatter.isAllowedInput("12", to: "", at: NSMakeRange(0, 2)))
        XCTAssertTrue(formatter.isAllowedInput("2", to: "1", at: NSMakeRange(1, 1)))
        XCTAssertTrue(formatter.isAllowedInput("3", to: "12", at: NSMakeRange(2, 1)))
        XCTAssertTrue(formatter.isAllowedInput("123", to: "", at: NSMakeRange(0, 1)))
        XCTAssertTrue(formatter.isAllowedInput("4", to: "123", at: NSMakeRange(3, 1)))
        XCTAssertFalse(formatter.isAllowedInput("5", to: "1234", at: NSMakeRange(4, 1)))

        formatter.cardBrand = .visa
        XCTAssertTrue(formatter.isAllowedInput("1", to: "", at: NSMakeRange(0, 1)))
        XCTAssertTrue(formatter.isAllowedInput("12", to: "", at: NSMakeRange(0, 2)))
        XCTAssertTrue(formatter.isAllowedInput("2", to: "1", at: NSMakeRange(1, 1)))
        XCTAssertTrue(formatter.isAllowedInput("3", to: "12", at: NSMakeRange(2, 1)))
        XCTAssertTrue(formatter.isAllowedInput("123", to: "", at: NSMakeRange(0, 1)))
        XCTAssertFalse(formatter.isAllowedInput("4", to: "123", at: NSMakeRange(3, 1)))
        XCTAssertFalse(formatter.isAllowedInput("5", to: "1234", at: NSMakeRange(4, 1)))

        XCTAssertFalse(formatter.isAllowedInput("a", to: "123", at: NSMakeRange(0, 1)))
    }

}

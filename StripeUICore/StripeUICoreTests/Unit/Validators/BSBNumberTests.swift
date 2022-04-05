//
//  BSBNumberTests.swift
//  StripeUICoreTests
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest

@_spi(STP) @testable import StripeUICore

class BSBNumberTests: XCTestCase {
    func testBSBNumber_0() {
        let bsbNumber = BSBNumber(number: "0")
        XCTAssertFalse(bsbNumber.isComplete)
        XCTAssertEqual(bsbNumber.formattedNumber(), "0")
        XCTAssertEqual(bsbNumber.bsbNumberText(), "0")
    }
    func testBSBNumber_01() {
        let bsbNumber = BSBNumber(number: "00")
        XCTAssertFalse(bsbNumber.isComplete)
        XCTAssertEqual(bsbNumber.formattedNumber(), "00")
        XCTAssertEqual(bsbNumber.bsbNumberText(), "00")
    }

    func testBSBNumber_012() {
        let bsbNumber = BSBNumber(number: "012")
        XCTAssertFalse(bsbNumber.isComplete)
        XCTAssertEqual(bsbNumber.formattedNumber(), "012")
        XCTAssertEqual(bsbNumber.bsbNumberText(), "012")
    }

    func testBSBNumber_0123() {
        let bsbNumber = BSBNumber(number: "0123")
        XCTAssertFalse(bsbNumber.isComplete)
        XCTAssertEqual(bsbNumber.formattedNumber(), "012-3")
        XCTAssertEqual(bsbNumber.bsbNumberText(), "0123")
    }
    
    func testBSBNumber_01234() {
        let bsbNumber = BSBNumber(number: "01234")
        XCTAssertFalse(bsbNumber.isComplete)
        XCTAssertEqual(bsbNumber.formattedNumber(), "012-34")
        XCTAssertEqual(bsbNumber.bsbNumberText(), "01234")
    }

    func testBSBNumber_012345() {
        let bsbNumber = BSBNumber(number: "012345")
        XCTAssert(bsbNumber.isComplete)
        XCTAssertEqual(bsbNumber.formattedNumber(), "012-345")
        XCTAssertEqual(bsbNumber.bsbNumberText(), "012345")
    }

    func testBSBNumber_012_withdash() {
        let bsbNumber = BSBNumber(number: "012-")
        XCTAssertFalse(bsbNumber.isComplete)
        XCTAssertEqual(bsbNumber.formattedNumber(), "012")
        XCTAssertEqual(bsbNumber.bsbNumberText(), "012")
    }

    func testBSBNumber_0123_withdash() {
        let bsbNumber = BSBNumber(number: "012-3")
        XCTAssertFalse(bsbNumber.isComplete)
        XCTAssertEqual(bsbNumber.formattedNumber(), "012-3")
        XCTAssertEqual(bsbNumber.bsbNumberText(), "0123")
    }
    
    func testBSBNumber_01234_withdash() {
        let bsbNumber = BSBNumber(number: "012-34")
        XCTAssertFalse(bsbNumber.isComplete)
        XCTAssertEqual(bsbNumber.formattedNumber(), "012-34")
        XCTAssertEqual(bsbNumber.bsbNumberText(), "01234")
    }

    func testBSBNumber_012345_withdash() {
        let bsbNumber = BSBNumber(number: "012-345")
        XCTAssert(bsbNumber.isComplete)
        XCTAssertEqual(bsbNumber.formattedNumber(), "012-345")
        XCTAssertEqual(bsbNumber.bsbNumberText(), "012345")
    }
}

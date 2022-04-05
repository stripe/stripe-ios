//
//  BSBNumberProviderTest.swift
//  StripeUICoreTests
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest
@_spi(STP) @testable import StripeUICore

class BSBNumberProviderTest: XCTestCase {
    var sut: BSBNumberProvider! = nil

    override func setUp() {
        sut = BSBNumberProvider.shared
        let e = expectation(description: "")

        XCTAssert(sut.bsbNumberToNameMapping.isEmpty)
        sut.loadBSBData {
            e.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertFalse(sut.bsbNumberToNameMapping.isEmpty)
    }

    override func tearDown() {
        sut.bsbNumberToNameMapping = [:]
        sut = nil
    }

    func testBankName_10() {
        let bsbName = sut.bsbName(for: "10")
        XCTAssertEqual(bsbName, "BankSA (division of Westpac Bank)")
    }
    func testLoads_fullBSB() {
        let bsbName = sut.bsbName(for: "100-000")
        XCTAssertEqual(bsbName, "BankSA (division of Westpac Bank)")
    }
    func testBankName_2char() {
        let bsbName = sut.bsbName(for: "09")
        XCTAssertEqual(bsbName, "Reserve Bank of Australia")
    }
    func testBankName_3char() {
        let bsbName = sut.bsbName(for: "091")
        XCTAssertEqual(bsbName, "Reserve Bank of Australia")
    }
    func testBankName_4char() {
        let bsbName = sut.bsbName(for: "091-")
        XCTAssertEqual(bsbName, "Reserve Bank of Australia")
    }
    func testBankName_5char() {
        let bsbName = sut.bsbName(for: "091-0")
        XCTAssertEqual(bsbName, "Reserve Bank of Australia")
    }
    func testBankName_6char() {
        let bsbName = sut.bsbName(for: "091-01")
        XCTAssertEqual(bsbName, "Reserve Bank of Australia")
    }
    func testBSBSingleChar() {
        let bsbName = sut.bsbName(for: "0")
        XCTAssertEqual(bsbName, "")
    }
    func testBSBEmpty() {
        let bsbName = sut.bsbName(for: "")
        XCTAssertEqual(bsbName, "")
    }
    func testInvalidBank1() {
        let bsbName = sut.bsbName(for: "0")
        XCTAssertEqual(bsbName, "")
    }
    func testInvalidBank2() {
        let bsbName = sut.bsbName(for: "560-111")
        XCTAssertEqual(bsbName, "")
    }

}

//
//  STPStringUtilsTest.swift
//  StripeiOS Tests
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPStringUtilsTest: XCTestCase {
    func testParseRangeSingleTagSuccess1() {
        let exp = self.expectation(description: "Parsed")
        STPStringUtils.parseRange(
            from: "Test <b>string</b>",
            withTag: "b"
        ) { string, range in
            XCTAssertTrue(NSEqualRanges(range, NSRange(location: 5, length: 6)))
            XCTAssertEqual(string, "Test string")
            exp.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testParseRangeSingleTagSuccess2() {
        let exp = self.expectation(description: "Parsed")
        STPStringUtils.parseRange(
            from: "<a>Test <b>str</a>ing</b>",
            withTag: "b"
        ) { string, range in
            XCTAssertTrue(NSEqualRanges(range, NSRange(location: 8, length: 10)))
            XCTAssertEqual(string, "<a>Test str</a>ing")
            exp.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testParseRangeSingleTagFailure1() {
        let exp = self.expectation(description: "Parsed")
        STPStringUtils.parseRange(
            from: "Test <b>string</b>",
            withTag: "a"
        ) { string, range in
            XCTAssertEqual(range.location, NSNotFound)
            XCTAssertEqual(string, "Test <b>string</b>")
            exp.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testParseRangeSingleTagFailure2() {
        let exp = self.expectation(description: "Parsed")
        STPStringUtils.parseRange(
            from: "Test <b>string",
            withTag: "b"
        ) { string, range in
            XCTAssertEqual(range.location, NSNotFound)
            XCTAssertEqual(string, "Test <b>string")
            exp.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testParseRangeMultiTag1() {
        let exp = self.expectation(description: "Parsed")
        STPStringUtils.parseRanges(
            from: "<a>Test</a> <b>string</b>",
            withTags: Set(["a", "b", "c"])
        ) { string, tagMap in
            XCTAssertTrue(NSEqualRanges(tagMap["a"]!.rangeValue, NSRange(location: 0, length: 4)))
            XCTAssertTrue(NSEqualRanges(tagMap["b"]!.rangeValue, NSRange(location: 5, length: 6)))
            XCTAssertEqual(tagMap["c"]!.rangeValue.location, NSNotFound)
            XCTAssertEqual(string, "Test string")
            exp.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testParseRangeMultiTag2() {
        let exp = self.expectation(description: "Parsed")
        STPStringUtils.parseRanges(from: "Test string", withTags: Set(["a", "b", "c"])) {
            string,
            tagMap in
            XCTAssertEqual(tagMap["a"]!.rangeValue.location, NSNotFound)
            XCTAssertEqual(tagMap["b"]!.rangeValue.location, NSNotFound)
            XCTAssertEqual(tagMap["c"]!.rangeValue.location, NSNotFound)
            XCTAssertEqual(string, "Test string")
            exp.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
    func testParseRangeWithOverlappingRanges() {
        let exp = self.expectation(description: "Parsed")
        STPStringUtils.parseRanges(
            from: "<a>Test <b>string</b></a>",
            withTags: Set(["a", "b"])
        ) { string, tagMap in
            XCTAssertEqual(string, "Test string")
            XCTAssertTrue(tagMap.isEmpty)
            exp.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
    func testHasOverlappingRanges_singleItem() {
        let ranges: [NSValue: String] = [
            NSValue(range: NSRange(location: 0, length: 2)): "a",
        ]
        XCTAssertFalse(STPStringUtils.hasOverlappingRanges(ranges: ranges))
    }
    func testHasOverlappingRanges_nonOverlapping() {
        let ranges: [NSValue: String] = [
            NSValue(range: NSRange(location: 0, length: 2)): "a",
            NSValue(range: NSRange(location: 2, length: 1)): "b",
        ]
        XCTAssertFalse(STPStringUtils.hasOverlappingRanges(ranges: ranges))
    }
    func testHasOverlappingRanges_overlapping() {
        let ranges: [NSValue: String] = [
            NSValue(range: NSRange(location: 0, length: 2)): "a",
            NSValue(range: NSRange(location: 1, length: 1)): "b",
        ]
        XCTAssert(STPStringUtils.hasOverlappingRanges(ranges: ranges))
    }

    func testExpirationDateStrings() {
        XCTAssertEqual(STPStringUtils.expirationDateString(from: "12/1995"), "12/95")
        XCTAssertEqual(STPStringUtils.expirationDateString(from: "12 / 1995"), "12 / 95")
        XCTAssertEqual(STPStringUtils.expirationDateString(from: "12 /1995"), "12 /95")
        XCTAssertEqual(STPStringUtils.expirationDateString(from: "1295"), "1295")
        XCTAssertEqual(STPStringUtils.expirationDateString(from: "12/95"), "12/95")
        XCTAssertEqual(STPStringUtils.expirationDateString(from: "08/2001"), "08/01")
        XCTAssertEqual(STPStringUtils.expirationDateString(from: " 08/a 2001"), " 08/a 2001")
        XCTAssertEqual(STPStringUtils.expirationDateString(from: "20/2022"), "20/22")
        XCTAssertEqual(STPStringUtils.expirationDateString(from: "20/202222"), "20/22")
        XCTAssertEqual(STPStringUtils.expirationDateString(from: ""), "")
        XCTAssertEqual(STPStringUtils.expirationDateString(from: " "), " ")
        XCTAssertEqual(STPStringUtils.expirationDateString(from: "12/"), "12/")
    }

    func testSanitizedExpirationDateFromOCRString() {
        XCTAssertEqual(STPStringUtils.sanitizedExpirationDateFromOCRString("12/1995"), "1295")
        XCTAssertEqual(STPStringUtils.sanitizedExpirationDateFromOCRString("12/95"), "1295")
        XCTAssertEqual(STPStringUtils.sanitizedExpirationDateFromOCRString("Security Code 123 Valid Thru 01/35"), "0135")
        XCTAssertEqual(STPStringUtils.sanitizedExpirationDateFromOCRString("BankCo Logo Is Copyright 1995 BankCo Call us at 888-555-5555 Expiration date 01/35 Security Code 123"), "0135")
        XCTAssertEqual(STPStringUtils.sanitizedExpirationDateFromOCRString("Made with 10% recycled plastic, 45% organic matter. Expiration date 01/35"), "0135")
        XCTAssertEqual(STPStringUtils.sanitizedExpirationDateFromOCRString("Expiration date 01/35, card produced 01/23"), "0135")
        XCTAssertEqual(STPStringUtils.sanitizedExpirationDateFromOCRString("Expiration date 01 35"), nil)
        XCTAssertEqual(STPStringUtils.sanitizedExpirationDateFromOCRString("AA/BB"), nil)
    }
}

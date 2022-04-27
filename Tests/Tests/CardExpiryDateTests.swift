//
//  CardExpiryDateTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 4/15/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest

@testable import Stripe

class CardExpiryDateTests: XCTestCase {

    func test_init() {
        let sut = CardExpiryDate(month: 2, year: 2026)
        XCTAssertEqual(sut.month, 2)
        XCTAssertEqual(sut.year, 2026)
    }

    func test_init_shouldNormalizeTheYear() {
        let sut = CardExpiryDate(month: 2, year: 50)
        XCTAssertEqual(sut.year, 2050)
    }

    func test_initFromString() {
        let sut = CardExpiryDate("0226")
        XCTAssertEqual(sut?.month, 2)
        XCTAssertEqual(sut?.year, 2026)
    }

    func test_initFromString_withInvalidString() {
        XCTAssertNil(CardExpiryDate("")) // empty
        XCTAssertNil(CardExpiryDate("0")) // missing 3 digits
        XCTAssertNil(CardExpiryDate("023")) // missing a digit
        XCTAssertNil(CardExpiryDate("1234567890")) // too many digits
        XCTAssertNil(CardExpiryDate("abcd")) // alpha

        // month out of range
        XCTAssertNil(CardExpiryDate("1326"))
        XCTAssertNil(CardExpiryDate("0026"))
        XCTAssertNil(CardExpiryDate("-126"))

        // year out of range
        XCTAssertNil(CardExpiryDate("02-1"))
    }

    func test_displayString() {
        let sut = CardExpiryDate(month: 2, year: 2026)
        XCTAssertEqual(sut.displayString, "0226")
    }

    func test_expired() throws {
        let calendar = Calendar(identifier: .gregorian)

        let sut = CardExpiryDate(month: 2, year: 2026)

        let aDayBefore   = try XCTUnwrap(calendar.date(from: .init(year: 2026, month: 2, day: 28)))
        let aMonthBefore = try XCTUnwrap(calendar.date(from: .init(year: 2026, month: 1, day: 31)))
        let aDayAfter    = try XCTUnwrap(calendar.date(from: .init(year: 2026, month: 3, day: 1)))
        let aMonthAfter  = try XCTUnwrap(calendar.date(from: .init(year: 2026, month: 3, day: 30)))

        XCTAssertFalse(sut.expired(now: aDayBefore))
        XCTAssertFalse(sut.expired(now: aMonthBefore))
        XCTAssertTrue(sut.expired(now: aDayAfter))
        XCTAssertTrue(sut.expired(now: aMonthAfter))
    }

}

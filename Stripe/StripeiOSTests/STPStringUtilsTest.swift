//
//  STPStringUtilsTest.swift
//  StripeiOS Tests
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePaymentsUI

class STPStringUtilsTest: XCTestCase {
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
}

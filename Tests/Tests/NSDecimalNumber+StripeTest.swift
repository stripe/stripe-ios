//
//  NSDecimalNumber+StripeTest.swift
//  StripeiOS Tests
//
//  Created by Ben Guo on 4/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentsUI

class NSDecimalNumberStripeTest: XCTestCase {
    func testDecimalAmount_hasDecimal() {
        let decimalNumber = NSDecimalNumber.stp_decimalNumber(withAmount: 1000, currency: "usd")
        XCTAssertEqual(decimalNumber, NSDecimalNumber(string: "10.00"))
    }

    func testDecimalAmount_noDecimal() {
        let decimalNumber = NSDecimalNumber.stp_decimalNumber(withAmount: 1000, currency: "jpy")
        XCTAssertEqual(decimalNumber, NSDecimalNumber(string: "1000"))
    }
    
    func testDecimalAmount_threeDecimal() {
        let decimalNumber = NSDecimalNumber.stp_decimalNumber(withAmount: 92000, currency: "kwd")
        XCTAssertEqual(decimalNumber, NSDecimalNumber(string: "92"))
    }
}

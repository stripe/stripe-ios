//
//  NSDecimalNumber+StripeTest.swift
//  Stripe
//
//  Created by Ben Guo on 4/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

@testable import Stripe

class NSDecimalNumberStripeTest: XCTestCase {
  func testDecimalAmount_hasDecimal() {
    let decimalNumber = NSDecimalNumber.stp_decimalNumber(withAmount: 1000, currency: "usd")
    XCTAssertEqual(decimalNumber, NSDecimalNumber(string: "10.00"))
  }

  func testDecimalAmount_noDecimal() {
    let decimalNumber = NSDecimalNumber.stp_decimalNumber(withAmount: 1000, currency: "jpy")
    XCTAssertEqual(decimalNumber, NSDecimalNumber(string: "1000"))
  }
}

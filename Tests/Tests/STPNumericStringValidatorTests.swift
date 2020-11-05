//
//  STPNumericStringValidatorTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 3/13/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//
@testable import Stripe

class STPNumericStringValidatorTests: XCTestCase {
  func testNumberSanitization() {
    let tests = [
      ["4242424242424242", "4242424242424242"],
      ["XXXXXX", ""],
      ["424242424242424X", "424242424242424"],
      ["X4242", "4242"],
      ["4242 4242 4242 4242", "4242424242424242"],
      ["123-456-", "123456"],
    ]
    for test in tests {
      XCTAssertEqual(STPNumericStringValidator.sanitizedNumericString(for: test[0]), test[1])
    }
  }

  func testIsStringNumeric() {
    let tests = [
      ["4242424242424242", NSNumber(value: true)],
      ["XXXXXX", NSNumber(value: false)],
      ["424242424242424X", NSNumber(value: false)],
      ["X4242", NSNumber(value: false)],
      ["4242 4242 4242 4242", NSNumber(value: false)],
      ["123-456-", NSNumber(value: false)],
      ["    1", NSNumber(value: false)],
      ["", NSNumber(value: true)],
    ]
    for test in tests {
      let first = STPNumericStringValidator.isStringNumeric(test[0] as! String)
      let second = (test[1] as! NSNumber).boolValue
      XCTAssertEqual(first, second)
    }
  }
}

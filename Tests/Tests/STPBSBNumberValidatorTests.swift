//
//  STPBSBNumberValidatorTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 3/13/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

@testable import Stripe

class STPBSBNumberValidatorTests: XCTestCase {
  func testValidationStateForText() {
    let tests: [(String, STPTextValidationState)] = [
      ("", .empty),
      ("1", .incomplete),
      ("11", .incomplete),
      ("00", .invalid),
      ("111111", .complete),
      ("111-111", .complete),
      ("--111-111--", .complete),
      ("1234567", .invalid),
    ]

    for test in tests {
      XCTAssertEqual(STPBSBNumberValidator.validationState(forText: test.0), test.1)
    }
  }

  func testformattedSanitizedTextFromString() {
    let tests = [
      ["", ""],
      ["1", "1"],
      ["11", "11"],
      ["111", "111-"],
      ["111111", "111-111"],
      ["--111111--", "111-111"],
      ["1234567", "123-456"],
    ]

    for test in tests {
      XCTAssertEqual(STPBSBNumberValidator.formattedSanitizedText(from: test[0]), test[1])
    }
  }

  func testIdentityForText() {
    let tests = [
      ["", NSNull()],
      ["9", NSNull()],
      ["94", NSNull()],
      ["941", "Delphi Bank (division of Bendigo and Adelaide Bank)"],
      ["942", "Bank of Sydney"],
      ["942942", "Bank of Sydney"],
      ["40", "Commonwealth Bank of Australia"],
      ["942-942", "Bank of Sydney"],
      ["942942111", "Bank of Sydney"],
    ]

    for test in tests {
      if test[1] as! NSObject == NSNull() {
        XCTAssertNil(STPBSBNumberValidator.identity(forText: test[0] as! String))
      } else {
        XCTAssertEqual(
          STPBSBNumberValidator.identity(forText: test[0] as! String), test[1] as? String)
      }
    }
  }

  func testIconForText() {
    let defaultIcon = STPBSBNumberValidator.icon(forText: nil)
    XCTAssertNotNil(defaultIcon, "Nil default icon")

    XCTAssertEqual(defaultIcon, STPBSBNumberValidator.icon(forText: "00"))

    let bankIcon = STPBSBNumberValidator.icon(forText: "11")
    XCTAssertNotNil(bankIcon, "Nil icon for bank `11`")
    XCTAssertFalse((defaultIcon == bankIcon), "Icon for `11` is same as default")

    XCTAssertEqual(bankIcon, STPBSBNumberValidator.icon(forText: "111-111"))
  }
}

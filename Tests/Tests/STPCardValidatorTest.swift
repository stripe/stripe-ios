//
//  STPCardValidatorTest.swift
//  Stripe
//
//  Created by Jack Flintermann on 7/24/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

import UIKit
import XCTest

@testable import Stripe

class STPCardValidatorTest: XCTestCase {
  static let cardData: [(STPCardBrand, String, STPCardValidationState)] = {
    return [
      (
        .visa,
        "4242424242424242",
        .valid
      ),
      (
        .visa,
        "4242424242422",
        .incomplete
      ),
      (
        .visa,
        "4012888888881881",
        .valid
      ),
      (
        .visa,
        "4000056655665556",
        .valid
      ),
      (
        .mastercard,
        "5555555555554444",
        .valid
      ),
      (
        .mastercard,
        "5200828282828210",
        .valid
      ),
      (
        .mastercard,
        "5105105105105100",
        .valid
      ),
      (
        .mastercard,
        "2223000010089800",
        .valid
      ),
      (
        .amex,
        "378282246310005",
        .valid
      ),
      (
        .amex,
        "371449635398431",
        .valid
      ),
      (
        .discover,
        "6011111111111117",
        .valid
      ),
      (
        .discover,
        "6011000990139424",
        .valid
      ),
      (
        .dinersClub,
        "36227206271667",
        .valid
      ),
      (
        .dinersClub,
        "3056930009020004",
        .valid
      ),
      (
        .JCB,
        "3530111333300000",
        .valid
      ),
      (
        .JCB,
        "3566002020360505",
        .valid
      ),
      (
        .unknown,
        "1234567812345678",
        .invalid
      ),
    ]
  }()

  func testNumberSanitization() {
    let tests = [
      ["4242424242424242", "4242424242424242"],
      ["XXXXXX", ""],
      ["424242424242424X", "424242424242424"],
      ["X4242", "4242"],
      ["4242 4242 4242 4242", "4242424242424242"],
    ]
    for test in tests {
      XCTAssertEqual(STPCardValidator.sanitizedNumericString(for: test[0]), test[1])
    }
  }

  func testNumberValidation() {
    var tests: [(STPCardValidationState, String)] = []

    for card in STPCardValidatorTest.cardData {
      tests.append((card.2, card.1))
    }

    tests.append((.valid, "4242 4242 4242 4242"))
    tests.append((.valid, "4136000000008"))

    let badCardNumbers = [
      "0000000000000000",
      "9999999999999995",
      "1",
      "1234123412341234",
      "xxx",
      "9999999999999999999999",
      "42424242424242424242",
      "4242-4242-4242-4242",
    ]

    for card in badCardNumbers {
      tests.append((.invalid, card))
    }

    let possibleCardNumbers = ["4242", "5", "3", "", "    ", "6011", "4012888888881"]

    for card in possibleCardNumbers {
      tests.append((.incomplete, card))
    }

    for test in tests {
      let card = test.1
      let validationState = STPCardValidator.validationState(
        forNumber: card, validatingCardBrand: true)
      let expected = test.0
      if !(validationState == expected) {
        XCTFail("Expected \(expected), got \(validationState) for number \(card)")
      }
    }

    XCTAssertEqual(
      .incomplete, STPCardValidator.validationState(forNumber: "1", validatingCardBrand: false))
    XCTAssertEqual(
      .incomplete,
      STPCardValidator.validationState(forNumber: "0000000000000000", validatingCardBrand: false))
    XCTAssertEqual(
      .incomplete,
      STPCardValidator.validationState(forNumber: "9999999999999995", validatingCardBrand: false))
    XCTAssertEqual(
      .valid,
      STPCardValidator.validationState(forNumber: "0000000000000000000", validatingCardBrand: false)
    )
    XCTAssertEqual(
      .valid,
      STPCardValidator.validationState(forNumber: "9999999999999999998", validatingCardBrand: false)
    )
    XCTAssertEqual(
      .incomplete,
      STPCardValidator.validationState(forNumber: "4242424242424", validatingCardBrand: true))
    XCTAssertEqual(
      .incomplete, STPCardValidator.validationState(forNumber: nil, validatingCardBrand: true))
  }

  func testBrand() {
    for test in STPCardValidatorTest.cardData {
      XCTAssertEqual(STPCardValidator.brand(forNumber: test.1), test.0)
    }
  }

  func testLengthsForCardBrand() {
    let tests: [(STPCardBrand, Set<Int>)] = [
      (.visa, Set([13, 16])),
      (.mastercard, Set([16])),
      (.amex, Set([15])),
      (.discover, Set([16])),
      (.dinersClub, Set([14, 16])),
      (.JCB, Set([16])),
      (.unionPay, Set([16])),
      (.unknown, Set([19])),
    ]
    for test in tests {
      let lengths = STPCardValidator.lengths(for: test.0) as NSSet
      let expected = test.1 as NSSet
      if !lengths.isEqual(expected) {
        XCTFail("Invalid lengths for brand \(test.0): expected \(expected), got \(lengths)")
      }
    }
  }

  func testFragmentLength() {
    let tests: [(STPCardBrand, Int)] = [
      (.visa, 4),
      (.mastercard, 4),
      (.amex, 5),
      (.discover, 4),
      (.dinersClub, 4),
      (.JCB, 4),
      (.unionPay, 4),
      (.unknown, 4),
    ]
    for test in tests {
      XCTAssertEqual(STPCardValidator.fragmentLength(for: test.0), test.1)
    }
  }

  func testMonthValidation() {
    let tests: [(String, STPCardValidationState)] = [
      ("", .incomplete),
      ("0", .incomplete),
      ("1", .incomplete),
      ("2", .valid),
      ("9", .valid),
      ("10", .valid),
      ("12", .valid),
      ("13", .invalid),
      ("11a", .invalid),
      ("x", .invalid),
      ("100", .invalid),
      ("00", .invalid),
      ("13", .invalid),
    ]
    for test in tests {
      XCTAssertEqual(STPCardValidator.validationState(forExpirationMonth: test.0), test.1)
    }
  }

  func testYearValidation() {
    let tests: [(String, String, STPCardValidationState)] = [
      ("12", "15", .valid),
      ("8", "15", .valid),
      ("9", "15", .valid),
      ("11", "16", .valid),
      ("11", "99", .valid),
      ("01", "99", .valid),
      ("1", "99", .valid),
      ("00", "99", .invalid),
      ("12", "14", .invalid),
      ("7", "15", .invalid),
      ("12", "00", .invalid),
      ("13", "16", .invalid),
      ("12", "2", .incomplete),
      ("12", "1", .incomplete),
      ("12", "0", .incomplete),
    ]

    for test in tests {
      let state = STPCardValidator.validationState(
        forExpirationYear: test.1, inMonth: test.0, inCurrentYear: 15, currentMonth: 8)
      XCTAssertEqual(state, test.2)
    }
  }

  func testCVCLength() {
    let tests: [(STPCardBrand, UInt)] = [
      (.visa, 3),
      (.mastercard, 3),
      (.amex, 4),
      (.discover, 3),
      (.dinersClub, 3),
      (.JCB, 3),
      (.unionPay, 3),
      (.unknown, 4),
    ]
    for test in tests {
      let maxCVCLength = STPCardValidator.maxCVCLength(for: test.0)
      XCTAssertEqual(maxCVCLength, test.1)
    }
  }

  func testCVCValidation() {
    let tests: [(String, STPCardBrand, STPCardValidationState)] = [
      ("x", .visa, .invalid),
      ("", .visa, .incomplete),
      ("1", .visa, .incomplete),
      ("12", .visa, .incomplete),
      ("1x3", .visa, .invalid),
      ("123", .visa, .valid),
      ("123", .amex, .valid),
      ("123", .unknown, .valid),
      ("1234", .visa, .invalid),
      ("1234", .amex, .valid),
      ("12345", .amex, .invalid),
    ]

    for test in tests {
      let state = STPCardValidator.validationState(forCVC: test.0, cardBrand: test.1)
      XCTAssertEqual(state, test.2)
    }
  }

  func testCardValidation() {
    let tests: [(String, UInt, UInt, String, STPCardValidationState)] = [
      (
        "4242424242424242",
        12,
        15,
        "123",
        .valid
      ),
      (
        "4242424242424242",
        12,
        15,
        "x",
        .invalid
      ),
      (
        "4242424242424242",
        12,
        15,
        "1",
        .incomplete
      ),
      (
        "4242424242424242",
        12,
        14,
        "123",
        .invalid
      ),
      (
        "4242424242424242",
        21,
        15,
        "123",
        .invalid
      ),
      (
        "42424242",
        12,
        15,
        "123",
        .incomplete
      ),
      (
        "378282246310005",
        12,
        15,
        "1234",
        .valid
      ),
      (
        "378282246310005",
        12,
        15,
        "123",
        .valid
      ),
      (
        "378282246310005",
        12,
        15,
        "12345",
        .invalid
      ),
      (
        "1234567812345678",
        12,
        15,
        "12345",
        .invalid
      ),
    ]
    for test in tests {
      let card = STPCardParams()
      card.number = test.0
      card.expMonth = test.1
      card.expYear = test.2
      card.cvc = test.3
      let state = STPCardValidator.validationState(
        forCard: card,
        inCurrentYear: 15,
        currentMonth: 8)
      if state != test.4 {
        XCTFail(
          "Wrong validation state for \(String(describing: card.number)). Expected \(test.4), got \(state))"
        )
      }
    }
  }
}

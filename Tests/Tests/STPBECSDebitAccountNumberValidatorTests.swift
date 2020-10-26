//
//  STPBECSDebitAccountNumberValidatorTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 3/13/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

@testable import Stripe

class STPBECSDebitAccountNumberValidatorTests: XCTestCase {
  func testValidationStateForText() {
    let tests = [
      // empty input
      [
        "input": "",
        "bsb": "",
        "editing": NSNumber(value: false),
        "expected": NSNumber(value: STPTextValidationState.empty.rawValue),
      ],
      [
        "input": "",
        "bsb": "0",
        "editing": NSNumber(value: false),
        "expected": NSNumber(value: STPTextValidationState.empty.rawValue),
      ],
      [
        "input": "",
        "editing": NSNumber(value: false),
        "expected": NSNumber(value: STPTextValidationState.empty.rawValue),
      ],
      [
        "input": "",
        "bsb": "00",
        "editing": NSNumber(value: false),
        "expected": NSNumber(value: STPTextValidationState.empty.rawValue),
      ],
      // incomplete input
      [
        "input": "1",
        "bsb": "",
        "editing": NSNumber(value: false),
        "expected": NSNumber(value: STPTextValidationState.incomplete.rawValue),
      ],
      [
        "input": "1",
        "bsb": "0",
        "editing": NSNumber(value: false),
        "expected": NSNumber(value: STPTextValidationState.incomplete.rawValue),
      ],
      [
        "input": "1",
        "bsb": "00",
        "editing": NSNumber(value: false),
        "expected": NSNumber(value: STPTextValidationState.incomplete.rawValue),
      ],
      [
        "input": "1",
        "editing": NSNumber(value: false),
        "expected": NSNumber(value: STPTextValidationState.incomplete.rawValue),
      ],
      [
        "input": "12345",
        "bsb": "06",
        "editing": NSNumber(value: false),
        "expected": NSNumber(value: STPTextValidationState.incomplete.rawValue),
      ],
      // incomplete input (editing)
      [
        "input": "1",
        "bsb": "",
        "editing": NSNumber(value: true),
        "expected": NSNumber(value: STPTextValidationState.incomplete.rawValue),
      ],
      [
        "input": "1",
        "bsb": "0",
        "editing": NSNumber(value: true),
        "expected": NSNumber(value: STPTextValidationState.incomplete.rawValue),
      ],
      [
        "input": "1",
        "bsb": "00",
        "editing": NSNumber(value: true),
        "expected": NSNumber(value: STPTextValidationState.incomplete.rawValue),
      ],
      [
        "input": "1",
        "editing": NSNumber(value: true),
        "expected": NSNumber(value: STPTextValidationState.incomplete.rawValue),
      ],
      [
        "input": "12345",
        "bsb": "06",
        "editing": NSNumber(value: true),
        "expected": NSNumber(value: STPTextValidationState.incomplete.rawValue),
      ],
      [
        "input": "12345678",
        "bsb": "",
        "editing": NSNumber(value: true),
        "expected": NSNumber(value: STPTextValidationState.incomplete.rawValue),
      ],
      // complete
      [
        "input": "12345",
        "bsb": "",
        "editing": NSNumber(value: false),
        "expected": NSNumber(value: STPTextValidationState.complete.rawValue),
      ],
      [
        "input": "123456",
        "bsb": "",
        "editing": NSNumber(value: false),
        "expected": NSNumber(value: STPTextValidationState.complete.rawValue),
      ],
      [
        "input": "1234567",
        "bsb": "",
        "editing": NSNumber(value: false),
        "expected": NSNumber(value: STPTextValidationState.complete.rawValue),
      ],
      [
        "input": "12345678",
        "bsb": "",
        "editing": NSNumber(value: false),
        "expected": NSNumber(value: STPTextValidationState.complete.rawValue),
      ],
      [
        "input": "123456789",
        "bsb": "",
        "editing": NSNumber(value: false),
        "expected": NSNumber(value: STPTextValidationState.complete.rawValue),
      ],
      // complete (editing)
      [
        "input": "123456789",
        "bsb": "",
        "editing": NSNumber(value: true),
        "expected": NSNumber(value: STPTextValidationState.complete.rawValue),
      ],
      // invalid
      [
        "input": "12345678910",
        "bsb": "",
        "editing": NSNumber(value: false),
        "expected": NSNumber(value: STPTextValidationState.invalid.rawValue),
      ],
      // invalid (editing)
      [
        "input": "12345678910",
        "bsb": "",
        "editing": NSNumber(value: true),
        "expected": NSNumber(value: STPTextValidationState.invalid.rawValue),
      ],
    ]

    for test in tests {
      let input = (test["input"] as? String)!
      let bsb = test["bsb"] as? String
      let editing = (test["editing"] as? NSNumber)!.boolValue
      let expected = STPTextValidationState(rawValue: (test["expected"] as! NSNumber).intValue)!

      XCTAssertEqual(
        STPBECSDebitAccountNumberValidator.validationState(
          forText: input, withBSBNumber: bsb, completeOnMaxLengthOnly: editing), expected)
    }
  }

  func testformattedSanitizedTextFromString() {
    let tests = [
      [
        "input": "",
        "bsb": "00",
        "expected": "",
      ],
      [
        "input": "1",
        "bsb": "00",
        "expected": "1",
      ],
      [
        "input": "--111111--",
        "bsb": "00",
        "expected": "111111",
      ],
      [
        "input": "12345678910",
        "bsb": "00",
        "expected": "123456789",
      ],
      [
        "input": "",
        "bsb": "06",
        "expected": "",
      ],
      [
        "input": "1",
        "bsb": "06",
        "expected": "1",
      ],
      [
        "input": "--111111--",
        "bsb": "06",
        "expected": "111111",
      ],
      [
        "input": "12345678910",
        "bsb": "06",
        "expected": "123456789",
      ],
    ]

    for test in tests {
      let input = (test["input"])!
      let bsb = test["bsb"]
      let expected = test["expected"]
      XCTAssertEqual(
        STPBECSDebitAccountNumberValidator.formattedSanitizedText(from: input, withBSBNumber: bsb),
        expected)
    }
  }
}

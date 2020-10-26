//
//  STPPostalCodeValidatorTest.swift
//  Stripe
//
//  Created by Ben Guo on 4/14/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//
@testable import Stripe

class STPPostalCodeValidatorTest: XCTestCase {
  func testValidUSPostalCodes() {
    let codes = ["10002", "10002-1234", "100021234", "21218"]
    for code in codes {
      XCTAssertEqual(
        STPPostalCodeValidator.validationState(
          forPostalCode: code,
          countryCode: "US"),
        .valid)
    }
  }

  func testInvalidUSPostalCodes() {
    let codes = ["100A03", "12345-12345", "1234512345", "$$$$$", "foo"]
    for code in codes {
      XCTAssertEqual(
        STPPostalCodeValidator.validationState(
          forPostalCode: code,
          countryCode: "US"),
        .invalid)
    }
  }

  func testIncompleteUSPostalCodes() {
    let codes = ["", "123", "12345-", "12345-12"]
    for code in codes {
      XCTAssertEqual(
        STPPostalCodeValidator.validationState(
          forPostalCode: code,
          countryCode: "US"),
        .incomplete)
    }
  }

  func testValidGenericPostalCodes() {
    let codes = ["ABC10002", "10002-ABCD", "ABCDE"]
    for code in codes {
      XCTAssertEqual(
        STPPostalCodeValidator.validationState(
          forPostalCode: code,
          countryCode: "UK"),
        .valid)
    }
  }

  func testIncompleteGenericPostalCodes() {
    let codes = [""]
    for code in codes {
      XCTAssertEqual(
        STPPostalCodeValidator.validationState(
          forPostalCode: code,
          countryCode: "UK"),
        .incomplete)
    }
  }
}

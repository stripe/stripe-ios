//
//  STPPhoneNumberValidatorTest.swift
//  Stripe
//
//  Created by Ben Guo on 3/22/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//
@testable import Stripe

private let kUSCountryCode = "US"
private let kUKCountryCode = "UK"
class STPPhoneNumberValidatorTest: XCTestCase {
  func testValidPhoneNumbers() {
    XCTAssertTrue(
      STPPhoneNumberValidator.stringIsValidPhoneNumber(
        "555-555-5555", forCountryCode: kUSCountryCode))
    XCTAssertTrue(
      STPPhoneNumberValidator.stringIsValidPhoneNumber("5555555555", forCountryCode: kUSCountryCode)
    )
    XCTAssertTrue(
      STPPhoneNumberValidator.stringIsValidPhoneNumber(
        "(555) 555-5555", forCountryCode: kUSCountryCode))
  }

  func testInvalidPhoneNumbers() {
    XCTAssertFalse(
      STPPhoneNumberValidator.stringIsValidPhoneNumber("", forCountryCode: kUSCountryCode))
    XCTAssertFalse(
      STPPhoneNumberValidator.stringIsValidPhoneNumber(
        "555-555-555", forCountryCode: kUSCountryCode))
    XCTAssertFalse(
      STPPhoneNumberValidator.stringIsValidPhoneNumber(
        "555-555-A555", forCountryCode: kUSCountryCode))
    XCTAssertFalse(
      STPPhoneNumberValidator.stringIsValidPhoneNumber(
        "55555555555", forCountryCode: kUSCountryCode))
  }

  func testFormattedSanitizedPhoneNumberForString() {
    XCTAssertEqual(
      STPPhoneNumberValidator.formattedSanitizedPhoneNumber(
        for: "55", forCountryCode: kUSCountryCode), "55")
    XCTAssertEqual(
      STPPhoneNumberValidator.formattedSanitizedPhoneNumber(
        for: "555", forCountryCode: kUSCountryCode), "(555) ")
    XCTAssertEqual(
      STPPhoneNumberValidator.formattedSanitizedPhoneNumber(
        for: "55555", forCountryCode: kUSCountryCode), "(555) 55")
    XCTAssertEqual(
      STPPhoneNumberValidator.formattedSanitizedPhoneNumber(
        for: "A-55555", forCountryCode: kUSCountryCode), "(555) 55")
    XCTAssertEqual(
      STPPhoneNumberValidator.formattedSanitizedPhoneNumber(
        for: "5555555", forCountryCode: kUSCountryCode), "(555) 555-5")
    XCTAssertEqual(
      STPPhoneNumberValidator.formattedSanitizedPhoneNumber(
        for: "5555555555", forCountryCode: kUSCountryCode), "(555) 555-5555")
    XCTAssertEqual(
      STPPhoneNumberValidator.formattedSanitizedPhoneNumber(
        for: "5555555555123", forCountryCode: kUSCountryCode), "(555) 555-5555")
    XCTAssertEqual(
      STPPhoneNumberValidator.formattedSanitizedPhoneNumber(
        for: "5555555555123", forCountryCode: kUKCountryCode),
      "5555555555123")
  }

  func testFormattedRedactedPhoneNumberForString() {
    XCTAssertEqual(
      STPPhoneNumberValidator.formattedRedactedPhoneNumber(
        for: "+1******1234", forCountryCode: kUSCountryCode), "+1 (•••) •••-1234")
    XCTAssertEqual(
      STPPhoneNumberValidator.formattedRedactedPhoneNumber(
        for: "+86******1234", forCountryCode: kUKCountryCode), "+86 ••••••1234")
  }
}

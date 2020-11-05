//
//  STPEmailAddressValidatorTest.swift
//  Stripe
//
//  Created by Jack Flintermann on 3/23/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

@testable import Stripe

class STPEmailAddressValidatorTest: XCTestCase {
  func testValidEmails() {
    let validEmails = ["test@test.com", "test+thing@test.com.nz", "a@b.c", "A@b.c"]
    for email in validEmails {
      XCTAssert(STPEmailAddressValidator.stringIsValidEmailAddress(email))
    }
  }

  func testInvalidEmails() {
    let invalidEmails = ["", "google.com", "asdf", "asdg@c"]
    for email in invalidEmails {
      XCTAssertFalse(STPEmailAddressValidator.stringIsValidEmailAddress(email))
    }
  }
}

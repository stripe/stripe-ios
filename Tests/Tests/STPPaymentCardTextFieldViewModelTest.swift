//
//  STPCreditCardTextFieldTest.m
//  Stripe
//
//  Created by Jack Flintermann on 7/16/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

import XCTest

@testable import Stripe

class STPPaymentCardTextFieldViewModelTest: XCTestCase {
  var viewModel: STPPaymentCardTextFieldViewModel?

  override func setUp() {
    super.setUp()
    viewModel = STPPaymentCardTextFieldViewModel()
  }

  func testCardNumber() {
    let tests = [
      ["", ""],
      ["4242", "4242"],
      ["4242424242424242", "4242424242424242"],
      ["4242 4242 4242 4242", "4242424242424242"],
      ["4242xxx4242", "42424242"],
      ["12345678901234567890", "1234567890123456789"],
    ]
    for test in tests {
      viewModel?.cardNumber = test[0]
      XCTAssertEqual(viewModel?.cardNumber, test[1])
    }
  }

  func testRawExpiration() {
    let tests: [(String, String, String, String, STPCardValidationState)] = [
      ("", "", "", "", .incomplete),
      ("12/23", "12/23", "12", "23", .valid),
      ("1223", "12/23", "12", "23", .valid),
      ("1", "1", "1", "", .incomplete),
      ("2", "02/", "02", "", .incomplete),
      ("12", "12/", "12", "", .incomplete),
      ("12/2", "12/2", "12", "2", .incomplete),
      ("99/23", "99", "99", "23", .invalid),
      ("10/12", "10/12", "10", "12", .invalid),
      ("12*23", "12/23", "12", "23", .valid),
      ("12/*", "12/", "12", "", .incomplete),
      ("*", "", "", "", .incomplete),
    ]
    for test in tests {
      viewModel?.rawExpiration = test.0
      XCTAssertEqual(viewModel?.rawExpiration, test.1)
      XCTAssertEqual(viewModel?.expirationMonth, test.2)
      XCTAssertEqual(viewModel?.expirationYear, test.3)
      XCTAssertEqual(viewModel?.validationStateForExpiration(), test.4)
    }
  }

  func testCVC() {
    let tests = [["1", "1"], ["1234", "1234"], ["12345", "1234"], ["1x", "1"]]
    for test in tests {
      viewModel?.cvc = test[0]
      XCTAssertEqual(viewModel?.cvc, test[1])
    }
  }

  func testValidity() {
    viewModel?.cardNumber = "4242424242424242"
    viewModel?.rawExpiration = "12/24"
    viewModel?.cvc = "123"
    XCTAssertTrue(viewModel!.isValid)

    viewModel?.cvc = "12"
    XCTAssertFalse(viewModel!.isValid)
  }

  func testCompressedCardNumber() {
    viewModel?.cardNumber = nil
    XCTAssertEqual(viewModel?.compressedCardNumber(withPlaceholder: nil), "4242")  // Should use default placeholder
    XCTAssertEqual(viewModel?.compressedCardNumber(withPlaceholder: "1234567812345678"), "5678")

    viewModel?.cardNumber = "424212345678"
    XCTAssertEqual(viewModel?.compressedCardNumber(withPlaceholder: nil), "5678")
    viewModel?.cardNumber = "42421234567"
    XCTAssertEqual(viewModel?.compressedCardNumber(withPlaceholder: nil), "567")
    viewModel?.cardNumber = "4242123456"
    XCTAssertEqual(viewModel?.compressedCardNumber(withPlaceholder: nil), "56")
    viewModel?.cardNumber = "424212345"
    XCTAssertEqual(viewModel?.compressedCardNumber(withPlaceholder: nil), "5")
    viewModel?.cardNumber = "42421234"
    XCTAssertEqual(viewModel?.compressedCardNumber(withPlaceholder: nil), "1234")

    viewModel?.cardNumber = "12"
    XCTAssertEqual(viewModel?.compressedCardNumber(withPlaceholder: nil), "12")

    viewModel?.cardNumber = "36227206271667"
    XCTAssertEqual(viewModel?.compressedCardNumber(withPlaceholder: nil), "1667")
    viewModel?.cardNumber = "3622720627166"
    XCTAssertEqual(viewModel?.compressedCardNumber(withPlaceholder: nil), "166")
    viewModel?.cardNumber = "36227206271"
    XCTAssertEqual(viewModel?.compressedCardNumber(withPlaceholder: nil), "1")
    viewModel?.cardNumber = "3622720627"
    XCTAssertEqual(viewModel?.compressedCardNumber(withPlaceholder: nil), "720627")
  }
}

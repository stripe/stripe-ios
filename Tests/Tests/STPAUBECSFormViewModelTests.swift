//
//  STPAUBECSFormViewModelTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 3/13/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

@testable import Stripe

class STPAUBECSFormViewModelTests: XCTestCase {
  func testBECSDebitParams() {
    do {
      // Test empty data
      let model = STPAUBECSFormViewModel()
      XCTAssertNil(model.becsDebitParams, "params with no data should be nil")
    }

    do {
      // Test complete/valid data
      let model = STPAUBECSFormViewModel()
      model.accountNumber = "123456"
      model.bsbNumber = "111-111"

      let params = model.becsDebitParams
      XCTAssertNotNil(params, "Failed to create BECS Debit params")
      XCTAssertEqual(params?.accountNumber, "123456")
      XCTAssertEqual(params?.bsbNumber, "111111")
    }

    do {
      // Test complete/valid data w/o formatting
      let model = STPAUBECSFormViewModel()
      model.accountNumber = "123456"
      model.bsbNumber = "111111"

      let params = model.becsDebitParams
      XCTAssertNotNil(params, "Failed to create BECS Debit params")
      XCTAssertEqual(params?.accountNumber, "123456")
      XCTAssertEqual(params?.bsbNumber, "111111")
    }

    do {
      // Test complete/valid accountNumber, incomplete bsb number
      let model = STPAUBECSFormViewModel()
      model.accountNumber = "123456"
      model.bsbNumber = "111-"

      let params = model.becsDebitParams
      XCTAssertNil(params, "Should not create params with incomplete bsb number")
    }

    do {
      // Test incomplete accountNumber, complete/valid bsb number
      let model = STPAUBECSFormViewModel()
      model.accountNumber = "1234"
      model.bsbNumber = "111-111"

      let params = model.becsDebitParams
      XCTAssertNil(params, "Should not create params with incomplete account number")
    }

    do {
      // Test invalid accountNumber, complete/valid bsb number
      let model = STPAUBECSFormViewModel()
      model.accountNumber = "12345678910"
      model.bsbNumber = "111-111"

      let params = model.becsDebitParams
      XCTAssertNil(params, "Should not create params with invalid account number")
    }

    do {
      // Test complete/valid accountNumber, invalid bsb number
      let model = STPAUBECSFormViewModel()
      model.accountNumber = "123456"
      model.bsbNumber = "666-666"

      let params = model.becsDebitParams
      XCTAssertNil(params, "Should not create params with incomplete bsb number")
    }
  }

  func testPaymentMethodParams() {
    do {
      /// Test empty
      let model = STPAUBECSFormViewModel()
      XCTAssertNil(model.paymentMethodParams, "params with no data should be nil")
    }

    do {
      /// name: +
      /// email: +
      /// bsb: + (formatting)
      /// account: +
      let model = STPAUBECSFormViewModel()
      model.name = "Jenny Rosen"
      model.email = "jrosen@example.com"
      model.accountNumber = "123456"
      model.bsbNumber = "111-111"

      let params = model.paymentMethodParams
      XCTAssertNotNil(params, "Failed to create BECS Debit params")
      XCTAssertEqual(params?.billingDetails?.name, "Jenny Rosen")
      XCTAssertEqual(params?.billingDetails?.email, "jrosen@example.com")
      XCTAssertEqual(params?.auBECSDebit?.accountNumber, "123456")
      XCTAssertEqual(params?.auBECSDebit?.bsbNumber, "111111")
    }

    do {
      /// name: +
      /// email: +
      /// bsb: +
      /// account: +
      let model = STPAUBECSFormViewModel()
      model.name = "Jenny Rosen"
      model.email = "jrosen@example.com"
      model.accountNumber = "123456"
      model.bsbNumber = "111111"

      let params = model.paymentMethodParams
      XCTAssertNotNil(params, "Failed to create BECS Debit params")
      XCTAssertEqual(params?.billingDetails?.name, "Jenny Rosen")
      XCTAssertEqual(params?.billingDetails?.email, "jrosen@example.com")
      XCTAssertEqual(params?.auBECSDebit?.accountNumber, "123456")
      XCTAssertEqual(params?.auBECSDebit?.bsbNumber, "111111")
    }

    do {
      /// name: +
      /// email: +
      /// bsb: x (incomplete)
      /// account: +
      let model = STPAUBECSFormViewModel()
      model.name = "Jenny Rosen"
      model.email = "jrosen@example.com"
      model.accountNumber = "123456"
      model.bsbNumber = "111-"

      let params = model.paymentMethodParams
      XCTAssertNil(params, "Should not create params with incomplete bsb number")
    }

    do {
      /// name: +
      /// email: +
      /// bsb: +
      /// account: x (incomplete)
      let model = STPAUBECSFormViewModel()
      model.name = "Jenny Rosen"
      model.email = "jrosen@example.com"
      model.accountNumber = "1234"
      model.bsbNumber = "111-111"

      let params = model.paymentMethodParams
      XCTAssertNil(params, "Should not create params with incomplete account number")
    }

    do {
      /// name: +
      /// email: +
      /// bsb: +
      /// account: x
      let model = STPAUBECSFormViewModel()
      model.name = "Jenny Rosen"
      model.email = "jrosen@example.com"
      model.accountNumber = "12345678910"
      model.bsbNumber = "111-111"

      let params = model.paymentMethodParams
      XCTAssertNil(params, "Should not create params with invalid account number")
    }

    do {
      /// name: +
      /// email: +
      /// bsb: x
      /// account: +
      let model = STPAUBECSFormViewModel()
      model.name = "Jenny Rosen"
      model.email = "jrosen@example.com"
      model.accountNumber = "123456"
      model.bsbNumber = "666-666"

      let params = model.paymentMethodParams
      XCTAssertNil(params, "Should not create params with incomplete bsb number")
    }

    do {
      /// name: x
      /// email: +
      /// bsb: + (formatting)
      /// account: +
      let model = STPAUBECSFormViewModel()
      model.name = ""
      model.email = "jrosen@example.com"
      model.accountNumber = "123456"
      model.bsbNumber = "111-111"

      let params = model.paymentMethodParams
      XCTAssertNil(params, "Should not create payment method params without name.")
    }

    do {
      /// name: +
      /// email: x
      /// bsb: + (formatting)
      /// account: +
      let model = STPAUBECSFormViewModel()
      model.name = "Jenny Rosen"
      model.email = "jrose"
      model.accountNumber = "123456"
      model.bsbNumber = "111-111"

      let params = model.paymentMethodParams
      XCTAssertNil(params, "Should not create payment method params with invalid email.")
    }
  }

  func testBSBLabelForInput() {
    do {
      // empty test
      let model = STPAUBECSFormViewModel()
      var isErrorString = true
      var bsbLabel = model.bsbLabel(forInput: "", editing: false, isErrorString: &isErrorString)
      XCTAssertFalse(isErrorString, "Empty input shouldn't be an error.")
      XCTAssertNil(bsbLabel, "No bsb label for empty input.")

      isErrorString = true
      bsbLabel = model.bsbLabel(forInput: nil, editing: true, isErrorString: &isErrorString)
      XCTAssertFalse(isErrorString, "nil input shouldn't be an error.")
      XCTAssertNil(bsbLabel, "No bsb label for nil input.")
    }

    do {
      // invalid test
      let model = STPAUBECSFormViewModel()
      var isErrorString = false
      var bsbLabel = model.bsbLabel(
        forInput: "666-666", editing: false, isErrorString: &isErrorString)
      XCTAssertTrue(isErrorString, "Invalid input should be an error.")
      XCTAssertEqual(bsbLabel, "The BSB you entered is invalid.")

      isErrorString = false
      bsbLabel = model.bsbLabel(forInput: "666-666", editing: true, isErrorString: &isErrorString)
      XCTAssertTrue(isErrorString, "Invalid input should be an error (editing).")
      XCTAssertEqual(bsbLabel, "The BSB you entered is invalid.")
    }

    do {
      // incomplete test
      let model = STPAUBECSFormViewModel()
      var isErrorString = false
      var bsbLabel = model.bsbLabel(
        forInput: "111-11", editing: false, isErrorString: &isErrorString)
      XCTAssertTrue(isErrorString, "Incomplete input should be an error when not editing.")
      XCTAssertEqual(bsbLabel, "The BSB you entered is incomplete.")

      isErrorString = true
      bsbLabel = model.bsbLabel(forInput: "111-11", editing: true, isErrorString: &isErrorString)
      XCTAssertFalse(isErrorString, "Incomplete input should not be an error when editing.")
      XCTAssertEqual(bsbLabel, "St George Bank (division of Westpac Bank)")
    }

    do {
      // valid test
      let model = STPAUBECSFormViewModel()
      var isErrorString = true
      var bsbLabel = model.bsbLabel(
        forInput: "111-111", editing: false, isErrorString: &isErrorString)
      XCTAssertFalse(isErrorString, "Complete input should be not an error when not editing.")
      XCTAssertEqual(bsbLabel, "St George Bank (division of Westpac Bank)")

      isErrorString = true
      bsbLabel = model.bsbLabel(forInput: "111-111", editing: true, isErrorString: &isErrorString)
      XCTAssertFalse(isErrorString, "Complete input should not be an error when editing.")
      XCTAssertEqual(bsbLabel, "St George Bank (division of Westpac Bank)")
    }
  }

  func testIsInputValid() {
    do {
      // name
      let model = STPAUBECSFormViewModel()
      XCTAssertTrue(
        model.isInputValid("", for: .name, editing: false), "Name should always be valid.")
      XCTAssertTrue(
        model.isInputValid("Jen", for: .name, editing: true), "Name should always be valid.")
    }

    do {
      // email
      let model = STPAUBECSFormViewModel()
      XCTAssertFalse(
        model.isInputValid("jrosen", for: .email, editing: false),
        "Partial email is invalid when not editing.")
      XCTAssertTrue(
        model.isInputValid("jrosen", for: .email, editing: true),
        "Partial email is valid when editing.")

      XCTAssertTrue(
        model.isInputValid("", for: .email, editing: false), "Empty email is always valid.")
      XCTAssertTrue(
        model.isInputValid("", for: .email, editing: true), "Empty email is always valid.")

      XCTAssertTrue(
        model.isInputValid("jrosen@example.com", for: .email, editing: false), "Valid email.")
      XCTAssertTrue(
        model.isInputValid("jrosen@example.com", for: .email, editing: true), "Valid email.")
    }

    do {
      // bsb
      let model = STPAUBECSFormViewModel()
      XCTAssertFalse(
        model.isInputValid("111-1", for: .BSBNumber, editing: false),
        "Partial bsb is invalid when not editing.")
      XCTAssertTrue(
        model.isInputValid("111-1", for: .BSBNumber, editing: true),
        "Partial bsb is valid when editing.")

      XCTAssertTrue(
        model.isInputValid("", for: .BSBNumber, editing: false), "Empty bsb is always valid.")
      XCTAssertTrue(
        model.isInputValid("", for: .BSBNumber, editing: true), "Empty bsb is always valid.")

      XCTAssertTrue(model.isInputValid("111-111", for: .BSBNumber, editing: false), "Valid bsb.")
      XCTAssertTrue(model.isInputValid("111-111", for: .BSBNumber, editing: true), "Valid bsb.")

      XCTAssertFalse(
        model.isInputValid("666-6", for: .BSBNumber, editing: false),
        "Invalid partial bsb is always invalid.")
      XCTAssertFalse(
        model.isInputValid("666-6", for: .BSBNumber, editing: true),
        "Invalid partial bsb is always invalid.")

      XCTAssertFalse(
        model.isInputValid("666-666", for: .BSBNumber, editing: false),
        "Invalid full bsb is always invalid.")
      XCTAssertFalse(
        model.isInputValid("666-666", for: .BSBNumber, editing: true),
        "Invalid full bsb is always invalid.")
    }

    do {
      // account
      let model = STPAUBECSFormViewModel()
      XCTAssertFalse(
        model.isInputValid("1234", for: .accountNumber, editing: false),
        "Partial account number is invalid when not editing.")
      XCTAssertTrue(
        model.isInputValid("1234", for: .accountNumber, editing: true),
        "Partial  account number is valid when editing.")

      XCTAssertTrue(
        model.isInputValid("", for: .accountNumber, editing: false),
        "Empty  account number is always valid.")
      XCTAssertTrue(
        model.isInputValid("", for: .accountNumber, editing: true),
        "Empty  account number is always valid.")

      XCTAssertTrue(
        model.isInputValid("12345", for: .accountNumber, editing: false), "Valid  account number.")
      XCTAssertTrue(
        model.isInputValid("12345", for: .accountNumber, editing: true), "Valid  account number.")

      XCTAssertFalse(
        model.isInputValid("12345678910", for: .accountNumber, editing: false),
        "Invalid  account number is always invalid.")
      XCTAssertFalse(
        model.isInputValid("12345678910", for: .accountNumber, editing: true),
        "Invalid  account number is always invalid.")
    }
  }

  func testIsFieldComplete() {
    do {
      // name
      let model = STPAUBECSFormViewModel()
      XCTAssertFalse(
        model.isFieldComplete(withInput: "", in: .name, editing: false),
        "Empty name is not complete.")
      XCTAssertFalse(
        model.isFieldComplete(withInput: "", in: .name, editing: true),
        "Empty name is not complete.")

      XCTAssertTrue(
        model.isFieldComplete(withInput: "Jen", in: .name, editing: false),
        "Non-empty name is complete.")
      XCTAssertTrue(
        model.isFieldComplete(withInput: "Jenny Rosen", in: .name, editing: true),
        "Non-empty name is complete.")
    }

    do {
      // email
      let model = STPAUBECSFormViewModel()
      XCTAssertFalse(
        model.isFieldComplete(withInput: "jrosen", in: .email, editing: false),
        "Partial email is not complete.")
      XCTAssertFalse(
        model.isFieldComplete(withInput: "jrosen", in: .email, editing: true),
        "Partial email is not complete.")

      XCTAssertTrue(
        model.isFieldComplete(withInput: "jrosen@example.com", in: .email, editing: false),
        "Full email is complete.")
      XCTAssertTrue(
        model.isFieldComplete(withInput: "jrosen@example.com", in: .email, editing: true),
        "Full email is complete.")
    }

    do {
      // bsb
      let model = STPAUBECSFormViewModel()
      XCTAssertFalse(
        model.isFieldComplete(withInput: "111-1", in: .BSBNumber, editing: false),
        "Partial bsb is not complete.")
      XCTAssertFalse(
        model.isFieldComplete(withInput: "111-1", in: .BSBNumber, editing: true),
        "Partial bsb is not complete.")

      XCTAssertFalse(
        model.isFieldComplete(withInput: "", in: .BSBNumber, editing: false),
        "Empty bsb is not complete.")
      XCTAssertFalse(
        model.isFieldComplete(withInput: "", in: .BSBNumber, editing: true),
        "Empty bsb is not complete.")

      XCTAssertTrue(
        model.isFieldComplete(withInput: "111-111", in: .BSBNumber, editing: false),
        "Full bsb is complete.")
      XCTAssertTrue(
        model.isFieldComplete(withInput: "111-111", in: .BSBNumber, editing: true),
        "Full bsb is complete.")

      XCTAssertFalse(
        model.isFieldComplete(withInput: "666-6", in: .BSBNumber, editing: false),
        "Invalid partial bsb is not complete.")
      XCTAssertFalse(
        model.isFieldComplete(withInput: "666-6", in: .BSBNumber, editing: true),
        "Invalid partial bsb is not complete.")

      XCTAssertFalse(
        model.isFieldComplete(withInput: "666-666", in: .BSBNumber, editing: false),
        "Invalid full bsb is not complete.")
      XCTAssertFalse(
        model.isFieldComplete(withInput: "666-666", in: .BSBNumber, editing: true),
        "Invalid full bsb is not complete.")
    }

    do {
      // account
      let model = STPAUBECSFormViewModel()
      XCTAssertFalse(
        model.isFieldComplete(withInput: "1234", in: .accountNumber, editing: false),
        "Partial account number is not complete.")
      XCTAssertFalse(
        model.isFieldComplete(withInput: "1234", in: .accountNumber, editing: true),
        "Partial account number is not complete.")

      XCTAssertFalse(
        model.isFieldComplete(withInput: "", in: .accountNumber, editing: false),
        "Empty account number is not complete.")
      XCTAssertFalse(
        model.isFieldComplete(withInput: "", in: .accountNumber, editing: true),
        "Empty account number is not complete.")

      XCTAssertTrue(
        model.isFieldComplete(withInput: "12345", in: .accountNumber, editing: false),
        "Min length account number is complete when not editing.")
      XCTAssertFalse(
        model.isFieldComplete(withInput: "12345", in: .accountNumber, editing: true),
        "Min length account number is not complete when editing.")

      XCTAssertTrue(
        model.isFieldComplete(withInput: "123456789", in: .accountNumber, editing: true),
        "Max length account number is complete when editing.")

      XCTAssertFalse(
        model.isFieldComplete(withInput: "12345678910", in: .accountNumber, editing: false),
        "Invalid  account number is not complete.")
      XCTAssertFalse(
        model.isFieldComplete(withInput: "12345678910", in: .accountNumber, editing: true),
        "Invalid  account number is not complete.")
    }
  }
}

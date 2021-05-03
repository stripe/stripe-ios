//
//  STPPostalCodeInputTextFieldSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 10/30/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import FBSnapshotTestCase

@testable import Stripe

class STPPostalCodeInputTextFieldSnapshotTests: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()
        //        recordMode = true
    }

    func testEmpty() {
        let field = STPPostalCodeInputTextField()
        field.sizeToFit()
        field.frame.size.width = 200

        FBSnapshotVerifyView(field)
    }

    func testIncomplete() {
        let field = STPPostalCodeInputTextField()
        field.sizeToFit()
        field.frame.size.width = 200
        field.countryCode = "US"
        field.text = "1"
        field.textDidChange()

        FBSnapshotVerifyView(field)
    }

    func testValidUS() {
        let field = STPPostalCodeInputTextField()
        field.sizeToFit()
        field.frame.size.width = 200
        field.countryCode = "US"
        field.text = "12345"
        field.textDidChange()

        FBSnapshotVerifyView(field)
    }

    func testValidUK() {
        let field = STPPostalCodeInputTextField()
        field.sizeToFit()
        field.frame.size.width = 200
        field.countryCode = "UK"
        field.text = "abcdef"
        field.textDidChange()

        FBSnapshotVerifyView(field)
    }

    func testInvalid() {
        let field = STPPostalCodeInputTextField()
        field.sizeToFit()
        field.frame.size.width = 200
        field.countryCode = "US"
        field.text = "12-3456789"
        field.textDidChange()
        field.validator.validationState = .invalid(errorMessage: nil) // manually set because the formatter prevents setting invalid text

        FBSnapshotVerifyView(field)
    }
}

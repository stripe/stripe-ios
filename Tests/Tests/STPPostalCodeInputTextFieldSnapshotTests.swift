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
        let field = STPPostalCodeInputTextField(postalCodeRequirement: .standard)
        field.sizeToFit()
        field.frame.size.width = 200

        STPSnapshotVerifyView(field)
    }

    func testIncomplete() {
        let field = STPPostalCodeInputTextField(postalCodeRequirement: .standard)
        field.sizeToFit()
        field.frame.size.width = 200
        field.countryCode = "US"
        field.text = "1"
        field.textDidChange()

        STPSnapshotVerifyView(field)
    }

    func testValidUS() {
        let field = STPPostalCodeInputTextField(postalCodeRequirement: .standard)
        field.sizeToFit()
        field.frame.size.width = 200
        field.countryCode = "US"
        field.text = "12345"
        field.textDidChange()

        STPSnapshotVerifyView(field)
    }

    func testValidUK() {
        let field = STPPostalCodeInputTextField(postalCodeRequirement: .standard)
        field.sizeToFit()
        field.frame.size.width = 200
        field.countryCode = "UK"
        field.text = "abcdef"
        field.textDidChange()

        STPSnapshotVerifyView(field)
    }

    func testInvalid() {
        let field = STPPostalCodeInputTextField(postalCodeRequirement: .standard)
        field.sizeToFit()
        field.frame.size.width = 200
        field.countryCode = "US"
        field.text = "12-3456789"
        field.textDidChange()
        field.validator.validationState = .invalid(errorMessage: nil) // manually set because the formatter prevents setting invalid text

        STPSnapshotVerifyView(field)
    }
}

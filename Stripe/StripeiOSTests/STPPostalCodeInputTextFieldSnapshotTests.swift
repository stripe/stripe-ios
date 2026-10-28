//
//  STPPostalCodeInputTextFieldSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 10/30/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import iOSSnapshotTestCase
import StripeCoreTestUtils

@testable@_spi(InternalOnlyAPI) import Stripe
@testable@_spi(InternalOnlyAPI) import StripeCore
@testable@_spi(InternalOnlyAPI) import StripePayments
@testable@_spi(InternalOnlyAPI) import StripePaymentSheet
@testable@_spi(InternalOnlyAPI) import StripePaymentsUI

class STPPostalCodeInputTextFieldSnapshotTests: STPSnapshotTestCase {

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
        // manually set because the formatter prevents setting invalid text
        field.validator.validationState = .invalid(errorMessage: nil)

        STPSnapshotVerifyView(field)
    }
}

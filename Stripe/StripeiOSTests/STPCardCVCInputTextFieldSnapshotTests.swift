//
//  STPCardCVCInputTextFieldSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 10/29/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import iOSSnapshotTestCase
import StripeCoreTestUtils

@testable@_spi(InternalOnlyAPI) import Stripe
@testable@_spi(InternalOnlyAPI) import StripeCore
@testable@_spi(InternalOnlyAPI) import StripePayments
@testable@_spi(InternalOnlyAPI) import StripePaymentSheet
@testable@_spi(InternalOnlyAPI) import StripePaymentsUI

class STPCardCVCInputTextFieldSnapshotTests: STPSnapshotTestCase {

    func testEmpty() {
        let field = STPCardCVCInputTextField()
        field.sizeToFit()
        field.frame.size.width = 200

        STPSnapshotVerifyView(field)
    }

    func testIncomplete() {
        let field = STPCardCVCInputTextField()
        field.sizeToFit()
        field.frame.size.width = 200
        field.text = "1"
        field.textDidChange()

        STPSnapshotVerifyView(field)
    }

    func testValid() {
        let field = STPCardCVCInputTextField()
        field.sizeToFit()
        field.frame.size.width = 200
        field.text = "123"
        field.textDidChange()

        STPSnapshotVerifyView(field)
    }

    func testInvalid() {
        let field = STPCardCVCInputTextField()
        field.sizeToFit()
        field.frame.size.width = 200
        field.text = "12345"
        field.textDidChange()

        STPSnapshotVerifyView(field)
    }
}

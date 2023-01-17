//
//  STPCardExpiryInputTextFieldSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 10/29/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import iOSSnapshotTestCase

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPCardExpiryInputTextFieldSnapshotTests: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()
        //        recordMode = true
    }

    func testEmpty() {
        let field = STPCardExpiryInputTextField()
        field.sizeToFit()
        field.frame.size.width = 200

        STPSnapshotVerifyView(field)
    }

    func testIncomplete() {
        let field = STPCardExpiryInputTextField()
        field.sizeToFit()
        field.frame.size.width = 200
        field.text = "1"
        field.textDidChange()

        STPSnapshotVerifyView(field)
    }

    // We can't have a valid test here because the date would have to change as time marches on
    //    func testValid() {
    //    }

    func testInvalid() {
        let field = STPCardExpiryInputTextField()
        field.sizeToFit()
        field.frame.size.width = 200
        field.text = "16/22"
        field.textDidChange()

        STPSnapshotVerifyView(field)
    }

}

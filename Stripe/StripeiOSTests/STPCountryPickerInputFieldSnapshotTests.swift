//
//  STPCountryPickerInputFieldSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 12/2/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import iOSSnapshotTestCase

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPCountryPickerInputFieldSnapshotTests: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()
        //        recordMode = true
    }

    func testDefault() {
        let field = STPCountryPickerInputField()
        field.sizeToFit()
        field.frame.size.width = 200

        STPSnapshotVerifyView(field)
    }
}

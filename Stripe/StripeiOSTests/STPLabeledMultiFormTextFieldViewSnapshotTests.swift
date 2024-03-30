//
//  STPLabeledMultiFormTextFieldViewSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 3/13/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import iOSSnapshotTestCase
import StripeCoreTestUtils

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPLabeledMultiFormTextFieldViewSnapshotTests: STPSnapshotTestCase {

    func testAppearance() {
        let formTextField1 = STPFormTextField()
        formTextField1.placeholder = "Placeholder 1"
        formTextField1.placeholderColor = UIColor.lightGray

        let formTextField2 = STPFormTextField()
        formTextField2.placeholder = "Placeholder 2"
        formTextField2.placeholderColor = UIColor.lightGray

        let labeledFormField = STPLabeledMultiFormTextFieldView(
            formLabel: "Test Label",
            firstTextField: formTextField1,
            secondTextField: formTextField2
        )
        labeledFormField.formBackgroundColor = UIColor.white
        labeledFormField.frame = CGRect(x: 0.0, y: 0.0, width: 320.0, height: 62.0)
        STPSnapshotVerifyView(
            labeledFormField,
            identifier: "STPLabeledMultiFormTextFieldView.defaultAppearance"
        )
    }
}

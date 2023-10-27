//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPLabeledFormTextFieldViewSnapshotTests.m
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 3/13/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import iOSSnapshotTestCaseCore
import StripeCoreTestUtils
@testable @_spi(STP) import StripePaymentsUI

class STPLabeledFormTextFieldViewSnapshotTests: STPSnapshotTestCase {
    func testAppearance() {
        let formTextField = STPFormTextField()
        formTextField.placeholder = "A placeholder"
        formTextField.placeholderColor = UIColor.lightGray
        let labeledFormField = STPLabeledFormTextFieldView(formLabel: "Test Label", textField: formTextField)
        labeledFormField.formBackgroundColor = UIColor.white
        labeledFormField.frame = CGRect(x: 0.0, y: 0.0, width: 320.0, height: 44.0)
        STPSnapshotVerifyView(labeledFormField, identifier: "STPLabeledFormTextFieldView.defaultAppearance")
    }
}

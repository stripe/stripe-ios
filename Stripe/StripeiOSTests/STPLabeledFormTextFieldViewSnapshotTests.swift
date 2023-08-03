//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
import Foundation
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI
//
//  STPLabeledFormTextFieldViewSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 3/13/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//


import iOSSnapshotTestCaseCore

class STPLabeledFormTextFieldViewSnapshotTests: FBSnapshotTestCase {
    //- (void)setUp {
    //    [super setUp];
    //
    //    self.recordMode = YES;
    //}

    func testAppearance() {
        let formTextField = STPFormTextField()
        formTextField.placeholder = "A placeholder"
        formTextField.placeholderColor = UIColor.lightGray
        let labeledFormField = STPLabeledFormTextFieldView(formLabel: "Test Label", textField: formTextField)
        labeledFormField.formBackgroundColor = UIColor.white
        labeledFormField.frame = CGRect(x: 0.0, y: 0.0, width: 320.0, height: 44.0)
        STPSnapshotVerifyView(labeledFormField, "STPLabeledFormTextFieldView.defaultAppearance")
    }
}

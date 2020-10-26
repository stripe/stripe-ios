//
//  STPLabeledMultiFormTextFieldViewSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 3/13/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import FBSnapshotTestCase

@testable import Stripe

class STPLabeledMultiFormTextFieldViewSnapshotTests: FBSnapshotTestCase {
  override func setUp() {
    super.setUp()
    //        self.recordMode = true
  }

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
      secondTextField: formTextField2)
    labeledFormField.formBackgroundColor = UIColor.white
    labeledFormField.frame = CGRect(x: 0.0, y: 0.0, width: 320.0, height: 62.0)
    FBSnapshotVerifyView(
      labeledFormField, identifier: "STPLabeledMultiFormTextFieldView.defaultAppearance")
  }
}

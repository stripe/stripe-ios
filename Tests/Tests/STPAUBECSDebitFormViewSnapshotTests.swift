//
//  STPAUBECSDebitFormViewSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 3/13/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import FBSnapshotTestCase

@testable import Stripe

class STPAUBECSDebitFormViewSnapshotTests: FBSnapshotTestCase {
  override func setUp() {
    super.setUp()
    //        self.recordMode = true
  }

  func testDefaultAppearance() {
    let view = _newFormView()
    _size(toFit: view)
    FBSnapshotVerifyView(view, identifier: "STPAUBECSDebitFormView.defaultAppearance")
  }

  func testNoDataCustomization() {
    let view = _newFormView()

    _applyCustomization(view)

    _size(toFit: view)

    FBSnapshotVerifyView(view, identifier: "STPAUBECSDebitFormView.noDataCustomization")
  }

  func testWithDataAppearance() {
    let view = _newFormView()
    view.nameTextField().text = "Jenny Rosen"
    view.emailTextField().text = "jrosen@example.com"
    view.bsbNumberTextField().text = "111111"
    view.accountNumberTextField().text = "123456"
    _size(toFit: view)

    FBSnapshotVerifyView(view, identifier: "STPAUBECSDebitFormView.withDataAppearance")
  }

  func testWithDataCustomization() {
    let view = _newFormView()
    view.nameTextField().text = "Jenny Rosen"
    view.emailTextField().text = "jrosen@example.com"
    view.bsbNumberTextField().text = "111111"
    view.accountNumberTextField().text = "123456"
    _applyCustomization(view)
    _size(toFit: view)

    FBSnapshotVerifyView(view, identifier: "STPAUBECSDebitFormView.withDataAppearance")
  }

  func testInvalidBSBAndEmailAppearance() {
    let view = _newFormView()
    view.nameTextField().text = "Jenny Rosen"
    view.emailTextField().text = "jrosen"
    view.bsbNumberTextField().text = "666666"
    view.accountNumberTextField().text = "123456"
    _size(toFit: view)

    FBSnapshotVerifyView(view, identifier: "STPAUBECSDebitFormView.invalidBSBAndEmailAppearance")
  }

  func testInvalidBSBAndEmailCustomization() {
    let view = _newFormView()
    view.nameTextField().text = "Jenny Rosen"
    view.emailTextField().text = "jrosen"
    view.bsbNumberTextField().text = "666666"
    view.accountNumberTextField().text = "123456"
    _applyCustomization(view)
    _size(toFit: view)

    FBSnapshotVerifyView(view, identifier: "STPAUBECSDebitFormView.invalidBSBAndEmailCustomization")
  }

  // MARK: - Helpers
  func _newFormView() -> STPAUBECSDebitFormView {
    let formView = STPAUBECSDebitFormView(companyName: "Snapshotter")
    formView.frame = CGRect(x: 0.0, y: 0.0, width: 320.0, height: 600.0)
    return formView
  }

  func _applyCustomization(_ view: STPAUBECSDebitFormView?) {
    view?.formFont = UIFont.boldSystemFont(ofSize: 12.0)
    view?.formTextColor = UIColor.blue
    view?.formTextErrorColor = UIColor.orange
    view?.formPlaceholderColor = UIColor.black
    view?.formCursorColor = UIColor.red
    view?.formBackgroundColor = UIColor(
      red: 255.0 / 255.0, green: 45.0 / 255.0, blue: 85.0 / 255.0, alpha: 1.0)
  }

  func _size(toFit view: STPAUBECSDebitFormView?) {
    var adjustedFrame = view?.frame
    adjustedFrame?.size.height =
      view?.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height ?? 0.0
    view?.frame = adjustedFrame!
  }
}

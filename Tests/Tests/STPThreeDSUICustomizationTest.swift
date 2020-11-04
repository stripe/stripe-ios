//
//  STPThreeDSUICustomizationTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 6/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

@testable import Stripe

class STPThreeDSUICustomizationTest: XCTestCase {
  func testPropertiesPassedThrough() {
    let customization = STPThreeDSUICustomization.defaultSettings()

    // Maintains button customization objects
    customization.buttonCustomization(for: .next).backgroundColor = UIColor.cyan
    customization.buttonCustomization(for: .resend).backgroundColor = UIColor.cyan
    customization.buttonCustomization(for: .submit).backgroundColor = UIColor.cyan
    customization.buttonCustomization(for: .continue).backgroundColor = UIColor.cyan
    customization.buttonCustomization(for: .cancel).backgroundColor = UIColor.cyan
    XCTAssertEqual(
      customization.uiCustomization.buttonCustomization(for: .next).backgroundColor, UIColor.cyan)
    XCTAssertEqual(
      customization.uiCustomization.buttonCustomization(for: .resend).backgroundColor, UIColor.cyan)
    XCTAssertEqual(
      customization.uiCustomization.buttonCustomization(for: .submit).backgroundColor, UIColor.cyan)
    XCTAssertEqual(
      customization.uiCustomization.buttonCustomization(for: .continue).backgroundColor,
      UIColor.cyan)
    XCTAssertEqual(
      customization.uiCustomization.buttonCustomization(for: .cancel).backgroundColor, UIColor.cyan)

    let buttonCustomization = STPThreeDSButtonCustomization.defaultSettings(for: .next)
    customization.setButtonCustomization(buttonCustomization, for: .next)
    XCTAssertEqual(
      customization.uiCustomization.buttonCustomization(for: .next),
      buttonCustomization.buttonCustomization)

    // Footer
    customization.footerCustomization.backgroundColor = UIColor.cyan
    XCTAssertEqual(customization.uiCustomization.footerCustomization.backgroundColor, UIColor.cyan)

    let footerCustomization = STPThreeDSFooterCustomization.defaultSettings()
    customization.footerCustomization = footerCustomization
    XCTAssertEqual(
      customization.uiCustomization.footerCustomization, footerCustomization.footerCustomization)

    // Label
    customization.labelCustomization.textColor = UIColor.cyan
    XCTAssertEqual(customization.uiCustomization.labelCustomization.textColor, UIColor.cyan)

    let labelCustomization = STPThreeDSLabelCustomization.defaultSettings()
    customization.labelCustomization = labelCustomization
    XCTAssertEqual(
      customization.uiCustomization.labelCustomization, labelCustomization.labelCustomization)

    // Navigation Bar
    customization.navigationBarCustomization.textColor = UIColor.cyan
    XCTAssertEqual(customization.uiCustomization.navigationBarCustomization.textColor, UIColor.cyan)

    let navigationBar = STPThreeDSNavigationBarCustomization.defaultSettings()
    customization.navigationBarCustomization = navigationBar
    XCTAssertEqual(
      customization.uiCustomization.navigationBarCustomization,
      navigationBar.navigationBarCustomization)

    // Selection
    customization.selectionCustomization.primarySelectedColor = UIColor.cyan
    XCTAssertEqual(
      customization.uiCustomization.selectionCustomization.primarySelectedColor, UIColor.cyan)

    let selection = STPThreeDSSelectionCustomization.defaultSettings()
    customization.selectionCustomization = selection
    XCTAssertEqual(
      customization.uiCustomization.selectionCustomization, selection.selectionCustomization)

    // Text Field
    customization.textFieldCustomization.textColor = UIColor.cyan
    XCTAssertEqual(customization.uiCustomization.textFieldCustomization.textColor, UIColor.cyan)

    let textField = STPThreeDSTextFieldCustomization.defaultSettings()
    customization.textFieldCustomization = textField
    XCTAssertEqual(
      customization.uiCustomization.textFieldCustomization, textField.textFieldCustomization)

    // Other
    customization.backgroundColor = UIColor.red
    customization.activityIndicatorViewStyle = UIActivityIndicatorView.Style.whiteLarge
    customization.blurStyle = UIBlurEffect.Style.dark

    XCTAssertEqual(UIColor.red, customization.backgroundColor)
    XCTAssertEqual(customization.backgroundColor, customization.uiCustomization.backgroundColor)

    XCTAssertEqual(
      UIActivityIndicatorView.Style.whiteLarge, customization.activityIndicatorViewStyle)
    XCTAssertEqual(
      customization.activityIndicatorViewStyle,
      customization.uiCustomization.activityIndicatorViewStyle)

    XCTAssertEqual(UIBlurEffect.Style.dark, customization.blurStyle)
    XCTAssertEqual(customization.blurStyle, customization.uiCustomization.blurStyle)
  }
}

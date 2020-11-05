//
//  STPThreeDSTextFieldCustomizationTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 6/18/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

@testable import Stripe

class STPThreeDSTextFieldCustomizationTest: XCTestCase {
  func testPropertiesAreForwarded() {
    let customization = STPThreeDSTextFieldCustomization.defaultSettings()
    customization.font = UIFont.italicSystemFont(ofSize: 1)
    customization.textColor = UIColor.blue
    customization.borderWidth = -1
    customization.borderColor = UIColor.red
    customization.cornerRadius = -8
    customization.keyboardAppearance = .alert
    customization.placeholderTextColor = UIColor.green

    let stdsCustomization = customization.textFieldCustomization
    XCTAssertEqual(UIFont.italicSystemFont(ofSize: 1), stdsCustomization.font)
    XCTAssertEqual(stdsCustomization.font, customization.font)

    XCTAssertEqual(UIColor.blue, stdsCustomization.textColor)
    XCTAssertEqual(stdsCustomization.textColor, customization.textColor)

    XCTAssertEqual(-1, stdsCustomization.borderWidth, accuracy: 0.1)
    XCTAssertEqual(stdsCustomization.borderWidth, customization.borderWidth, accuracy: 0.1)

    XCTAssertEqual(UIColor.red, stdsCustomization.borderColor)
    XCTAssertEqual(stdsCustomization.borderColor, customization.borderColor)

    XCTAssertEqual(-8, stdsCustomization.cornerRadius, accuracy: 0.1)
    XCTAssertEqual(stdsCustomization.cornerRadius, customization.cornerRadius, accuracy: 0.1)

    XCTAssertEqual(UIKeyboardAppearance.alert, stdsCustomization.keyboardAppearance)
    XCTAssertEqual(stdsCustomization.keyboardAppearance, customization.keyboardAppearance)

    XCTAssertEqual(UIColor.green, stdsCustomization.placeholderTextColor)
    XCTAssertEqual(stdsCustomization.placeholderTextColor, customization.placeholderTextColor)
  }
}

//
//  STPThreeDSNavigationBarCustomizationTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 6/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

@testable import Stripe

class STPThreeDSNavigationBarCustomizationTest: XCTestCase {
  func testPropertiesAreForwarded() {
    let customization = STPThreeDSNavigationBarCustomization.defaultSettings()
    customization.font = UIFont.italicSystemFont(ofSize: 1)
    customization.textColor = UIColor.blue
    customization.barTintColor = UIColor.red
    customization.barStyle = UIBarStyle.blackOpaque
    customization.translucent = false
    customization.headerText = "foo"
    customization.buttonText = "bar"

    let stdsCustomization = customization.navigationBarCustomization
    XCTAssertEqual(UIFont.italicSystemFont(ofSize: 1), stdsCustomization.font)
    XCTAssertEqual(stdsCustomization.font, customization.font)

    XCTAssertEqual(UIColor.blue, stdsCustomization.textColor)
    XCTAssertEqual(stdsCustomization.textColor, customization.textColor)

    XCTAssertEqual(UIColor.red, stdsCustomization.barTintColor)
    XCTAssertEqual(stdsCustomization.barTintColor, customization.barTintColor)

    XCTAssertEqual(UIBarStyle.blackOpaque, stdsCustomization.barStyle)
    XCTAssertEqual(stdsCustomization.barStyle, customization.barStyle)

    XCTAssertEqual(false, stdsCustomization.translucent)
    XCTAssertEqual(stdsCustomization.translucent, customization.translucent)

    XCTAssertEqual("foo", stdsCustomization.headerText)
    XCTAssertEqual(stdsCustomization.headerText, customization.headerText)

    XCTAssertEqual("bar", stdsCustomization.buttonText)
    XCTAssertEqual(stdsCustomization.buttonText, customization.buttonText)
  }
}

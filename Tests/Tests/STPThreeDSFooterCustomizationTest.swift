//
//  STPThreeDSFooterCustomizationTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 6/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

@testable import Stripe

class STPThreeDSFooterCustomizationTest: XCTestCase {
  func testPropertiesAreForwarded() {
    let customization = STPThreeDSFooterCustomization.defaultSettings()
    customization.backgroundColor = UIColor.red
    customization.chevronColor = UIColor.blue
    customization.headingTextColor = UIColor.green
    customization.headingFont = UIFont.systemFont(ofSize: 1)
    customization.font = UIFont.systemFont(ofSize: 2)
    customization.textColor = UIColor.magenta

    let stdsCustomization = customization.footerCustomization

    XCTAssertEqual(UIColor.red, stdsCustomization.backgroundColor)
    XCTAssertEqual(stdsCustomization.backgroundColor, customization.backgroundColor)

    XCTAssertEqual(UIColor.blue, stdsCustomization.chevronColor)
    XCTAssertEqual(stdsCustomization.chevronColor, customization.chevronColor)

    XCTAssertEqual(UIColor.green, stdsCustomization.headingTextColor)
    XCTAssertEqual(stdsCustomization.headingTextColor, customization.headingTextColor)

    XCTAssertEqual(UIFont.systemFont(ofSize: 1), stdsCustomization.headingFont)
    XCTAssertEqual(stdsCustomization.headingFont, customization.headingFont)

    XCTAssertEqual(UIFont.systemFont(ofSize: 2), stdsCustomization.font)
    XCTAssertEqual(stdsCustomization.font, customization.font)

    XCTAssertEqual(UIColor.magenta, stdsCustomization.textColor)
    XCTAssertEqual(stdsCustomization.textColor, customization.textColor)
  }
}

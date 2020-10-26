//
//  STPThreeDSLabelCustomizationTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 6/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

@testable import Stripe

class STPThreeDSLabelCustomizationTest: XCTestCase {
  func testPropertiesAreForwarded() {
    let customization = STPThreeDSLabelCustomization.defaultSettings()
    customization.headingFont = UIFont.systemFont(ofSize: 1)
    customization.headingTextColor = UIColor.red
    customization.font = UIFont.systemFont(ofSize: 2)
    customization.textColor = UIColor.blue

    let stdsCustomization = customization.labelCustomization

    XCTAssertEqual(UIFont.systemFont(ofSize: 1), stdsCustomization.headingFont)
    XCTAssertEqual(stdsCustomization.headingFont, customization.headingFont)

    XCTAssertEqual(UIColor.red, stdsCustomization.headingTextColor)
    XCTAssertEqual(stdsCustomization.headingTextColor, customization.headingTextColor)

    XCTAssertEqual(UIFont.systemFont(ofSize: 2), stdsCustomization.font)
    XCTAssertEqual(stdsCustomization.font, customization.font)

    XCTAssertEqual(UIColor.blue, stdsCustomization.textColor)
    XCTAssertEqual(stdsCustomization.textColor, customization.textColor)
  }
}

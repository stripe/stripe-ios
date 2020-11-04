//
//  STPThreeDSSelectionCustomizationTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 6/18/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

@testable import Stripe

class STPThreeDSSelectionCustomizationTest: XCTestCase {
  func testPropertiesAreForwarded() {
    let customization = STPThreeDSSelectionCustomization.defaultSettings()
    customization.primarySelectedColor = UIColor.red
    customization.secondarySelectedColor = UIColor.blue
    customization.unselectedBorderColor = UIColor.brown
    customization.unselectedBackgroundColor = UIColor.cyan

    let stdsCustomization = customization.selectionCustomization
    XCTAssertEqual(UIColor.red, stdsCustomization.primarySelectedColor)
    XCTAssertEqual(stdsCustomization.primarySelectedColor, customization.primarySelectedColor)

    XCTAssertEqual(UIColor.blue, stdsCustomization.secondarySelectedColor)
    XCTAssertEqual(stdsCustomization.secondarySelectedColor, customization.secondarySelectedColor)

    XCTAssertEqual(UIColor.brown, stdsCustomization.unselectedBorderColor)
    XCTAssertEqual(stdsCustomization.unselectedBorderColor, customization.unselectedBorderColor)

    XCTAssertEqual(UIColor.cyan, stdsCustomization.unselectedBackgroundColor)
    XCTAssertEqual(
      stdsCustomization.unselectedBackgroundColor, customization.unselectedBackgroundColor)
  }
}

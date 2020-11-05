//
//  STPThreeDSButtonCustomizationTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 6/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

@testable import Stripe

class STPThreeDSButtonCustomizationTest: XCTestCase {
  func testPropertiesAreForwarded() {
    let customization = STPThreeDSButtonCustomization.defaultSettings(for: .next)
    customization.backgroundColor = UIColor.red
    customization.cornerRadius = -1
    customization.titleStyle = .lowercase
    customization.font = UIFont.italicSystemFont(ofSize: 1)
    customization.textColor = UIColor.blue

    let stdsCustomization = customization.buttonCustomization
    XCTAssertEqual(UIColor.red, stdsCustomization.backgroundColor)
    XCTAssertEqual(stdsCustomization.backgroundColor, customization.backgroundColor)

    XCTAssertEqual(-1, stdsCustomization.cornerRadius, accuracy: 0.1)
    XCTAssertEqual(stdsCustomization.cornerRadius, customization.cornerRadius, accuracy: 0.1)

    XCTAssertEqual(.lowercase, stdsCustomization.titleStyle)
    XCTAssertEqual(stdsCustomization.titleStyle.rawValue, customization.titleStyle.rawValue)

    XCTAssertEqual(UIFont.italicSystemFont(ofSize: 1), stdsCustomization.font)
    XCTAssertEqual(stdsCustomization.font, customization.font)

    XCTAssertEqual(UIColor.blue, stdsCustomization.textColor)
    XCTAssertEqual(stdsCustomization.textColor, customization.textColor)
  }
}

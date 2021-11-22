//
//  UIColor+StripeUICoreTests.swift
//  StripeUICoreTests
//
//  Created by Ramon Torres on 11/9/21.
//

import XCTest
@_spi(STP) @testable import StripeUICore

final class UIColorStripeUICoreTests: XCTestCase {

    func testLighten() {
        XCTAssertEqual(
            UIColor.black.lighten(by: 0.5),
            UIColor(hue: 0, saturation: 0, brightness: 0.5, alpha: 1)
        )

        XCTAssertEqual(
            UIColor.gray.lighten(by: 1),
            UIColor(hue: 0, saturation: 0, brightness: 1, alpha: 1)
        )

        XCTAssertEqual(
            UIColor(hue: 0, saturation: 0.5, brightness: 0.5, alpha: 1).lighten(by: 0.3),
            UIColor(hue: 0, saturation: 0.5, brightness: 0.8, alpha: 1)
        )
    }

    func testDarken() {
        XCTAssertEqual(
            UIColor.white.darken(by: 0.5),
            UIColor(hue: 0, saturation: 0, brightness: 0.5, alpha: 1)
        )

        XCTAssertEqual(
            UIColor.gray.darken(by: 1),
            UIColor(hue: 0, saturation: 0, brightness: 0, alpha: 1)
        )

        XCTAssertEqual(
            UIColor(hue: 0, saturation: 0.5, brightness: 0.5, alpha: 1).darken(by: 0.2),
            UIColor(hue: 0, saturation: 0.5, brightness: 0.3, alpha: 1)
        )
    }

}

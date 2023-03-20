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
            UIColor.black.lighten(by: 0.5).cgColor,
            UIColor(hue: 0, saturation: 0, brightness: 0.5, alpha: 1).cgColor
        )

        XCTAssertEqual(
            UIColor.gray.lighten(by: 1).cgColor,
            UIColor(hue: 0, saturation: 0, brightness: 1, alpha: 1).cgColor
        )

        XCTAssertEqual(
            UIColor(hue: 0, saturation: 0.5, brightness: 0.5, alpha: 1).lighten(by: 0.3).cgColor,
            UIColor(hue: 0, saturation: 0.5, brightness: 0.8, alpha: 1).cgColor
        )
    }

    func testDarken() {
        XCTAssertEqual(
            UIColor.white.darken(by: 0.5).cgColor,
            UIColor(hue: 0, saturation: 0, brightness: 0.5, alpha: 1).cgColor
        )

        XCTAssertEqual(
            UIColor.gray.darken(by: 1).cgColor,
            UIColor(hue: 0, saturation: 0, brightness: 0, alpha: 1).cgColor
        )

        XCTAssertEqual(
            UIColor(hue: 0, saturation: 0.5, brightness: 0.5, alpha: 1).darken(by: 0.2).cgColor,
            UIColor(hue: 0, saturation: 0.5, brightness: 0.3, alpha: 1).cgColor
        )
    }
    
    func testLuminance() {
        // Well-known color-luminance values
        let testCases: [(UIColor, CGFloat)] = [
            // Grays
            (UIColor(white: 0, alpha: 1), 0.0),
            (UIColor(white: 0.25, alpha: 1), 0.05),
            (UIColor(white: 0.5, alpha: 1), 0.21),
            (UIColor(white: 0.75, alpha: 1), 0.52),
            (UIColor(white: 1, alpha: 1), 1.0),
            // Colors (Extract Rec. 709 coefficients)
            (UIColor(red: 1, green: 0, blue: 0, alpha: 1), 0.2126),
            (UIColor(red: 0, green: 1, blue: 0, alpha: 1), 0.7152),
            (UIColor(red: 0, green: 0, blue: 1, alpha: 1), 0.0722)
        ]

        for (color, expectedLuminance) in testCases {
            XCTAssertEqual(color.luminance, expectedLuminance, accuracy: 0.01)
        }
    }

    func testContrastRatio() {
        // Highest contrast ratio
        XCTAssertEqual(UIColor.black.contrastRatio(to: .white), 21)
        XCTAssertEqual(UIColor.white.contrastRatio(to: .black), 21)

        // Lowest contrast ratio (identical colors)
        XCTAssertEqual(UIColor.red.contrastRatio(to: .red), 1)

        // Black to 50% gray
        XCTAssertEqual(UIColor.black.contrastRatio(to: .gray), 5.28, accuracy: 0.01)

        // Red to black
        XCTAssertEqual(UIColor.red.contrastRatio(to: .black), 5.25, accuracy: 0.01)
    }

}

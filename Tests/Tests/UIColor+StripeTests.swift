//
//  UIColor+StripeTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 9/30/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest

@testable import Stripe

class UIColor_StripeTests: XCTestCase {

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

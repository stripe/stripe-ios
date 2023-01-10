//
//  UIColor+StripeUICoreTests.swift
//  StripeUICoreTests
//
//  Created by Ramon Torres on 11/9/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) @testable import StripeUICore
import XCTest

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
            (UIColor(red: 0, green: 0, blue: 1, alpha: 1), 0.0722),
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

    func testGrayscaleColorsIsBright() {
        let space = CGColorSpaceCreateDeviceGray()
        var components: [CGFloat] = [0.0, 1.0]

        // Using 0.3 as the cutoff from bright/non-bright because that's what
        // the current implementation does.

        var white: CGFloat = 0.0
        while white < 0.3 {
            components[0] = white
            let cgcolor = CGColor(colorSpace: space, components: &components)!
            let color = UIColor(cgColor: cgcolor)

            XCTAssertFalse(color.isBright)
            white += CGFloat(0.05)
        }

        white = CGFloat(0.3001)
        while white < 2 {
            components[0] = white
            let cgcolor = CGColor(colorSpace: space, components: &components)!
            let color = UIColor(cgColor: cgcolor)

            XCTAssertTrue(color.isBright)
            white += CGFloat(0.1)
        }
    }

    func testBuiltinColorsIsBright() {
        // This is primarily to document what colors are considered bright/dark
        let brightColors = [
            UIColor.brown,
            UIColor.cyan,
            UIColor.darkGray,
            UIColor.gray,
            UIColor.green,
            UIColor.lightGray,
            UIColor.magenta,
            UIColor.orange,
            UIColor.white,
            UIColor.yellow,
        ]
        let darkColors = [
            UIColor.black,
            UIColor.blue,
            UIColor.clear,
            UIColor.purple,
            UIColor.red,
        ]

        for color in brightColors {
            XCTAssertTrue(color.isBright)
        }

        for color in darkColors {
            XCTAssertFalse(color.isBright)
        }
    }

    func testAllColorSpaces() {
        // block to create & check brightness of color in a given color space
        let testColorSpace: ((CFString, Bool) -> Void)? = { colorSpaceName, expectedToBeBright in
            // this a bright color in almost all color spaces
            let components: [CGFloat] = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0]

            var color: UIColor?
            let colorSpace = CGColorSpace(name: colorSpaceName)

            if let colorSpace = colorSpace {
                let cgcolor = CGColor(colorSpace: colorSpace, components: components)

                if let cgcolor = cgcolor {
                    color = UIColor(cgColor: cgcolor)
                }
            }

            if let color = color {
                if expectedToBeBright {
                    XCTAssertTrue(color.isBright)
                } else {
                    XCTAssertFalse(color.isBright)
                }
            } else {
                XCTFail("Could not create color for \(colorSpaceName)")
            }
        }

        let colorSpaceNames = [
            CGColorSpace.sRGB, CGColorSpace.dcip3, CGColorSpace.rommrgb, CGColorSpace.itur_709,
            CGColorSpace.displayP3, CGColorSpace.itur_2020, CGColorSpace.genericXYZ,
            CGColorSpace.linearSRGB, CGColorSpace.genericCMYK, CGColorSpace.acescgLinear,
            CGColorSpace.adobeRGB1998, CGColorSpace.extendedGray, CGColorSpace.extendedSRGB,
            CGColorSpace.genericRGBLinear, CGColorSpace.extendedLinearSRGB,
            CGColorSpace.genericGrayGamma2_2,
        ]

        let colorSpaceCount =
            MemoryLayout.size(ofValue: colorSpaceNames)
            / MemoryLayout.size(ofValue: colorSpaceNames[0])
        for i in 0..<colorSpaceCount {
            // CMYK is the only one where all 1's results in a dark color
            testColorSpace?(colorSpaceNames[i], colorSpaceNames[i] != CGColorSpace.genericCMYK)
        }

        testColorSpace?(CGColorSpace.linearGray, true)
        testColorSpace?(CGColorSpace.extendedLinearGray, true)

        // in LAB all 1's is dark
        testColorSpace?(CGColorSpace.genericLab, false)
    }
}

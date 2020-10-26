//
//  STPColorUtilsTest.swift
//  StripeiOS Tests
//
//  Created by Daniel Jackson on 5/29/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

import XCTest

@testable import Stripe

class STPColorUtilsTest: XCTestCase {
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

      XCTAssertFalse(STPColorUtils.colorIsBright(color))
      white += CGFloat(0.05)
    }

    white = CGFloat(0.3001)
    while white < 2 {
      components[0] = white
      let cgcolor = CGColor(colorSpace: space, components: &components)!
      let color = UIColor(cgColor: cgcolor)

      XCTAssertTrue(STPColorUtils.colorIsBright(color))
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
      XCTAssertTrue(STPColorUtils.colorIsBright(color))
    }

    for color in darkColors {
      XCTAssertFalse(STPColorUtils.colorIsBright(color))
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
          XCTAssertTrue(STPColorUtils.colorIsBright(color))
        } else {
          XCTAssertFalse(STPColorUtils.colorIsBright(color))
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
      MemoryLayout.size(ofValue: colorSpaceNames) / MemoryLayout.size(ofValue: colorSpaceNames[0])
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

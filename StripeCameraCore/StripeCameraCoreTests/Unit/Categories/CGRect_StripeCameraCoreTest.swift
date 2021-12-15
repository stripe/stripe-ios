//
//  CGRect_StripeCameraCoreTest.swift
//  StripeCameraCoreTests
//
//  Created by Mel Ludowise on 12/14/21.
//

import XCTest
import CoreGraphics
@_spi(STP) import StripeCameraCore

class CGRect_StripeCameraCoreTest: XCTestCase {
    func testInvertedNormalizedCoordinates() {
        let rect = CGRect(x: 0.1, y: 0.1, width: 0.5, height: 0.5)
        let invertedRect = rect.invertedNormalizedCoordinates

        XCTAssertEqual(invertedRect.minX, 0.1)
        XCTAssertEqual(invertedRect.minY, 0.4)
        XCTAssertEqual(invertedRect.width, 0.5)
        XCTAssertEqual(invertedRect.height, 0.5)
    }
}

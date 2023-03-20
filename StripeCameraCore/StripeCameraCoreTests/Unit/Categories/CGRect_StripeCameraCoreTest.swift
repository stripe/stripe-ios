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

    func testConvertFromNormalizedCenterCropSquareLandscape() {
        // Centered-square rect corresponds to (350,0) 900x900
        let originalSize = CGSize(width: 1600, height: 900)


        // Corresponds to actual coordinates of
        // (350+900*0.25,900*0.25) 900*0.25 x 900*0.25
        // = (575,225) 225x225
        let normalizedSquareRect = CGRect(x: 0.25, y: 0.25, width: 0.25, height: 0.25)


        // Should have coordinates of
        // (575/1600, 225/900) 225/1600 x 225/900
        // = (0.359375,0.25) 0.140625 x 0.25
        let convertedRect = normalizedSquareRect.convertFromNormalizedCenterCropSquare(toOriginalSize: originalSize)

        
        XCTAssertEqual(convertedRect.minX, 0.359375)
        XCTAssertEqual(convertedRect.minY, 0.25)
        XCTAssertEqual(convertedRect.width, 0.140625)
        XCTAssertEqual(convertedRect.height, 0.25)
    }

    func testConvertFromNormalizedCenterCropSquarePortrait() {
        // Centered-square rect corresponds to (0,350) 900x900
        let originalSize = CGSize(width: 900, height: 1600)


        // Corresponds to actual coordinates of
        // (900*0.25,350+900*0.25) 900*0.25 x 900*0.25
        // = (225,575) 225x225
        let normalizedSquareRect = CGRect(x: 0.25, y: 0.25, width: 0.25, height: 0.25)


        // Should have coordinates of
        // (225/900, 575/1600) 225/900 x 225/1600
        // = (0.25,0.359375) 0.25 x 0.140625
        let convertedRect = normalizedSquareRect.convertFromNormalizedCenterCropSquare(toOriginalSize: originalSize)


        XCTAssertEqual(convertedRect.minX, 0.25)
        XCTAssertEqual(convertedRect.minY, 0.359375)
        XCTAssertEqual(convertedRect.width, 0.25)
        XCTAssertEqual(convertedRect.height, 0.140625)
    }

}

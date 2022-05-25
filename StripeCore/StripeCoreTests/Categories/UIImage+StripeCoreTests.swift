//
//  UIImage+StripeTests.swift
//  Stripe
//
//  Created by Brian Dorfman on 4/25/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//
import XCTest
@_spi(STP) @testable import StripeCore

class UIImage_StripeTests: XCTestCase {
    static let testJpegImageResizingKBiggerSize = 50000
    static let testJpegImageResizingKSmallerSize = 6000
    static let testJpegImageResizingKMuchSmallerSize = 5000  // don't make this too low or test becomes somewhat meaningless, as jpegs can only get so small

    func testJpegImageResizing() {
        // Strategy is to grab an image from our bundle and pass to the resizer
        // with maximums both larger and smaller than it already is
        // then make sure we get what we expect

        guard let testImage = UIImage(named: "test_image", in: Bundle(for: UIImage_StripeTests.self), compatibleWith: nil) else {
            return XCTFail("Could not load test image")
        }

        // Verify that before being passed to resizer it is within the
        // correct size range for our tests to be meaningful
        var data = testImage.jpegData(compressionQuality: 0.5)!

        XCTAssertLessThan(data.count, UIImage_StripeTests.testJpegImageResizingKBiggerSize)
        XCTAssertGreaterThan(data.count, UIImage_StripeTests.testJpegImageResizingKSmallerSize)
        XCTAssertGreaterThan(data.count, UIImage_StripeTests.testJpegImageResizingKMuchSmallerSize)

        // This is the size the data would be without scaling it less than maxBytes
        let baselineSize = data.count

        // Test passing in a maxBytes larger than original image
        data = testImage.jpegDataAndDimensions(
            maxBytes: UIImage_StripeTests.testJpegImageResizingKBiggerSize).imageData
        var resultingImage = UIImage(data: data, scale: testImage.scale)!
        XCTAssertLessThan(data.count, UIImage_StripeTests.testJpegImageResizingKBiggerSize)
        // Image shouldn't have been shrunk at all
        XCTAssertEqual(resultingImage.size, testImage.size)

        // Test passing in a maxBytes a bit smaller than the original image
        data = testImage.jpegDataAndDimensions(
            maxBytes: UIImage_StripeTests.testJpegImageResizingKSmallerSize).imageData
        resultingImage = UIImage(data: data, scale: testImage.scale)!
        XCTAssertNotNil(data)
        XCTAssertLessThan(data.count, UIImage_StripeTests.testJpegImageResizingKSmallerSize)
        XCTAssertLessThan(resultingImage.size.width, testImage.size.width)
        XCTAssertLessThan(resultingImage.size.height, testImage.size.height)

        // Test passing in a maxBytes a lot smaller than the original image
        data = testImage.jpegDataAndDimensions(
            maxBytes: UIImage_StripeTests.testJpegImageResizingKMuchSmallerSize).imageData
        resultingImage = UIImage(data: data, scale: testImage.scale)!
        XCTAssertNotNil(data)
        XCTAssertLessThan(data.count, UIImage_StripeTests.testJpegImageResizingKMuchSmallerSize)
        XCTAssertLessThan(resultingImage.size.width, testImage.size.width)
        XCTAssertLessThan(resultingImage.size.height, testImage.size.height)

        // Test passing in nil maxBytes
        data = testImage.jpegDataAndDimensions(maxBytes: nil).imageData
        resultingImage = UIImage(data: data, scale: testImage.scale)!
        XCTAssertNotNil(data)
        XCTAssertEqual(data.count, baselineSize)
        XCTAssertEqual(resultingImage.size, testImage.size)
    }
}

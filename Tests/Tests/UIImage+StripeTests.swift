//
//  UIImage+StripeTests.swift
//  Stripe
//
//  Created by Brian Dorfman on 4/25/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//
@testable import Stripe

class UIImage_StripeTests: XCTestCase {
  static let testJpegImageResizingKBiggerSize = 50000
  static let testJpegImageResizingKSmallerSize = 6000
  static let testJpegImageResizingKMuchSmallerSize = 5000  // don't make this too low or test becomes somewhat meaningless, as jpegs can only get so small

  func testJpegImageResizing() {
    // Strategy is to grab an image from our bundle and pass to the resizer
    // with maximums both larger and smaller than it already is
    // then make sure we get what we expect

    let testImage = STPImageLibrary.safeImageNamed(
      "stp_shipping_form.png",
      templateIfAvailable: false)

    // Verify that before being passed to resizer it is within the
    // correct size range for our tests to be meaningful
    var data = testImage.jpegData(compressionQuality: 0.5)!
    XCTAssertTrue(data.count < UIImage_StripeTests.testJpegImageResizingKBiggerSize)
    XCTAssertTrue(data.count > UIImage_StripeTests.testJpegImageResizingKSmallerSize)
    XCTAssertTrue(data.count > UIImage_StripeTests.testJpegImageResizingKMuchSmallerSize)

    // Test passing in a maxBytes larger than original image
    data = testImage.stp_jpegData(
      withMaxFileSize: UIImage_StripeTests.testJpegImageResizingKBiggerSize)
    XCTAssertTrue(data.count < UIImage_StripeTests.testJpegImageResizingKBiggerSize)
    let resizedImage = UIImage(data: data, scale: testImage.scale)!
    // Image shouldn't have been shrunk at all
    XCTAssertTrue(resizedImage.size.equalTo(testImage.size))

    // Test passing in a maxBytes a bit smaller than the original image
    data = testImage.stp_jpegData(
      withMaxFileSize: UIImage_StripeTests.testJpegImageResizingKSmallerSize)
    XCTAssertNotNil(data)
    XCTAssertTrue(data.count < UIImage_StripeTests.testJpegImageResizingKSmallerSize)

    // Test passing in a maxBytes a lot smaller than the original image
    data = testImage.stp_jpegData(
      withMaxFileSize: UIImage_StripeTests.testJpegImageResizingKMuchSmallerSize)
    XCTAssertNotNil(data)
    XCTAssertTrue(data.count < UIImage_StripeTests.testJpegImageResizingKMuchSmallerSize)
  }
}

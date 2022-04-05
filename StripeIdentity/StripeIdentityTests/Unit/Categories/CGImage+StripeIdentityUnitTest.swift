//
//  CGImage+StripeIdentityUnitTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 12/10/21.
//

import XCTest
import CoreImage
@testable import StripeIdentity

final class CGImage_StripeIdentityUnitTest: XCTestCase {

    let imageSizeLandscape = CGSize(width: 1600, height: 900)
    let imageSizePortrait = CGSize(width: 900, height: 1600)
    private var cgImageLandscape: CGImage!
    private var cgImagePortrait: CGImage!

    override func setUp() {
        super.setUp()

        cgImageLandscape = makeImage(ofSize: imageSizeLandscape)
        cgImagePortrait = makeImage(ofSize: imageSizePortrait)
    }

    // Tests that the padding is based on width when > height
    func testComputePaddingLandscape() {
        let padding = cgImageLandscape.computePixelPadding(padding: 0.08)

        // Actual padding should be 0.08 * 1600 = 128px
        XCTAssertEqual(padding, 128)
    }

    // Tests that the padding is based on height when > width
    func testComputePaddingPortrait() {
        let padding = cgImagePortrait.computePixelPadding(padding: 0.08)

        // Actual padding should be 0.08 * 1600 = 128px
        XCTAssertEqual(padding, 128)
    }

    func testComputePixelCropArea() {
        // Equivalent to pixel coordinates (200, 200, 200, 200)
        // for landscape image
        let normalizedRegion = CGRect(x: 0.125, y: 0.2222, width: 0.125, height: 0.2222)
        let pixelPadding: CGFloat = 100

        let expectedCropArea = CGRect(x: 100, y: 100, width: 400, height: 400)
        let actualCropArea = cgImageLandscape.computePixelCropArea(normalizedRegion: normalizedRegion, pixelPadding: pixelPadding)

        XCTAssertEqual(round(actualCropArea.minX), expectedCropArea.minX)
        XCTAssertEqual(round(actualCropArea.minY), expectedCropArea.minY)
        XCTAssertEqual(round(actualCropArea.width), expectedCropArea.width)
        XCTAssertEqual(round(actualCropArea.height), expectedCropArea.height)
    }

    // Tests when an image's width and height are bigger than the max dimensions
    func testComputeScaleTooBigAllDimensions() {
        let maxDimension = CGSize(width: 800, height: 800)
        let scale = cgImageLandscape.computeScale(maxPixelDimension: maxDimension)

        // Actual scale should be 800 / 1600 = 0.5
        XCTAssertEqual(scale, 0.5)
    }

    // Tests when an image's width is bigger than max dimension, but not height
    func testComputeScaleTooBigWidth() {
        let maxDimension = CGSize(width: 1000, height: 1000)
        let scale = cgImageLandscape.computeScale(maxPixelDimension: maxDimension)

        // Actual scale should be 1000 / 1600 = 0.625
        XCTAssertEqual(scale, 0.625)
    }

    // Tests when an image's height is bigger than max dimension, but not height
    func testComputeScaleTooBigHeight() {
        let maxDimension = CGSize(width: 1000, height: 1000)
        let scale = cgImagePortrait.computeScale(maxPixelDimension: maxDimension)

        // Actual scale should be 1000 / 1600 = 0.625
        XCTAssertEqual(scale, 0.625)
    }

    // Tests when an image is the exact size of the max dimension
    func testComputeScaleExactSize() {
        let maxDimension = imageSizeLandscape
        let scale = cgImageLandscape.computeScale(maxPixelDimension: maxDimension)

        // Actual scale should be 1
        XCTAssertEqual(scale, 1)
    }

    // Tests when an image is smaller than the max dimension
    func testComputeScaleSmaller() {
        let maxDimension = CGSize(width: 2000, height: 2000)
        guard let scaledImage = cgImageLandscape.scaledDown(toMaxPixelDimension: maxDimension) else {
            return XCTFail("Image is nil")
        }

        XCTAssertEqual(CGFloat(scaledImage.width), imageSizeLandscape.width)
        XCTAssertEqual(CGFloat(scaledImage.height), imageSizeLandscape.height)
    }

    // Tests when an image's width and height are bigger than the max dimensions
    func testScaleImageTooBigAllDimensions() {
        let maxDimension = CGSize(width: 800, height: 800)
        guard let scaledImage = cgImageLandscape.scaledDown(toMaxPixelDimension: maxDimension) else {
            return XCTFail("Image is nil")
        }

        XCTAssertEqual(CGFloat(scaledImage.width), 800)
        XCTAssertEqual(CGFloat(scaledImage.height), 450)
    }

    // Tests when an image's width is bigger than max dimension, but not height
    func testScaleImageTooBigWidth() {
        let maxDimension = CGSize(width: 1000, height: 1000)
        guard let scaledImage = cgImageLandscape.scaledDown(toMaxPixelDimension: maxDimension) else {
            return XCTFail("Image is nil")
        }

        XCTAssertEqual(CGFloat(scaledImage.width), 1000)
        XCTAssertEqual(CGFloat(scaledImage.height), 562)
    }

    // Tests when an image's height is bigger than max dimension, but not height
    func testScaleImageTooBigHeight() {
        let maxDimension = CGSize(width: 1000, height: 1000)
        guard let scaledImage = cgImagePortrait.scaledDown(toMaxPixelDimension: maxDimension) else {
            return XCTFail("Image is nil")
        }

        XCTAssertEqual(CGFloat(scaledImage.width), 562)
        XCTAssertEqual(CGFloat(scaledImage.height), 1000)
    }

    // Tests when an image is the exact size of the max dimension
    func testScaleImageExactSize() {
        let maxDimension = imageSizeLandscape
        guard let scaledImage = cgImageLandscape.scaledDown(toMaxPixelDimension: maxDimension) else {
            return XCTFail("Image is nil")
        }

        XCTAssertEqual(CGFloat(scaledImage.width), imageSizeLandscape.width)
        XCTAssertEqual(CGFloat(scaledImage.height), imageSizeLandscape.height)
    }

    // Tests when an image is smaller than the max dimension
    func testScaleImageSmaller() {
        let maxDimension = CGSize(width: 2000, height: 2000)
        guard let scaledImage = cgImageLandscape.scaledDown(toMaxPixelDimension: maxDimension) else {
            return XCTFail("Image is nil")
        }

        XCTAssertEqual(CGFloat(scaledImage.width), imageSizeLandscape.width)
        XCTAssertEqual(CGFloat(scaledImage.height), imageSizeLandscape.height)
    }
}

private extension CGImage_StripeIdentityUnitTest {
    func makeImage(ofSize size: CGSize) -> CGImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        let uiImage = UIGraphicsImageRenderer(size: size, format: format).image { context in
            context.fill(CGRect(origin: .zero, size: size))
        }
        return uiImage.cgImage!
    }
}

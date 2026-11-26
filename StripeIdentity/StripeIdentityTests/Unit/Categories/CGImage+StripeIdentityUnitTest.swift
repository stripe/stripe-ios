//
//  CGImage+StripeIdentityUnitTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 12/10/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import CoreImage
import XCTest

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
    func testComputePaddingLandscapeMaxImageWidthOrHeight() {
        // Equivalent to pixel coordinates (200, 200, 400, 200)
        // for landscape image
        let normalizedRegion = CGRect(x: 0.125, y: 0.2222, width: 0.25, height: 0.2222)

        let padding = cgImageLandscape.computePixelPadding(
            padding: 0.08,
            normalizedRegion: normalizedRegion,
            computationMethod: .maxImageWidthOrHeight
        )

        // Actual padding should be 0.08 * 1600 = 128px
        XCTAssertEqual(padding, 128, accuracy: 0.5)
    }

    // Tests that the padding is based on height when > width
    func testComputePaddingPortraitMaxImageWidthOrHeight() {
        // Equivalent to pixel coordinates (200, 200, 200, 400)
        // for portrait image
        let normalizedRegion = CGRect(x: 0.2222, y: 0.125, width: 0.2222, height: 0.25)

        let padding = cgImagePortrait.computePixelPadding(
            padding: 0.08,
            normalizedRegion: normalizedRegion,
            computationMethod: .maxImageWidthOrHeight
        )

        // Actual padding should be 0.08 * 1600 = 128px
        XCTAssertEqual(padding, 128, accuracy: 0.5)
    }

    func testComputePaddingLandscapeRegionWidth() {
        // Equivalent to pixel coordinates (200, 200, 400, 200)
        // for landscape image
        let normalizedRegion = CGRect(x: 0.125, y: 0.2222, width: 0.25, height: 0.2222)

        let padding = cgImageLandscape.computePixelPadding(
            padding: 0.08,
            normalizedRegion: normalizedRegion,
            computationMethod: .regionWidth
        )

        // Actual padding should be 0.08 * 400 = 32px
        XCTAssertEqual(padding, 32, accuracy: 0.5)
    }

    func testComputePaddingPortraitRegionWidth() {
        // Equivalent to pixel coordinates (200, 200, 200, 400)
        // for portrait image
        let normalizedRegion = CGRect(x: 0.2222, y: 0.125, width: 0.2222, height: 0.25)

        let padding = cgImagePortrait.computePixelPadding(
            padding: 0.08,
            normalizedRegion: normalizedRegion,
            computationMethod: .regionWidth
        )

        // Actual padding should be 0.08 * 200 = 16px
        XCTAssertEqual(padding, 16, accuracy: 0.5)
    }

    func testComputePixelCropArea() {
        // Equivalent to pixel coordinates (200, 200, 200, 200)
        // for landscape image
        let normalizedRegion = CGRect(x: 0.125, y: 0.2222, width: 0.125, height: 0.2222)
        let pixelPadding: CGFloat = 100

        let expectedCropArea = CGRect(x: 100, y: 100, width: 400, height: 400)
        let actualCropArea = cgImageLandscape.computePixelCropArea(
            normalizedRegion: normalizedRegion,
            pixelPadding: pixelPadding
        )

        XCTAssertEqual(round(actualCropArea.minX), expectedCropArea.minX)
        XCTAssertEqual(round(actualCropArea.minY), expectedCropArea.minY)
        XCTAssertEqual(round(actualCropArea.width), expectedCropArea.width)
        XCTAssertEqual(round(actualCropArea.height), expectedCropArea.height)
    }

    func testFaceLandmarksCropAreaMatchesWebForCenteredFace() {
        // Given a face at pixel edges (337.5, 600, 562.5, 1000) in the 900x1600 image
        let face = CGRect(x: 0.375, y: 0.375, width: 0.25, height: 0.25)

        // When the crop uses the default MediaPipe padding
        let cropArea = cgImagePortrait.computeFaceLandmarksCropArea(
            normalizedFaceRegion: face,
            sidePadding: 0.5,
            topPadding: 0.25,
            bottomPadding: 0.35
        )

        // Then it matches web: the expanded box (330.75, 480, 573.75, 1025) gets
        // 121.5 pixels on each side, plus 136.25 above and 190.75 below
        assertEqual(cropArea, CGRect(x: 209.25, y: 222.25, width: 486, height: 1115))
    }

    func testFaceLandmarksCropAreaMatchesWebForFacesNearEdges() {
        // Given faces near the top-left and bottom-right corners of the 900x1600 image
        let topLeftFace = CGRect(x: 0.0625, y: 0.0625, width: 0.25, height: 0.25)
        let bottomRightFace = CGRect(x: 0.75, y: 0.75, width: 0.25, height: 0.25)

        // When the crops use the default MediaPipe padding
        let topLeftCrop = cgImagePortrait.computeFaceLandmarksCropArea(
            normalizedFaceRegion: topLeftFace,
            sidePadding: 0.5,
            topPadding: 0.25,
            bottomPadding: 0.35
        )
        let bottomRightCrop = cgImagePortrait.computeFaceLandmarksCropArea(
            normalizedFaceRegion: bottomRightFace,
            sidePadding: 0.5,
            topPadding: 0.25,
            bottomPadding: 0.35
        )

        // Then the clamped origin keeps the full padded size, as on web
        assertEqual(topLeftCrop, CGRect(x: 0, y: 0, width: 463.5, height: 923.75))

        // ...and the size is limited to the remaining image pixels
        assertEqual(bottomRightCrop, CGRect(x: 542.25, y: 680.75, width: 357.75, height: 919.25))
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
    func testComputeScaleSmaller() throws {
        let maxDimension = CGSize(width: 2000, height: 2000)
        let scaledImage = try cgImageLandscape.scaledDown(toMaxPixelDimension: maxDimension)

        XCTAssertEqual(CGFloat(scaledImage.width), imageSizeLandscape.width)
        XCTAssertEqual(CGFloat(scaledImage.height), imageSizeLandscape.height)
    }

    // Tests when an image's width and height are bigger than the max dimensions
    func testScaleImageTooBigAllDimensions() throws {
        let maxDimension = CGSize(width: 800, height: 800)
        let scaledImage = try cgImageLandscape.scaledDown(toMaxPixelDimension: maxDimension)

        XCTAssertEqual(CGFloat(scaledImage.width), 800)
        XCTAssertEqual(CGFloat(scaledImage.height), 450)
    }

    // Tests when an image's width is bigger than max dimension, but not height
    func testScaleImageTooBigWidth() throws {
        let maxDimension = CGSize(width: 1000, height: 1000)
        let scaledImage = try cgImageLandscape.scaledDown(toMaxPixelDimension: maxDimension)

        XCTAssertEqual(CGFloat(scaledImage.width), 1000)
        XCTAssertEqual(CGFloat(scaledImage.height), 562)
    }

    // Tests when an image's height is bigger than max dimension, but not height
    func testScaleImageTooBigHeight() throws {
        let maxDimension = CGSize(width: 1000, height: 1000)
        let scaledImage = try cgImagePortrait.scaledDown(toMaxPixelDimension: maxDimension)

        XCTAssertEqual(CGFloat(scaledImage.width), 562)
        XCTAssertEqual(CGFloat(scaledImage.height), 1000)
    }

    // Tests when an image is the exact size of the max dimension
    func testScaleImageExactSize() throws {
        let maxDimension = imageSizeLandscape
        let scaledImage = try cgImageLandscape.scaledDown(toMaxPixelDimension: maxDimension)

        XCTAssertEqual(CGFloat(scaledImage.width), imageSizeLandscape.width)
        XCTAssertEqual(CGFloat(scaledImage.height), imageSizeLandscape.height)
    }

    // Tests when an image is smaller than the max dimension
    func testScaleImageSmaller() throws {
        let maxDimension = CGSize(width: 2000, height: 2000)
        let scaledImage = try cgImageLandscape.scaledDown(toMaxPixelDimension: maxDimension)

        XCTAssertEqual(CGFloat(scaledImage.width), imageSizeLandscape.width)
        XCTAssertEqual(CGFloat(scaledImage.height), imageSizeLandscape.height)
    }
}

extension CGImage_StripeIdentityUnitTest {
    fileprivate func assertEqual(
        _ actual: CGRect,
        _ expected: CGRect,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(actual.minX, expected.minX, accuracy: 1e-9, file: file, line: line)
        XCTAssertEqual(actual.minY, expected.minY, accuracy: 1e-9, file: file, line: line)
        XCTAssertEqual(actual.width, expected.width, accuracy: 1e-9, file: file, line: line)
        XCTAssertEqual(actual.height, expected.height, accuracy: 1e-9, file: file, line: line)
    }

    fileprivate func makeImage(ofSize size: CGSize) -> CGImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        let uiImage = UIGraphicsImageRenderer(size: size, format: format).image { context in
            context.fill(CGRect(origin: .zero, size: size))
        }
        return uiImage.cgImage!
    }
}

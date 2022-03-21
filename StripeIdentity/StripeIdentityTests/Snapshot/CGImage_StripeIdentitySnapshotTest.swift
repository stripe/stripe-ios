//
//  CGImage_StripeIdentitySnapshotTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 12/13/21.
//

import FBSnapshotTestCase
import CoreImage
@testable import StripeIdentity

/*
 For an overview of the expected results for these tests, see
 CGImage_StripeIdentitySnapshotTest.png

 Solid lines represent the region of interest (ROI) and dotted lines
 represent the expected crop area that includes padding.
 */
final class CGImage_StripeIdentitySnapshotTest: FBSnapshotTestCase {

    // Image dimensions are 3024 × 4032
    let image: CGImage = SnapshotTestMockData.cgImage(image: .cgImage)

    // Pixel padding = 0.08 * 4032 = 332.56
    let padding: CGFloat = 0.08

    override func setUp() {
        super.setUp()

//        recordMode = true
    }

    /*
     Tests the case that the region of interest + padding are complete contained
     inside the image bounds:
         +-----------------+
         |   + - - - - +   |
         |   ┆ +-----+ ┆   |
         |   ┆ | ROI | ┆   |
         |   ┆ +-----+ ┆   |
         |   + - - - - +   |
         +-----------------+
     */
    func testCropContained() {
        let regionOfInterestPixels = CGRect(x: 1262, y: 1766, width: 500, height: 500)
        let normalizedRegion = imageNormalizeRect(for: regionOfInterestPixels)
        let croppedImage = image.cropping(
            toNormalizedRegion: normalizedRegion,
            withPadding: padding
        )
        snapshotVerifyImage(croppedImage)
    }

    /*
     Tests the case that the region of interest is contained inside the image
     bounds, but the padding is not:
       + - - - - - - +
       ┆ +-----------------+
       ┆ | +-----+   ┆     |
       ┆ | | ROI |   ┆     |
       ┆ | +-----+   ┆     |
       ┆ |           ┆     |
       + | - - - - - +     |
         +-----------------+
     */
    func testCropPaddingUncontainedTopLeft() {
        let regionOfInterestPixels = CGRect(x: 100, y: 100, width: 500, height: 500)
        let normalizedRegion = imageNormalizeRect(for: regionOfInterestPixels)
        let croppedImage = image.cropping(
            toNormalizedRegion: normalizedRegion,
            withPadding: padding
        )
        snapshotVerifyImage(croppedImage)
    }

    /*
     Tests the case that the region of interest is contained inside the image
     bounds, but the padding is not:
         +-----------------+
         |     + - - - - - | +
         |     ┆           | ┆
         |     ┆   +-----+ | ┆
         |     ┆   | ROI | | ┆
         |     ┆   +-----+ | ┆
         +-----------------+ ┆
               + - - - - - - +
     */
    func testCropPaddingUncontainedBottomRight() {
        let regionOfInterestPixels = CGRect(x: 2424, y: 3432, width: 500, height: 500)
        let normalizedRegion = imageNormalizeRect(for: regionOfInterestPixels)
        let croppedImage = image.cropping(
            toNormalizedRegion: normalizedRegion,
            withPadding: padding
        )
        snapshotVerifyImage(croppedImage)
    }

    /*
     Tests the case that the region of interest is contained outside the
     image:
               +-----------------+
               |                 |
         + - - - - - - +         |
         ┆  +--|---+   ┆         |
         ┆  |  |   |   ┆         |
         ┆  | R|OI |   ┆         |
         ┆  |  +---|-------------+
         ┆  +------+   ┆
         + - - - - - - +
     */
    func testCropROIUncontainedBottomLeft() {
        let regionOfInterestPixels = CGRect(x: -20, y: 3552, width: 500, height: 500)
        let normalizedRegion = imageNormalizeRect(for: regionOfInterestPixels)
        let croppedImage = image.cropping(
            toNormalizedRegion: normalizedRegion,
            withPadding: padding
        )
        snapshotVerifyImage(croppedImage)
    }

    /*
     Tests the case that the region of interest is contained outside the
     image:
                   + - - - - - - +
                   ┆   +------+  ┆
         +-------------|---+  |  ┆
         |         ┆   | RO|I |  ┆
         |         ┆   |   |  |  ┆
         |         ┆   +---|--+  ┆
         |         + - - - - - - +
         |                 |
         +-----------------+
     */
    func testCropROIUncontainedTopRight() {
        let regionOfInterestPixels = CGRect(x: 2544, y: -20, width: 500, height: 500)
        let normalizedRegion = imageNormalizeRect(for: regionOfInterestPixels)
        let croppedImage = image.cropping(
            toNormalizedRegion: normalizedRegion,
            withPadding: padding
        )
        snapshotVerifyImage(croppedImage)
    }
}

private extension CGImage_StripeIdentitySnapshotTest {
    /// Uses `FBSnapshotVerifyView` to verify image by creating a `UIImageView`
    func snapshotVerifyImage(
        _ image: CGImage?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let image = image else {
            return XCTFail("Image was nil", file: file, line: line)
        }
        let view = UIImageView(image: UIImage(cgImage: image))
        // NOTE: Small tolerance to account for discrepancies between CI vs. running locally
        FBSnapshotVerifyView(view, perPixelTolerance: 0.01, file: file, line: line)
    }

    /// Helper method to normalize rects into image coordinates
    func imageNormalizeRect(for rect: CGRect) -> CGRect {
        return CGRect(
            x: rect.minX / CGFloat(image.width),
            y: rect.minY / CGFloat(image.height),
            width: rect.width / CGFloat(image.width),
            height: rect.height / CGFloat(image.height)
        )
    }
}

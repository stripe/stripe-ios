//
//  CIImage+StripeIdentity.swift
//  StripeCameraCore
//
//  Created by Mel Ludowise on 12/8/21.
//

import CoreImage
@_spi(STP) import StripeCameraCore

extension CIImage {
    /**
     Crops the image to a given region of interest plus padding.

     - Parameters:
       - invertedNormalizedRegion: A rect, in image coordinates, defining the area to add padding to and then crop, where origin is top-left.
       - cropPadding: A value, ranging between 0–1, that is added as padding to the region of interest.

     - Returns: An image cropped to the given specifications.

     - Note:
     The pixel value of the padding added to region of interest is defined as `cropPadding * max(width, height)`.
     */
    func cropped(
        toInvertedNormalizedRegion invertedNormalizedRegion: CGRect,
        withPadding cropPadding: CGFloat
    ) -> CIImage {
        let normalizedRegion = invertedNormalizedRegion.invertedNormalizedCoordinates
        return cropped(to: computePixelCropArea(
            normalizedRegion: normalizedRegion,
            pixelPadding: computePixelPadding(padding: cropPadding)
        ))
    }

    /**
     Crops the image to a given region of interest plus padding.

     - Parameters:
       - normalizedRegion: A rect, in image coordinates, defining the area to add padding to and then crop, where origin is bottom-left.
       - cropPadding: A value, ranging between 0–1, that is added as padding to the region of interest.

     - Returns: An image cropped to the given specifications.

     - Note:
     The pixel value of the padding added to region of interest is defined as `cropPadding * max(width, height)`.
     */
    func cropped(
        toNormalizedRegion normalizedRegion: CGRect,
        withPadding cropPadding: CGFloat
    ) -> CIImage {
        return cropped(to: computePixelCropArea(
            normalizedRegion: normalizedRegion,
            pixelPadding: computePixelPadding(padding: cropPadding)
        ))
    }

    func computePixelPadding(
        padding: CGFloat
    ) -> CGFloat {
        return padding * max(extent.width, extent.height)
    }

    func computePixelCropArea(
        normalizedRegion: CGRect,
        pixelPadding: CGFloat
    ) -> CGRect {
        let pixelRegionOfInterest = CGRect(
            x: normalizedRegion.minX * extent.width,
            y: normalizedRegion.minY * extent.height,
            width: normalizedRegion.width * extent.width,
            height: normalizedRegion.height * extent.height
        )
        return pixelRegionOfInterest.insetBy(
            dx: -pixelPadding,
            dy: -pixelPadding
        )
    }

    /**
     Scales the image, maintaining its aspect ratio, to a maximum dimension.
     If the image size is already smaller than the given dimension, it will
     maintain its original dimension.

     - Parameter maxPixelDimension: The maximum dimensions, in pixels, the returned image should be.

     - Returns: An image scaled down to the max dimensions.
     */
    func scaledDown(
        toMaxPixelDimension maxPixelDimension: CGSize
    ) -> CIImage {
        let scale = computeScale(maxPixelDimension: maxPixelDimension)

        let transform = CGAffineTransform(scaleX: scale, y: scale)
        return self.transformed(by: transform)
    }

    func computeScale(
        maxPixelDimension: CGSize
    ) -> CGFloat {
        let horizontalScale = min(maxPixelDimension.width, extent.width) / extent.width
        let verticalScale = min(maxPixelDimension.height, extent.height) / extent.height
        return min(horizontalScale, verticalScale)
    }
}

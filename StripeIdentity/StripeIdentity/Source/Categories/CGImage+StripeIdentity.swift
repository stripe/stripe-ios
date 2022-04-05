//
//  CGImage+StripeIdentity.swift
//  StripeCameraCore
//
//  Created by Mel Ludowise on 12/8/21.
//

import CoreGraphics
import UIKit
@_spi(STP) import StripeCore

extension CGImage {
    /**
     Crops the image to a given region of interest plus padding.

     - Parameters:
       - normalizedRegion: A rect, in image coordinates, defining the area to add padding to and then crop, where origin is bottom-left.
       - cropPadding: A value, ranging between 0–1, that is added as padding to the region of interest.

     - Returns: An image cropped to the given specifications.

     - Note:
     The pixel value of the padding added to region of interest is defined as `cropPadding * max(width, height)`.
     */
    func cropping(
        toNormalizedRegion normalizedRegion: CGRect,
        withPadding cropPadding: CGFloat
    ) -> CGImage? {
        return cropping(to: computePixelCropArea(
            normalizedRegion: normalizedRegion,
            pixelPadding: computePixelPadding(padding: cropPadding)
        ))
    }

    func computePixelPadding(
        padding: CGFloat
    ) -> CGFloat {
        return padding * CGFloat(max(width, height))
    }

    func computePixelCropArea(
        normalizedRegion: CGRect,
        pixelPadding: CGFloat
    ) -> CGRect {
        let pixelRegionOfInterest = CGRect(
            x: normalizedRegion.minX * CGFloat(width),
            y: normalizedRegion.minY * CGFloat(height),
            width: normalizedRegion.width * CGFloat(width),
            height: normalizedRegion.height * CGFloat(height)
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
    ) -> CGImage? {
        let scale = computeScale(maxPixelDimension: maxPixelDimension)
        return UIImage(cgImage: self).resized(to: scale)?.cgImage
    }

    func computeScale(
        maxPixelDimension: CGSize
    ) -> CGFloat {
        let horizontalScale = min(maxPixelDimension.width, CGFloat(width)) / CGFloat(width)
        let verticalScale = min(maxPixelDimension.height, CGFloat(height)) / CGFloat(height)
        return min(horizontalScale, verticalScale)
    }
}

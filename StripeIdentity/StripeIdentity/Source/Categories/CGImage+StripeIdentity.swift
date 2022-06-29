//
//  CGImage+StripeIdentity.swift
//  StripeCameraCore
//
//  Created by Mel Ludowise on 12/8/21.
//

import CoreGraphics
import UIKit
@_spi(STP) import StripeCore

enum STPCGImageError: String, Error {
    /// The image could not be cropped
    case unableToCrop
    /// The image could not be scaled down
    case unableToScaleDown
}

extension CGImage {

    enum CropPaddingComputationMethod {
        /// The pixel crop padding is a function of the maximum width or height of the image
        case maxImageWidthOrHeight
        /// The pixel crop padding is a function of the width of the region of interest
        case regionWidth
    }

    /**
     Crops the image to a given region of interest plus padding.

     - Parameters:
       - normalizedRegion: A rect, in image coordinates, defining the area to add padding to and then crop, where origin is bottom-left.
       - cropPadding: A value, ranging between 0–1, that is added as padding to the region of interest.
       - computationMethod: The method which the crop padding pixel value is computed from.

     - Returns: An image cropped to the given specifications.

     - Throws: STPCGImageError if the image could not be cropped

     - Note:
     The pixel value of the padding added to region of interest is defined as `cropPadding * max(width, height)`.
     */
    func cropping(
        toNormalizedRegion normalizedRegion: CGRect,
        withPadding cropPadding: CGFloat,
        computationMethod: CropPaddingComputationMethod
    ) throws -> CGImage {
        guard let image = cropping(to: computePixelCropArea(
            normalizedRegion: normalizedRegion,
            pixelPadding: computePixelPadding(
                padding: cropPadding,
                normalizedRegion: normalizedRegion,
                computationMethod: computationMethod
            )
        )) else {
            throw STPCGImageError.unableToCrop
        }
        return image
    }

    func computePixelPadding(
        padding: CGFloat,
        normalizedRegion: CGRect,
        computationMethod: CropPaddingComputationMethod
    ) -> CGFloat {
        switch computationMethod {
        case .maxImageWidthOrHeight:
            return padding * CGFloat(max(width, height))
        case .regionWidth:
            return padding * normalizedRegion.width * CGFloat(width)
        }
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

     - Throws: STPCGImageError if the image could not be scaled
     */
    func scaledDown(
        toMaxPixelDimension maxPixelDimension: CGSize
    ) throws -> CGImage {
        let scale = computeScale(maxPixelDimension: maxPixelDimension)
        guard let image = UIImage(cgImage: self).resized(to: scale)?.cgImage else {
            throw STPCGImageError.unableToScaleDown
        }
        return image
    }

    func computeScale(
        maxPixelDimension: CGSize
    ) -> CGFloat {
        let horizontalScale = min(maxPixelDimension.width, CGFloat(width)) / CGFloat(width)
        let verticalScale = min(maxPixelDimension.height, CGFloat(height)) / CGFloat(height)
        return min(horizontalScale, verticalScale)
    }
}

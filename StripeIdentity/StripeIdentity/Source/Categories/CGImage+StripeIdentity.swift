//
//  CGImage+StripeIdentity.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 12/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import CoreGraphics
@_spi(InternalOnlyAPI) import StripeCore
import UIKit

enum STPCGImageError: String, Error {
    /// The image could not be cropped
    case unableToCrop
    /// The image could not be scaled down
    case unableToScaleDown
}

extension CGImage {

    enum CropPaddingComputationMethod: Equatable {
        /// The pixel crop padding is a function of the maximum width or height of the image
        case maxImageWidthOrHeight
        /// The pixel crop padding is a function of the width of the region of interest
        case regionWidth
        /// Add a fraction of face width on every edge, plus fractions of face height above and below.
        case faceLandmarks(side: CGFloat, top: CGFloat, bottom: CGFloat)
    }

    /// Crops the image to a given region of interest plus padding.
    ///
    /// - Parameters:
    ///   - normalizedRegion: A normalized rect with its origin at the top left of the image.
    ///   - cropPadding: The padding fraction for the uniform padding methods.
    ///   - computationMethod: The method which the crop padding pixel value is computed from.
    ///
    /// - Returns: An image cropped to the given specifications.
    ///
    /// - Throws: STPCGImageError if the image could not be cropped
    func cropping(
        toNormalizedRegion normalizedRegion: CGRect,
        withPadding cropPadding: CGFloat,
        computationMethod: CropPaddingComputationMethod
    ) throws -> CGImage {
        let pixelPadding = computePixelPadding(
            padding: cropPadding,
            normalizedRegion: normalizedRegion,
            computationMethod: computationMethod
        )
        var cropArea = computePixelCropArea(normalizedRegion: normalizedRegion, pixelPadding: pixelPadding)
        if case .faceLandmarks(_, let top, let bottom) = computationMethod {
            let faceHeight = normalizedRegion.height * CGFloat(height)
            cropArea.origin.y -= top * faceHeight
            cropArea.size.height += top * faceHeight + bottom * faceHeight
        }
        // CGImage clips the final pixel rectangle to the source image.
        guard let image = cropping(to: cropArea) else {
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
        case .faceLandmarks(let side, _, _):
            return side * normalizedRegion.width * CGFloat(width)
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

    /// Scales the image, maintaining its aspect ratio, to a maximum dimension.
    /// If the image size is already smaller than the given dimension, it will
    /// maintain its original dimension.
    ///
    /// - Parameter maxPixelDimension: The maximum dimensions, in pixels, the returned image should be.
    ///
    /// - Returns: An image scaled down to the max dimensions.
    ///
    /// - Throws: STPCGImageError if the image could not be scaled
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

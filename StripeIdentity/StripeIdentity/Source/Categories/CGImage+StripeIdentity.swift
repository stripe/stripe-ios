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
        /// Expands the face box by fixed factors, then adds a fraction of its width on every edge,
        /// plus fractions of its height above and below.
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
        let cropArea: CGRect
        if case .faceLandmarks(let side, let top, let bottom) = computationMethod {
            let area = computeFaceLandmarksCropArea(
                normalizedFaceRegion: normalizedRegion,
                sidePadding: side,
                topPadding: top,
                bottomPadding: bottom
            )
            let minX = area.minX.rounded()
            let minY = area.minY.rounded()
            cropArea = CGRect(
                x: minX,
                y: minY,
                width: area.maxX.rounded() - minX,
                height: area.maxY.rounded() - minY
            )
            guard !cropArea.isEmpty,
                CGRect(x: 0, y: 0, width: width, height: height).contains(cropArea)
            else {
                throw STPCGImageError.unableToCrop
            }
        } else {
            let pixelPadding = computePixelPadding(
                padding: cropPadding,
                normalizedRegion: normalizedRegion,
                computationMethod: computationMethod
            )
            // CGImage clips the final pixel rectangle to the source image.
            cropArea = computePixelCropArea(normalizedRegion: normalizedRegion, pixelPadding: pixelPadding)
        }
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
        case .faceLandmarks:
            stpAssertionFailure("Face landmark crops use computeFaceLandmarksCropArea")
            return 0
        }
    }

    /// Returns web's MediaPipe selfie crop, in unrounded pixels, without leaving the image.
    func computeFaceLandmarksCropArea(
        normalizedFaceRegion face: CGRect,
        sidePadding: CGFloat,
        topPadding: CGFloat,
        bottomPadding: CGFloat
    ) -> CGRect {
        let frameWidth = CGFloat(width)
        let frameHeight = CGFloat(height)

        // Web scales the pixel coordinates of the face box's edges, not its size.
        let expandedLeft = face.minX * frameWidth * 0.98
        let expandedTop = face.minY * frameHeight * 0.80
        let expandedRight = min(face.maxX * frameWidth * 1.02, frameWidth)
        let expandedBottom = min(face.maxY * frameHeight * 1.025, frameHeight)
        let expandedWidth = expandedRight - expandedLeft
        let expandedHeight = expandedBottom - expandedTop

        let widthBasedPadding = expandedWidth * sidePadding
        // Web clamps the origin before sizing the crop, so an edge clamp moves
        // the crop toward the image center instead of shrinking it.
        let cropLeft = max(0, expandedLeft - widthBasedPadding)
        let topAfterHeightPadding = max(0, expandedTop - expandedHeight * topPadding)
        let cropTop = max(0, topAfterHeightPadding - widthBasedPadding)
        let heightWithVerticalPadding = min(
            expandedHeight + expandedHeight * (topPadding + bottomPadding),
            frameHeight
        )
        return CGRect(
            x: cropLeft,
            y: cropTop,
            width: min(expandedWidth + 2 * widthBasedPadding, frameWidth - cropLeft),
            height: min(heightWithVerticalPadding + 2 * widthBasedPadding, frameHeight - cropTop)
        )
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

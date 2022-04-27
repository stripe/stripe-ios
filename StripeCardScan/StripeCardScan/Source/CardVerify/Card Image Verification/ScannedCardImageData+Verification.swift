//
//  VerificationScannedCardImageData.swift
//  StripeCardScan
//
//  Created by Jaime Park on 11/21/21.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

/// Image configurations used for verification flow
internal struct ImageConfig {
    let jpegCompressionQuality: CGFloat = 0.8
    var jpegMaxBytes: Int = 1 * 1_000_000
    let maxWidth = 1080
    let maxHeight = 1920
}

/// Methods used to transform a scanned card image data into `VerificationFramesData`
extension ScannedCardImageData {
    /// Returns a `VerificationFramesData` object from the scanned image data
    func toVerificationFramesData(imageConfig: ImageConfig = ImageConfig()) -> VerificationFramesData {
        let encodedImage = toExpectedImageFormat(image: previewLayerImage, imageConfig: imageConfig)
        let imageData = encodedImage.imageData
        let size = encodedImage.encodedImageSize
        
        // make sure to adjust the size of our viewFinderRect if jpeg conversion resized the image
        let scaleX = size.width / CGFloat(previewLayerImage.width)
        let scaleY = size.height / CGFloat(previewLayerImage.height)
        let viewfinderMargins = toViewfinderMargins(viewfinderRect: previewLayerViewfinderRect, scaleX: scaleX, scaleY: scaleY)

        return VerificationFramesData(imageData: imageData, viewfinderMargins: viewfinderMargins)
    }

    /// Converts a CGImage into a base64 encoded string of a jpeg image
    private func toExpectedImageFormat(image: CGImage, imageConfig: ImageConfig) -> (imageData: Data, encodedImageSize: CGSize) {
        /// Convert CGImage to UIImage
        let convertedUIImage = UIImage(cgImage: image)

        ///TODO(jaimepark): Resize with aspect ratio maintained if image is bigger than 1080 x 1920

        /// Convert UIImage to JPEG
        let compressedImage = convertedUIImage.jpegDataAndDimensions(
            maxBytes: imageConfig.jpegMaxBytes,
            compressionQuality: imageConfig.jpegCompressionQuality
        )

        return (imageData: compressedImage.imageData, encodedImageSize: compressedImage.imageSize)
    }

    /// Converts the view finder CGRect into a ViewFinderMargins object
    private func toViewfinderMargins(
        viewfinderRect: CGRect,
        scaleX: CGFloat,
        scaleY: CGFloat
    ) -> ViewFinderMargins {
        let left: Int = Int(viewfinderRect.origin.x * scaleX)
        let right: Int = Int((viewfinderRect.width + viewfinderRect.origin.x) * scaleX)
        let upper: Int = Int(viewfinderRect.origin.y * scaleY)
        let lower: Int = Int((viewfinderRect.height + viewfinderRect.origin.y) * scaleY)

        return ViewFinderMargins(left: left, upper: upper, right: right, lower: lower)
    }
}

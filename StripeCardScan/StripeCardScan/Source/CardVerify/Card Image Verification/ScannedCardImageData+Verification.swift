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
typealias ImageConfig = CardImageVerificationAcceptedImageConfigs

/// Methods used to transform a scanned card image data into `VerificationFramesData`
extension ScannedCardImageData {
    /// Returns a `VerificationFramesData` object from the scanned image data
    func toVerificationFramesData(imageConfig: ImageConfig?) -> VerificationFramesData {
        let config = imageConfig ?? ImageConfig()
        let encodedImage = toExpectedImageFormat(image: previewLayerImage, imageConfig: config)
        let imageData = encodedImage?.imageData
        let size = encodedImage?.imageSize ?? .zero
        
        // make sure to adjust the size of our viewFinderRect if jpeg conversion resized the image
        let scaleX = size.width / CGFloat(previewLayerImage.width)
        let scaleY = size.height / CGFloat(previewLayerImage.height)
        let viewfinderMargins = toViewfinderMargins(viewfinderRect: previewLayerViewfinderRect, scaleX: scaleX, scaleY: scaleY)

        return VerificationFramesData(imageData: imageData, viewfinderMargins: viewfinderMargins)
    }

    /// Converts a CGImage into a base64 encoded string of a jpeg image
    private func toExpectedImageFormat(image: CGImage, imageConfig: ImageConfig) -> (imageData: Data, imageSize: CGSize)? {
        /// Convert CGImage to UIImage
        let uiImage = UIImage(cgImage: image)

        ///TODO(jaimepark): Resize with aspect ratio maintained if image is bigger than 1080 x 1920

        for format in imageConfig.preferredFormats ?? [] {
            if !isImageFormatSupported(format: format) {
                continue
            }

            let result = compressedImageForFormat(image: uiImage, format: format, imageConfig: imageConfig)
            if let compressedImage = result, compressedImage.imageData.count > 0 {
                return result
            }
        }

        return compressedImageForFormat(image: uiImage, format: .jpeg, imageConfig: imageConfig)
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

    private func isImageFormatSupported(format: CardImageVerificationFormat) -> Bool {
        format == .heic || format == .jpeg
    }

    private func compressedImageForFormat(image: UIImage, format: CardImageVerificationFormat, imageConfig: ImageConfig) -> (imageData: Data, imageSize: CGSize)? {
        var result: (imageData: Data, imageSize: CGSize)? = nil
        let imageSettings = imageConfig.imageSettings(format: format)
        let compressionRatio = imageSettings.compressionRatio ?? 1

        switch format {
        case .heic:
            result = image.heicDataAndDimensions(compressionQuality: compressionRatio)
        case .webp, .unparsable:
            fallthrough
        case .jpeg:
            result = image.jpegDataAndDimensions(compressionQuality: compressionRatio)
        }

        return result
    }
}

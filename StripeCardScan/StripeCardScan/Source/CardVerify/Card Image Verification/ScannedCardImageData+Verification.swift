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
private struct ImageConfig {
    static let jpegCompressionQuality: CGFloat = 0.8
    static let jpegScale: CGFloat = 1.0
    static let jpegMaxBytes: Int = 1 * 1_000_000
    static let maxWidth = 1080
    static let maxHeight = 1920
}

/// Methods used to transform a scanned card image data into `VerificationFramesData`
extension ScannedCardImageData {
    /// Returns a `VerificationFramesData` object from the scanned image data
    func toVerificationFramesData() -> VerificationFramesData {
        let b64ImageData = toBase64EncodedImageData(image: previewLayerImage)
        let viewfinderMargins = toViewfinderMargins(viewfinderRect: previewLayerViewfinderRect)

        return VerificationFramesData(imageData: b64ImageData, viewfinderMargins: viewfinderMargins)
    }

    /// Converts a CGImage into a base64 encoded string of a jpeg image
    private func toBase64EncodedImageData(image: CGImage) -> String {
        /// Convert CGImage to UIImage
        let convertedUIImage = UIImage(cgImage: image)

        ///TODO(jaimepark): Resize with aspect ratio maintained if image is bigger than 1080 x 1920

        /// Convert UIImage to JPEG
        let jpegImage = convertedUIImage.jpegData(
            maxBytes: ImageConfig.jpegMaxBytes,
            scale: ImageConfig.jpegScale,
            compressionQuality: ImageConfig.jpegCompressionQuality
        )

        return jpegImage.base64EncodedString()
    }

    /// Converts the view finder CGRect into a ViewFinderMargins object
    private func toViewfinderMargins(
        viewfinderRect: CGRect
    ) -> ViewFinderMargins {
        let left: Int = Int(viewfinderRect.origin.x)
        let right: Int = Int(viewfinderRect.width + viewfinderRect.origin.x)
        let upper: Int = Int(viewfinderRect.origin.y)
        let lower: Int = Int(viewfinderRect.height + viewfinderRect.origin.y)

        return ViewFinderMargins(left: left, upper: upper, right: right, lower: lower)
    }
}

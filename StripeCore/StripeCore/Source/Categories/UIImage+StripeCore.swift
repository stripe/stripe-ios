//
//  UIImage+StripeCore.swift
//  StripeCore
//
//  Created by Brian Dorfman on 4/25/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//
import AVFoundation
import UIKit

@_spi(STP) public typealias ImageDataAndSize = (imageData: Data, imageSize: CGSize)

extension UIImage {
    @_spi(STP) public static let defaultCompressionQuality: CGFloat = 0.5

    /// Encodes the image to jpeg at the specified compression quality.
    ///
    /// The image will be scaled down, if needed, to ensure its size does not exceed `maxBytes`.
    ///
    /// - Parameters:
    ///   - maxBytes: The maximum size of the allowed file. If value is nil, then
    ///     the image will not be scaled down.
    ///   - compressionQuality: The compression quality to use when encoding the jpeg.
    /// - Returns: A tuple containing the following properties.
    ///   - `imageData`: Data object of the jpeg encoded image.
    ///   - `imageSize`: The dimensions of the the image that was encoded.
    ///      This size may be smaller than the original image size if the image
    ///      needed to be scaled down to fit the specified `maxBytes`.
    @_spi(STP) public func jpegDataAndDimensions(
        maxBytes: Int? = nil,
        compressionQuality: CGFloat = defaultCompressionQuality
    ) -> ImageDataAndSize {
        dataAndDimensions(
            maxBytes: maxBytes,
            compressionQuality: compressionQuality
        ) { image, quality in
            image.jpegData(compressionQuality: quality)
        }
    }

    /// Encodes the image to heic at the specified compression quality.
    ///
    /// The image will be scaled down, if needed, to ensure its size does not exceed `maxBytes`.
    ///
    /// - Parameters:
    ///   - maxBytes: The maximum size of the allowed file. If value is nil, then
    ///     the image will not be scaled down.
    ///   - compressionQuality: The compression quality to use when encoding the jpeg.
    /// - Returns: A tuple containing the following properties.
    ///   - `imageData`: Data object of the jpeg encoded image.
    ///   - `imageSize`: The dimensions of the the image that was encoded.
    ///      This size may be smaller than the original image size if the image
    ///      needed to be scaled down to fit the specified `maxBytes`.
    @_spi(STP) public func heicDataAndDimensions(
        maxBytes: Int? = nil,
        compressionQuality: CGFloat = defaultCompressionQuality
    ) -> ImageDataAndSize {
        dataAndDimensions(
            maxBytes: maxBytes,
            compressionQuality: compressionQuality
        ) { image, quality in
            image.heicData(compressionQuality: quality)
        }
    }

    @_spi(STP) public func resized(to scale: CGFloat) -> UIImage? {
        let newImageSize = CGSize(
            width: CGFloat(floor(size.width * scale)),
            height: CGFloat(floor(size.height * scale))
        )
        UIGraphicsBeginImageContextWithOptions(newImageSize, false, self.scale)

        defer {
            UIGraphicsEndImageContext()
        }

        draw(in: CGRect(x: 0, y: 0, width: newImageSize.width, height: newImageSize.height))
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    private func heicData(compressionQuality: CGFloat = UIImage.defaultCompressionQuality) -> Data?
    {
        [self].heicData(compressionQuality: compressionQuality)
    }

    private func dataAndDimensions(
        maxBytes: Int? = nil,
        compressionQuality: CGFloat = defaultCompressionQuality,
        imageDataProvider: ((_ image: UIImage, _ quality: CGFloat) -> Data?)
    ) -> ImageDataAndSize {
        var imageData = imageDataProvider(self, compressionQuality)

        guard imageData != nil else {
            return (imageData: Data(), imageSize: .zero)
        }

        var newImageSize = self.size

        // Try something smarter first
        if let maxBytes = maxBytes,
            (imageData?.count ?? 0) > maxBytes
        {
            var scale = CGFloat(1.0)

            // Assuming jpeg file size roughly scales linearly with area of the image
            // which is ~correct (although breaks down at really small file sizes)
            let percentSmallerNeeded = CGFloat(maxBytes) / CGFloat((imageData?.count ?? 0))

            // Shrink to a little bit less than we need to try to ensure we're under
            // (otherwise its likely our first pass will be over the limit due to
            // compression variance and floating point rounding)
            scale = scale * (percentSmallerNeeded - (percentSmallerNeeded * 0.05))

            repeat {
                if let newImage = resized(to: scale) {
                    newImageSize = newImage.size
                    imageData = imageDataProvider(newImage, compressionQuality)
                }

                // If the smart thing doesn't work, just start scaling down a bit on a loop until we get there
                scale *= 0.7
            } while (imageData?.count ?? 0) > maxBytes
        }

        return (imageData: imageData!, imageSize: newImageSize)
    }
}

extension Array where Element: UIImage {
    @_spi(STP) public func heicData(
        compressionQuality: CGFloat = UIImage.defaultCompressionQuality
    ) -> Data? {
        guard let mutableData = CFDataCreateMutable(nil, 0) else {
            return nil
        }

        guard
            let destination = CGImageDestinationCreateWithData(
                mutableData,
                AVFileType.heic as CFString,
                self.count,
                nil
            )
        else {
            return nil
        }

        let properties =
            [kCGImageDestinationLossyCompressionQuality: compressionQuality] as CFDictionary

        for image in self {
            let cgImage = image.cgImage!
            CGImageDestinationAddImage(destination, cgImage, properties)
        }

        if CGImageDestinationFinalize(destination) {
            return mutableData as Data
        }

        return nil
    }
}

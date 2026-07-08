//
//  UIImage+StripeCore.swift
//  StripeCore
//
//  Created by Brian Dorfman on 4/25/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//
import AVFoundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

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
            #if canImport(UIKit)
            image.jpegData(compressionQuality: quality)
            #elseif canImport(AppKit)
            image.stp_encodedData(type: AVFileType.jpg as CFString, compressionQuality: quality)
            #endif
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

    @_spi(STP) public func resized(to size: CGSize) -> UIImage? {
        #if canImport(UIKit)
        let renderingMode = renderingMode
        UIGraphicsBeginImageContextWithOptions(size, false, self.scale)
        defer {
            UIGraphicsEndImageContext()
        }
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        return resizedImage?.withRenderingMode(renderingMode)
        #elseif canImport(AppKit)
        let image = NSImage(size: size)
        image.lockFocus()
        defer { image.unlockFocus() }
        draw(in: CGRect(origin: .zero, size: size))
        return image
        #endif
    }

    @_spi(STP) public func resized(to scale: CGFloat) -> UIImage? {
        let newImageSize = CGSize(
            width: CGFloat(floor(size.width * scale)),
            height: CGFloat(floor(size.height * scale))
        )
        #if canImport(UIKit)
        UIGraphicsBeginImageContextWithOptions(newImageSize, false, self.scale)

        defer {
            UIGraphicsEndImageContext()
        }

        draw(in: CGRect(x: 0, y: 0, width: newImageSize.width, height: newImageSize.height))
        return UIGraphicsGetImageFromCurrentImageContext()
        #elseif canImport(AppKit)
        return resized(to: newImageSize)
        #endif
    }

    // Returns a CGSize for the view that is scaled according to the size of the given font.
    // For example, a font with a higher or lower pointSize or using dynamic type will result in a
    //      proportionally larger or smaller image size
    // `additionalScale` determines the ratio between the returned height and the font height
    @_spi(STP) public func sizeMatchingFont(_ font: UIFont, additionalScale: CGFloat) -> CGSize {
        let fontScale = font.capHeight / size.height
        let totalScale = fontScale * additionalScale
        return CGSize(width: size.width * totalScale, height: size.height * totalScale)
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
            #if canImport(UIKit)
            let cgImage = image.cgImage!
            #elseif canImport(AppKit)
            guard let cgImage = image.stp_cgImage else {
                continue
            }
            #endif
            CGImageDestinationAddImage(destination, cgImage, properties)
        }

        if CGImageDestinationFinalize(destination) {
            return mutableData as Data
        }

        return nil
    }
}

#if canImport(AppKit)
extension NSImage {
    fileprivate var stp_cgImage: CGImage? {
        var proposedRect = CGRect(origin: .zero, size: size)
        return cgImage(forProposedRect: &proposedRect, context: nil, hints: nil)
    }

    fileprivate func stp_encodedData(
        type: CFString,
        compressionQuality: CGFloat
    ) -> Data? {
        guard let cgImage = stp_cgImage,
            let mutableData = CFDataCreateMutable(nil, 0),
            let destination = CGImageDestinationCreateWithData(mutableData, type, 1, nil)
        else {
            return nil
        }
        let properties = [
            kCGImageDestinationLossyCompressionQuality: compressionQuality,
        ] as CFDictionary
        CGImageDestinationAddImage(destination, cgImage, properties)
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        return mutableData as Data
    }
}
#endif

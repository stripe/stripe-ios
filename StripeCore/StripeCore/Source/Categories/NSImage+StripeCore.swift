//
//  NSImage+StripeCore.swift
//  StripeCore
//
//  Created by Stripe SDK for macOS AppKit support.
//  Copyright © 2024 Stripe, Inc. All rights reserved.
//

#if canImport(AppKit) && os(macOS)
import AppKit
import AVFoundation

@_spi(STP) public typealias ImageDataAndSize = (imageData: Data, imageSize: CGSize)

extension NSImage {
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

    @_spi(STP) public func resized(to scale: CGFloat) -> NSImage? {
        let newImageSize = CGSize(
            width: CGFloat(floor(size.width * scale)),
            height: CGFloat(floor(size.height * scale))
        )
        
        guard let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(newImageSize.width),
            pixelsHigh: Int(newImageSize.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .calibratedRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            return nil
        }
        
        bitmapRep.size = newImageSize
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
        draw(in: NSRect(origin: .zero, size: newImageSize))
        NSGraphicsContext.restoreGraphicsState()
        
        let newImage = NSImage(size: newImageSize)
        newImage.addRepresentation(bitmapRep)
        return newImage
    }

    private func jpegData(compressionQuality: CGFloat = NSImage.defaultCompressionQuality) -> Data? {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        return bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
    }

    private func heicData(compressionQuality: CGFloat = NSImage.defaultCompressionQuality) -> Data? {
        [self].heicData(compressionQuality: compressionQuality)
    }

    private func dataAndDimensions(
        maxBytes: Int? = nil,
        compressionQuality: CGFloat = defaultCompressionQuality,
        imageDataProvider: ((_ image: NSImage, _ quality: CGFloat) -> Data?)
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

extension Array where Element: NSImage {
    @_spi(STP) public func heicData(
        compressionQuality: CGFloat = NSImage.defaultCompressionQuality
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
            guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                continue
            }
            CGImageDestinationAddImage(destination, cgImage, properties)
        }

        if CGImageDestinationFinalize(destination) {
            return mutableData as Data
        }

        return nil
    }
}

#endif 
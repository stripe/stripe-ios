// Copyright (c) 2017 M.I. Hollemans
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

// https://github.com/hollance/CoreMLHelpers

import UIKit
import VideoToolbox

extension UIImage {
    /// Resizes the image to width x height and converts it to an RGB CVPixelBuffer.
    func pixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        return pixelBuffer(
            width: width,
            height: height,
            pixelFormatType: kCVPixelFormatType_32ARGB,
            colorSpace: CGColorSpaceCreateDeviceRGB(),
            alphaInfo: .noneSkipFirst
        )
    }

    /// Resizes the image to width x height and converts it to a grayscale CVPixelBuffer.
    func pixelBufferGray(width: Int, height: Int) -> CVPixelBuffer? {
        return pixelBuffer(
            width: width,
            height: height,
            pixelFormatType: kCVPixelFormatType_OneComponent8,
            colorSpace: CGColorSpaceCreateDeviceGray(),
            alphaInfo: .none
        )
    }

    /// Convert to pixel buffer without resizing
    func pixelBufferGray() -> CVPixelBuffer? {
        return pixelBufferGray(width: Int(self.size.width), height: Int(self.size.height))
    }

    func pixelBuffer(
        width: Int,
        height: Int,
        pixelFormatType: OSType,
        colorSpace: CGColorSpace,
        alphaInfo: CGImageAlphaInfo
    ) -> CVPixelBuffer? {
        var maybePixelBuffer: CVPixelBuffer?
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue,
        ]
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            pixelFormatType,
            attrs as CFDictionary,
            &maybePixelBuffer
        )

        guard status == kCVReturnSuccess, let pixelBuffer = maybePixelBuffer else {
            return nil
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)

        guard
            let context = CGContext(
                data: pixelData,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                space: colorSpace,
                bitmapInfo: alphaInfo.rawValue
            )
        else {
            return nil
        }

        UIGraphicsPushContext(context)
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        UIGraphicsPopContext()

        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        return pixelBuffer
    }

    func areCornerPixelsBlack() -> Bool {
        let pixelBuffer = self.pixelBufferGray()!
        var result = true

        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.readOnly)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let pixels = CVPixelBufferGetBaseAddress(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        // let pixelBufferIndex = x + y * bytesPerRow
        var pixelValue = pixels?.load(fromByteOffset: 0, as: UInt8.self) ?? 0
        result = result && pixelValue == 0
        pixelValue = pixels?.load(fromByteOffset: (width - 1), as: UInt8.self) ?? 0
        result = result && pixelValue == 0
        pixelValue = pixels?.load(fromByteOffset: ((height - 1) * bytesPerRow), as: UInt8.self) ?? 0
        result = result && pixelValue == 0
        pixelValue =
            pixels?.load(fromByteOffset: ((width - 1) + (height - 1) * bytesPerRow), as: UInt8.self)
            ?? 0
        result = result && pixelValue == 0
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.readOnly)

        return result
    }
}

extension UIImage {
    /// Creates a new UIImage from a CVPixelBuffer.
    /// NOTE: This only works for RGB pixel buffers, not for grayscale.
    convenience init?(
        pixelBuffer: CVPixelBuffer
    ) {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)

        if let cgImage = cgImage {
            self.init(cgImage: cgImage)
        } else {
            return nil
        }
    }

    /// Creates a new UIImage from a CVPixelBuffer, using Core Image.
    convenience init?(
        pixelBuffer: CVPixelBuffer,
        context: CIContext
    ) {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let rect = CGRect(
            x: 0,
            y: 0,
            width: CVPixelBufferGetWidth(pixelBuffer),
            height: CVPixelBufferGetHeight(pixelBuffer)
        )
        if let cgImage = context.createCGImage(ciImage, from: rect) {
            self.init(cgImage: cgImage)
        } else {
            return nil
        }
    }
}

extension UIImage {
    /// Creates a new UIImage from an array of RGBA bytes.
    @nonobjc class func fromByteArrayRGBA(
        _ bytes: [UInt8],
        width: Int,
        height: Int,
        scale: CGFloat = 0,
        orientation: UIImage.Orientation = .up
    ) -> UIImage? {
        return fromByteArray(
            bytes,
            width: width,
            height: height,
            scale: scale,
            orientation: orientation,
            bytesPerRow: width * 4,
            colorSpace: CGColorSpaceCreateDeviceRGB(),
            alphaInfo: .premultipliedLast
        )
    }

    /// Creates a new UIImage from an array of grayscale bytes.
    @nonobjc class func fromByteArrayGray(
        _ bytes: [UInt8],
        width: Int,
        height: Int,
        scale: CGFloat = 0,
        orientation: UIImage.Orientation = .up
    ) -> UIImage? {
        return fromByteArray(
            bytes,
            width: width,
            height: height,
            scale: scale,
            orientation: orientation,
            bytesPerRow: width,
            colorSpace: CGColorSpaceCreateDeviceGray(),
            alphaInfo: .none
        )
    }

    @nonobjc class func fromByteArray(
        _ bytes: [UInt8],
        width: Int,
        height: Int,
        scale: CGFloat,
        orientation: UIImage.Orientation,
        bytesPerRow: Int,
        colorSpace: CGColorSpace,
        alphaInfo: CGImageAlphaInfo
    ) -> UIImage? {
        var image: UIImage?
        bytes.withUnsafeBytes { ptr in
            if let context = CGContext(
                data: UnsafeMutableRawPointer(mutating: ptr.baseAddress!),
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: alphaInfo.rawValue
            ),
                let cgImage = context.makeImage()
            {
                image = UIImage(cgImage: cgImage, scale: scale, orientation: orientation)
            }
        }
        return image
    }
}

extension UIImage {
    static func blankGrayImage(width: Int, height: Int) -> UIImage? {
        UIGraphicsBeginImageContext(CGSize(width: width, height: height))
        UIColor.gray.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: width, height: height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}

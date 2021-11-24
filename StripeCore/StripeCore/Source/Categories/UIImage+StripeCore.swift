//
//  UIImage+StripeCore.swift
//  StripeCore
//
//  Created by Brian Dorfman on 4/25/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import UIKit

extension UIImage {
    @objc(stp_jpegDataWithMaxFileSize:) func stp_jpegData(withMaxFileSize maxBytes: Int) -> Data {
        return jpegData(
            maxBytes: maxBytes,
            scale: 1.0,
            compressionQuality: 0.5
        )
    }

    @_spi(STP) public func jpegData(
        maxBytes: Int,
        scale: CGFloat,
        compressionQuality: CGFloat
    ) -> Data {
        let shrinkingScaleFactor: CGFloat = 0.05
        let fallbackCompressionQuality: CGFloat = 0.7

        var scale = scale
        var imageData = self.jpegData(compressionQuality: compressionQuality)

        // Try something smarter first
        if (imageData?.count ?? 0) > maxBytes {
            // Assuming jpeg file size roughly scales linearly with area of the image
            // which is ~correct (although breaks down at really small file sizes)
            let percentSmallerNeeded = CGFloat(maxBytes) / CGFloat((imageData?.count ?? 0))

            // Shrink to a little bit less than we need to try to ensure we're under
            // (otherwise its likely our first pass will be over the limit due to
            // compression variance and floating point rounding)
            scale = scale * (percentSmallerNeeded - (percentSmallerNeeded * shrinkingScaleFactor))

            repeat {
                let newImageSize = CGSize(
                    width: CGFloat(floor(size.width * scale)),
                    height: CGFloat(floor(size.height * scale)))
                UIGraphicsBeginImageContextWithOptions(newImageSize, false, self.scale)
                draw(in: CGRect(x: 0, y: 0, width: newImageSize.width, height: newImageSize.height))
                let newImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                imageData = newImage?.jpegData(compressionQuality: compressionQuality)

                // If the smart thing doesn't work, just start scaling down a bit on a loop until we get there
                scale = scale * CGFloat(fallbackCompressionQuality)
            } while (imageData?.count ?? 0) > maxBytes
        }
        return imageData!
    }
}

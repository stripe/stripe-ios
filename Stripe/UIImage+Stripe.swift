//
//  UIImage+Stripe.swift
//  Stripe
//
//  Created by Brian Dorfman on 4/25/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import UIKit

extension UIImage {
  @objc(stp_jpegDataWithMaxFileSize:) func stp_jpegData(withMaxFileSize maxBytes: Int) -> Data {
    var scale: CGFloat = 1.0
    var imageData = self.jpegData(compressionQuality: 0.5)

    // Try something smarter first
    if (imageData?.count ?? 0) > maxBytes {
      // Assuming jpeg file size roughly scales linearly with area of the image
      // which is ~correct (although breaks down at really small file sizes)
      let percentSmallerNeeded = CGFloat(maxBytes) / CGFloat((imageData?.count ?? 0))

      // Shrink to a little bit less than we need to try to ensure we're under
      // (otherwise its likely our first pass will be over the limit due to
      // compression variance and floating point rounding)
      scale = scale * (percentSmallerNeeded - (percentSmallerNeeded * 0.05))

      repeat {
        let newImageSize = CGSize(
          width: CGFloat(floor(size.width * scale)),
          height: CGFloat(floor(size.height * scale)))
        UIGraphicsBeginImageContextWithOptions(newImageSize, false, self.scale)
        draw(in: CGRect(x: 0, y: 0, width: newImageSize.width, height: newImageSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        imageData = newImage?.jpegData(compressionQuality: 0.5)

        // If the smart thing doesn't work, just start scaling down a bit on a loop until we get there
        scale = scale * CGFloat(0.7)
      } while (imageData?.count ?? 0) > maxBytes
    }
    return imageData!
  }
}

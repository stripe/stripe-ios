//
//  UIImage+utils.swift
//  StripeIdentity
//
//  Created by Chen Cen on 2/28/24.
//

import Foundation
import UIKit

extension UIImage {
    /// Remove the imageOrientation property and redraw the image in portrait
    func unrotate() -> UIImage? {
        let size = self.size
        UIGraphicsBeginImageContext(size)
        self.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}

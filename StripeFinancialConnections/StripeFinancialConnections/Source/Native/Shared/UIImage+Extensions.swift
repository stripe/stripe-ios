//
//  UIImage+Extensions.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 11/17/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {

    // create a new image with transparent insets around it
    func withInsets(_ insets: UIEdgeInsets) -> UIImage? {
        let newSize = CGSize(
            width: size.width + insets.left * scale + insets.right * scale,
            height: size.height + insets.top * scale + insets.bottom * scale
        )
        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        let origin = CGPoint(x: insets.left * scale, y: insets.top * scale)
        self.draw(at: origin)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()?.withRenderingMode(renderingMode)
        UIGraphicsEndImageContext()
        return newImage
    }
}

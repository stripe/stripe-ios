//
//  UIImage+Stripe.swift
//  Stripe
//
//  Created by Brian Dorfman on 4/25/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import UIKit

extension UIImage {
    // An version of `withTintColor` that works for < iOS 13.0
    func compatible_withTintColor(_ color: UIColor) -> UIImage? {
        if #available(iOS 13.0, *) {
            return withTintColor(color)
        }
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)

        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        draw(in: rect)
        color.setFill()
        UIRectFillUsingBlendMode(rect, .sourceAtop)

        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return tintedImage
    }
}

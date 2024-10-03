//
//  STPImageLibrary.swift
//  StripeiOS
//
//  Created by Jack Flintermann on 6/30/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

/// This class lets you access card icons used by the Stripe SDK. All icons are 32 x 20 points.
@objc class STPLegacyImageLibrary: NSObject {

    /// An icon representing FPX.
    @objc
    public class func fpxLogo() -> UIImage {
        return self.safeImageNamed("stp_fpx_logo", templateIfAvailable: false)
    }

    /// A large branding image for FPX.
    @objc
    public class func largeFpxLogo() -> UIImage {
        return self.safeImageNamed("stp_fpx_big_logo", templateIfAvailable: false)
    }

    class func image(
        withTintColor color: UIColor,
        for image: UIImage
    ) -> UIImage {
        var newImage: UIImage?
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        color.set()
        let templateImage = image.withRenderingMode(.alwaysTemplate)
        templateImage.draw(
            in: CGRect(
                x: 0,
                y: 0,
                width: templateImage.size.width,
                height: templateImage.size.height
            )
        )
        newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? image
    }
}

// MARK: - ImageMaker

// :nodoc:
@_spi(STP) extension STPLegacyImageLibrary: ImageMaker {
    @_spi(STP) public typealias BundleLocator = StripeBundleLocator
}

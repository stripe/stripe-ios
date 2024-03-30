//
//  ImageMaker.swift
//  StripeUICore
//
//  Created by Mel Ludowise on 9/10/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

@_spi(STP) import StripeCore

@_spi(STP) public protocol ImageMaker {
    associatedtype BundleLocator: BundleLocatorProtocol
}

@_spi(STP) public extension ImageMaker {
    private static func imageNamed(
      _ imageName: String,
      templateIfAvailable: Bool,
      compatibleWith traitCollection: UITraitCollection? = nil
    ) -> UIImage? {

      var image = UIImage(
        named: imageName, in: BundleLocator.resourcesBundle, compatibleWith: traitCollection)

      if image == nil {
          image = UIImage(named: imageName, in: nil, compatibleWith: traitCollection)
      }

      if templateIfAvailable {
        image = image?.withRenderingMode(.alwaysTemplate)
      }

      return image
    }

    static func safeImageNamed(
        _ imageName: String,
        templateIfAvailable: Bool = false,
        overrideUserInterfaceStyle: UIUserInterfaceStyle? = nil
    ) -> UIImage {
        let image: UIImage
        if let overrideUserInterfaceStyle = overrideUserInterfaceStyle {
            let appearanceTrait = UITraitCollection(userInterfaceStyle: overrideUserInterfaceStyle)
            image = imageNamed(imageName, templateIfAvailable: templateIfAvailable, compatibleWith: appearanceTrait) ?? UIImage()
        } else {
            image = imageNamed(imageName, templateIfAvailable: templateIfAvailable) ?? UIImage()
        }
        assert(image.size != .zero, "Failed to find an image named \(imageName)")
        return image
    }
}

@_spi(STP) public extension ImageMaker where Self: RawRepresentable, RawValue == String {
    func makeImage(template: Bool = false, overrideUserInterfaceStyle: UIUserInterfaceStyle? = nil) -> UIImage {
        return Self.safeImageNamed(
            self.rawValue,
            templateIfAvailable: template,
            overrideUserInterfaceStyle: overrideUserInterfaceStyle
        )
    }
}

//
//  ImageMaker.swift
//  StripeUICore
//
//  Created by Mel Ludowise on 9/10/21.
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
      templateIfAvailable: Bool
    ) -> UIImage? {

      var image = UIImage(
        named: imageName, in: BundleLocator.resourcesBundle, compatibleWith: nil)

      if image == nil {
        image = UIImage(named: imageName)
      }

      if templateIfAvailable {
        image = image?.withRenderingMode(.alwaysTemplate)
      }

      return image
    }

    static func safeImageNamed(
        _ imageName: String,
        templateIfAvailable: Bool = false
    ) -> UIImage {

        let image = imageNamed(imageName, templateIfAvailable: templateIfAvailable) ?? UIImage()
        assert(image.size != .zero, "Failed to find an image named \(imageName)")
        // Vend a dark variant if available
        // Workaround until we can use image assets
        if isDarkMode(),
           let darkImage = imageNamed(imageName + "_dark", templateIfAvailable: templateIfAvailable) {
            return darkImage
        } else {
            return image
        }
    }
}

@_spi(STP) public extension ImageMaker where Self: RawRepresentable, RawValue == String {
    func makeImage(template: Bool = false) -> UIImage {
        return Self.safeImageNamed(
            self.rawValue,
            templateIfAvailable: template
        )
    }
}

@_spi(STP) public func isDarkMode() -> Bool {
    if #available(iOS 13.0, *) {
        return UITraitCollection.current.isDarkMode
    }
    return false
}

//
//  Image.swift
//  StripeConnections
//
//  Created by Vardges Avetisyan on 11/22/21.
//

import Foundation
@_spi(STP) import StripeUICore

/// The canonical set of all image files in the `StripeConnections` module.
/// This helps us avoid duplicates and automatically test that all images load properly
enum Image: String, ImageMaker {
    typealias BundleLocator = StripeConnectionsBundleLocator

    case back_arrow = "back_arrow"
    case close = "close"
}

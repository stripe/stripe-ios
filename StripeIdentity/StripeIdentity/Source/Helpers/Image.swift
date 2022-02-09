//
//  Image.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/8/21.
//

import Foundation
@_spi(STP) import StripeUICore

/// The canonical set of all image files in the `StripeIdentity` module.
/// This helps us avoid duplicates and automatically test that all images load properly
enum Image: String, ImageMaker {
    typealias BundleLocator = StripeIdentityBundleLocator

    case iconCheckmark = "icon_checkmark"
    case iconAdd = "icon_add"
}

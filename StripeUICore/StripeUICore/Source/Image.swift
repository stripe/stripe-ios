//
//  Image.swift
//  StripeUICore
//
//  Created by Mel Ludowise on 9/10/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/// The canonical set of all image files in the SDK.
/// This helps us avoid duplicates and automatically test that all images load properly
/// Raw value is the image file name. We use snake case to make long names easier to read.
@_spi(STP) public enum Image: String, ImageMaker, CaseIterable {
    public typealias BundleLocator = StripeUICoreBundleLocator

    // Icons/symbols
    case icon_chevron_down = "icon_chevron_down"
    case icon_clear = "icon_clear"

    // Brand Icons
    case brand_stripe = "brand_stripe"
    case icon_error = "form_error_icon"
}

@_spi(STP) public extension Image {
    static func brandImage(named name: String) -> Image? {
        return Image(rawValue: "brand_\(name)")
    }
}

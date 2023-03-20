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
enum Image: String, CaseIterable, ImageMaker {
    typealias BundleLocator = StripeIdentityBundleLocator

    case iconAdd = "icon_add"
    case iconCheckmark = "icon_checkmark"
    case iconCheckmark92 = "icon_checkmark_92"
    case iconClock = "icon_clock"
    case iconInfo = "icon_info"
    case iconWarning92 = "icon_warning_92"
}

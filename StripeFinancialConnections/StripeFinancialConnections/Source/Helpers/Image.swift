//
//  Image.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 11/22/21.
//

import Foundation
@_spi(STP) import StripeUICore

/// The canonical set of all image files in the `StripeFinancialConnections` module.
/// This helps us avoid duplicates and automatically test that all images load properly
enum Image: String, ImageMaker {
    typealias BundleLocator = StripeFinancialConnectionsBundleLocator

    case add
    case arrow_right
    case back_arrow
    case bank
    case bank_check
    case brandicon_default
    case cancel_circle
    case check
    case chevron_down
    case close
    case ellipsis
    case generic_error
    case prepane_phone_background
    case search
    case stripe_logo
    case spinner
    case warning_circle
    case warning_triangle
    case bullet
}

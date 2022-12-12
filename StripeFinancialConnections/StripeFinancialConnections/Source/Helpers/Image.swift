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

    case back_arrow = "back_arrow"
    case bank = "bank"
    case bank_check = "bank_check"
    case brandicon_default = "brandicon_default"
    case cancel_circle = "cancel_circle"
    case check = "check"
    case chevron_down = "chevron_down"
    case close = "close"
    case edit = "edit"
    case email = "email"
    case generic_error = "generic_error"
    case search = "search"
    case stripe_logo = "stripe_logo"
    case spinner = "spinner"
    case warning_circle = "warning_circle"
    case warning_triangle = "warning_triangle"
    case mx = "mx"
    case finicity = "finicity"
    case bullet = "bullet"
}

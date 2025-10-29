//
//  Image.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 11/22/21.
//

@_spi(STP) import StripeUICore
import UIKit

/// The canonical set of all image files in the `StripeFinancialConnections` module.
/// This helps us avoid duplicates and automatically test that all images load properly
enum Image: String, ImageMaker {
    typealias BundleLocator = StripeFinancialConnectionsBundleLocator

    case add
    case back_arrow
    case bank
    case cancel_circle
    case check
    case chevron_down
    case close
    case generic_error
    case info
    case link_logo
    case panel_arrow_right
    case person
    case search
    case stripe_logo
    case spinner
    case testmode
    case warning_triangle
    case bullet
}

extension UIImage {
    func applyFinancialConnectionsBackButtonEdgeInsets() -> UIImage {
        if LiquidGlassDetector.isEnabledInMerchantApp {
            return self
        } else {
            return withAlignmentRectInsets(UIEdgeInsets(top: 0, left: -13, bottom: -2, right: 0))
        }
    }
}

extension UIBarButtonItem {
    func applyFinancialConnectionsCloseButtonEdgeInsets() {
        if !LiquidGlassDetector.isEnabledInMerchantApp {
            imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 5)
        }
    }
}

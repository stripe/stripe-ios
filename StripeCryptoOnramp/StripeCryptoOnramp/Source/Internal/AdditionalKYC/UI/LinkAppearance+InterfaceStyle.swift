//
//  LinkAppearance+InterfaceStyle.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/29/26.
//

@_spi(CryptoOnrampAlpha) import StripePaymentSheet
import UIKit

extension LinkAppearance {

    /// Applies the configured light, dark, or automatic interface style to a view controller.
    /// - Parameter viewController: The view controller whose interface style is configured.
    func applyInterfaceStyle(to viewController: UIViewController) {
        switch style {
        case .automatic:
            break
        case .alwaysLight:
            viewController.overrideUserInterfaceStyle = .light
        case .alwaysDark:
            viewController.overrideUserInterfaceStyle = .dark
        @unknown default:
            break
        }
    }
}

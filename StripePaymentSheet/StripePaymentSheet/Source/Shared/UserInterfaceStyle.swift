//
//  UserInterfaceStyle.swift
//  StripePaymentSheet
//

import UIKit

/// Style options for colors in PaymentSheet
public enum UserInterfaceStyle: Int {

    /// (default) PaymentSheet will automatically switch between standard and dark mode compatible colors based on device settings
    case automatic = 0

    /// PaymentSheet will always use colors appropriate for standard, i.e. non-dark mode UI
    case alwaysLight

    /// PaymentSheet will always use colors appropriate for dark mode UI
    case alwaysDark

    func configure(_ viewController: UIViewController) {
        switch self {
        case .automatic:
            break  // no-op

        case .alwaysLight:
            viewController.overrideUserInterfaceStyle = .light

        case .alwaysDark:
            viewController.overrideUserInterfaceStyle = .dark
        }
    }
}

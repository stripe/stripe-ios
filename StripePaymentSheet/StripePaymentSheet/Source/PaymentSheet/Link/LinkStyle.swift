//
//  LinkStyle.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 7/10/25.
//

import Foundation

enum LinkStyle {
    /// (default)  Link will automatically switch between light and dark mode compatible colors based on device settings.
    case automatic
    /// Link will always use colors appropriate for light mode UI.
    case alwaysLight
    /// Link will always use colors appropriate for dark mode UI.
    case alwaysDark

    var asPaymentSheetStyle: PaymentSheet.UserInterfaceStyle {
        switch self {
        case .automatic: return .automatic
        case .alwaysLight: return .alwaysLight
        case .alwaysDark: return .alwaysDark
        }
    }
}

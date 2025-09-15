//
//  PaymentSheetAppearance+Helpers.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 9/15/25.
//

@_spi(STP) import StripeUICore
import UIKit

internal extension PaymentSheet.Appearance {
    var topFormInsets: NSDirectionalEdgeInsets {
        return .insets(top: formInsets.top, leading: formInsets.leading, trailing: formInsets.trailing)
    }
    static let defaultPreIOS26CornerRadius: CGFloat = 6.0
}

extension PaymentSheet.Appearance.NavigationBarStyle {
    var isGlass: Bool {
        #if !os(visionOS)
        guard #available(iOS 26.0, *) else {
            return false
        }
        return self == .glass
        #else
        return false
        #endif
    }
    var isPlain: Bool {
        return self == .plain
    }
}

extension UIView {
    /// A convenience method that looks at `appearance.cornerRadius` and applies it or, if `nil`, handles what the default value should be.
    func applyCornerRadius(appearance: PaymentSheet.Appearance, ios26DefaultCornerStyle: CornerStyle = .uniform) {
        applyCornerRadius(appearance: appearance.asElementsTheme, ios26DefaultCornerStyle: ios26DefaultCornerStyle)
    }
}
